#!/usr/bin/env bash
# ── USB 롬팩 감시기 ──
# USB가 꽂히거나 빠지면 openMSX를 다시 띄운다.
#
# 📌 실기 MSX도 카트리지는 전원을 끄고 갈아야 했다.
#    "꽂으면 재시작"은 편법이 아니라 원래 동작에 충실한 방식이다.
#
# 환경변수
#   MSX_POLL     감시 주기(초). 기본 2
#   MSX_MACHINE  머신 이름. 기본 Daewoo_CPC-300
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERVAL="${MSX_POLL:-2}"
last="__init__"
pid=""

cleanup() { [[ -n "$pid" ]] && kill "$pid" 2>/dev/null; exit 0; }
trap cleanup INT TERM

launch() {
  local cart="$1"
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  if [[ -n "$cart" ]]; then
    echo "[cart] 꽂힘: $("$HERE/cart-label.sh" "$cart")  ($cart)"
    "$HERE/msx-run.sh" "$cart" &
  else
    echo "[cart] 비어 있음 → 아이큐 교실"
    "$HERE/msx-run.sh" &
  fi
  pid=$!
}

echo "[watch] 시작 (주기 ${INTERVAL}s)"
while true; do
  cur="$("$HERE/cart-find.sh" 2>/dev/null || true)"
  if [[ "$cur" != "$last" ]]; then
    launch "$cur"
    last="$cur"
  fi
  sleep "$INTERVAL"
done
