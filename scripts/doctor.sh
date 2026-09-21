#!/usr/bin/env bash
# 읽기 전용 진단. BIOS 내용이나 개인 설정을 업로드하지 않는다.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
errors=0
printf 'IQ-2000 환경 진단\nOS: '
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  ( . /etc/os-release; printf '%s\n' "$PRETTY_NAME" )
else uname -s; fi
printf '아키텍처: '; uname -m
for tool in openmsx findmnt lsblk flock; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '[확인] %s\n' "$tool"
  else printf '[오류] %s 없음 — scripts/install.sh 실행\n' "$tool"; errors=$((errors + 1)); fi
done
if command -v openmsx >/dev/null 2>&1; then openmsx -v; fi
printf '머신: %s / 비디오: %s\n' "${MSX_MACHINE:-Daewoo_CPC-300}" "${SDL_VIDEODRIVER:-자동 선택}"
for name in MSX_POLL MSX_RESTART_DELAY; do
  value="${!name:-}"
  if [[ -n "$value" ]] && { [[ ! "$value" =~ ^[1-9][0-9]{0,2}$ ]] || (( value > 300 )); }; then
    printf '[오류] %s는 1~300의 정수여야 합니다.\n' "$name"
    errors=$((errors + 1))
  fi
done
for file in msx-keys.tcl cheat-knightmare.tcl; do
  if [[ -r "$HOME/.openMSX/share/scripts/$file" ]]; then echo "[확인] $file";
  else echo "[안내] $file 없음 — scripts/install.sh --keys"; fi
done
echo 'ROM 검색 경로: ~/.openMSX/share/systemroms/ 및 openMSX의 시스템 공유 경로'
echo 'BIOS 완전성은 openMSX 실행으로 확인하세요. 파일 개수만으로 판정하지 않습니다.'
cart="$("$HERE/cart-find.sh" 2>&1)"; status=$?
case "$status" in
  0) printf '[확인] 팩: %s\n' "$cart"; findmnt --target "$cart" --output TARGET,SOURCE,FSTYPE,OPTIONS ;;
  1) echo '[안내] 팩 없음 (아이큐 교실로 부팅)' ;;
  *) printf '%s\n' "$cart"; errors=$((errors + 1)) ;;
esac
if command -v systemctl >/dev/null 2>&1; then
  printf '서비스 상태: '; systemctl is-active openmsx-cart 2>/dev/null || true
fi
if command -v vcgencmd >/dev/null 2>&1; then vcgencmd get_throttled; fi
printf '\n오류 %s개. 로그: journalctl -u openmsx-cart -n 50 --no-pager\n' "$errors"
(( errors == 0 ))
