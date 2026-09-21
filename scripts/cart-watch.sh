#!/usr/bin/env bash
# USB 변화 및 openMSX 종료를 감시한다. 설정은 docs/maintenance.md 참고.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERVAL="${MSX_POLL:-2}"
RETRY="${MSX_RESTART_DELAY:-3}"
for value in "$INTERVAL" "$RETRY"; do
  if [[ ! "$value" =~ ^[1-9][0-9]{0,2}$ ]] || (( value > 300 )); then
    echo "[watch] MSX_POLL과 MSX_RESTART_DELAY는 1~300의 정수(초)여야 합니다." >&2
    exit 2
  fi
done
command -v openmsx >/dev/null 2>&1 || { echo "[watch] openmsx를 먼저 설치하세요." >&2; exit 127; }
command -v flock >/dev/null 2>&1 || { echo "[watch] flock(util-linux)이 필요합니다." >&2; exit 127; }
# systemd와 Desktop에서 XDG_RUNTIME_DIR 유무가 달라도 같은 잠금을 쓴다.
lockdir="${XDG_CACHE_HOME:-$HOME/.cache}/iq2000-reborn"
mkdir -p "$lockdir" || exit 1
exec 9>"$lockdir/watch.lock"
flock -n 9 || { echo "[watch] 이미 실행 중입니다." >&2; exit 1; }
pid=""
sleeper=""
stop() {
  [[ -n "$pid" ]] || return 0
  kill "$pid" 2>/dev/null || true
  local deadline=$((SECONDS + 3))
  while kill -0 "$pid" 2>/dev/null && (( SECONDS < deadline )); do sleep 0.1; done
  kill -KILL "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  pid=""
}
cleanup() {
  if [[ -n "$sleeper" ]]; then
    kill "$sleeper" 2>/dev/null || true
    wait "$sleeper" 2>/dev/null || true
  fi
  stop
}
trap 'exit 0' INT TERM
trap cleanup EXIT
last="__init__"
last_error=""
retry_at=0
echo "[watch] 시작 (주기 ${INTERVAL}s, 재실행 대기 ${RETRY}s)"
while true; do
  result="$("$HERE/cart-find.sh" 2>&1)"
  status=$?
  cur=""; error=""
  if (( status == 0 )); then cur="$result"; elif (( status != 1 )); then error="$result"; fi
  if [[ "$error" != "$last_error" ]]; then
    [[ -z "$error" ]] || printf '%s\n' "$error" >&2
    last_error="$error"
  fi
  identity="$cur"
  [[ -z "$cur" ]] || identity+="$(stat -Lc '%d:%i:%s:%Y:%Z' -- "$cur" 2>/dev/null)"
  if [[ "$identity" != "$last" ]]; then
    stop
    last="$identity"
    retry_at=0
  fi
  if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
    wait "$pid"; status=$?
    echo "[watch] openMSX 종료 (코드 $status). ${RETRY}초 후 재실행합니다." >&2
    pid=""
    retry_at=$((SECONDS + RETRY))
  fi
  if [[ -z "$pid" ]] && (( SECONDS >= retry_at )); then
    if [[ -n "$cur" ]]; then
      echo "[cart] 꽂힘: $("$HERE/cart-label.sh" "$cur") ($cur)"
      "$HERE/msx-run.sh" "$cur" 9>&- &
    else
      echo "[cart] 비어 있음 → 아이큐 교실"
      "$HERE/msx-run.sh" 9>&- &
    fi
    pid=$!
  fi
  sleep "$INTERVAL" 9>&- &
  sleeper=$!
  wait "$sleeper" || true
  sleeper=""
done
