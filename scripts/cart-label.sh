#!/usr/bin/env bash
# 롬 파일이 놓인 USB의 볼륨 레이블을 출력한다 (팩 이름 표시용).
# 레이블이 없으면 파일명(확장자 제외)을 대신 출력.
set -uo pipefail
ROM="${1:-}"
[[ -n "$ROM" ]] || exit 1

label="$(findmnt --noheadings --raw --output LABEL --target "$ROM" 2>/dev/null || true)"
printf -v label '%b' "$label"

if [[ -n "$label" ]]; then
  printf '%s\n' "$label"
else
  b="$(basename "$ROM")"
  echo "${b%.*}"
fi
