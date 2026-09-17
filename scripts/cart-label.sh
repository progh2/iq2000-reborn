#!/usr/bin/env bash
# 롬 파일이 놓인 USB의 볼륨 레이블을 출력한다 (팩 이름 표시용).
# 레이블이 없으면 파일명(확장자 제외)을 대신 출력.
set -uo pipefail
ROM="${1:-}"
[[ -n "$ROM" ]] || exit 1

mp="$(df --output=target "$ROM" 2>/dev/null | tail -n1 | xargs)"
label="$(lsblk -no LABEL "$(findmnt -no SOURCE --target "$mp" 2>/dev/null)" 2>/dev/null | xargs || true)"

if [[ -n "$label" ]]; then
  echo "$label"
else
  b="$(basename "$ROM")"
  echo "${b%.*}"
fi
