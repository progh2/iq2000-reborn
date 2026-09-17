#!/usr/bin/env bash
# 마운트된 USB에서 롬 파일을 하나 찾아 경로를 출력한다.
# 못 찾으면 아무것도 출력하지 않고 종료코드 1.
set -uo pipefail

for base in /media /run/media /mnt; do
  [[ -d "$base" ]] || continue
  found="$(find "$base" -maxdepth 3 -type f \
      \( -iname '*.rom' -o -iname '*.mx1' -o -iname '*.mx2' \) \
      2>/dev/null | sort | head -n 1)"
  if [[ -n "$found" ]]; then
    echo "$found"
    exit 0
  fi
done
exit 1
