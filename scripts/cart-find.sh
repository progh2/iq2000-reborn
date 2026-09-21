#!/usr/bin/env bash
# FAT USB 루트에서 ROM 하나를 찾는다. 0=발견, 1=없음, 2=설정/선택 오류.
# MSX_CART_ROOT: 지정한 디렉터리만 검색 (수동 마운트/개발용).
set -uo pipefail
roots=()
if [[ -n "${MSX_CART_ROOT:-}" ]]; then
  if [[ ! -d "$MSX_CART_ROOT" || ! -r "$MSX_CART_ROOT" || ! -x "$MSX_CART_ROOT" ]]; then
    echo "[cart] 검색 디렉터리를 읽을 수 없습니다: $MSX_CART_ROOT" >&2
    exit 2
  fi
  roots+=("$MSX_CART_ROOT")
else
  for tool in findmnt lsblk; do
    command -v "$tool" >/dev/null 2>&1 || { echo "[cart] 필요한 명령: $tool" >&2; exit 2; }
  done
  while read -r target source; do
    # findmnt --raw의 공백 이스케이프(\x20 등)를 복원한다.
    printf -v target '%b' "$target"
    printf -v source '%b' "$source"
    case "$target" in /media/*|/run/media/*|/mnt/*) ;; *) continue ;; esac
    if lsblk --inverse --noheadings --output TRAN "$source" 2>/dev/null | grep -qw usb; then
      roots+=("$target")
    fi
  done < <(findmnt --list --raw --noheadings --types vfat --output TARGET,SOURCE)
fi
files=()
for root in "${roots[@]}"; do
  while IFS= read -r -d '' file; do
    if [[ "$file" == *$'\n'* ]]; then
      echo "[cart] ROM 경로에서 줄바꿈 문자를 제거하세요." >&2
      exit 2
    fi
    duplicate=false
    for existing in "${files[@]}"; do
      [[ "$file" -ef "$existing" ]] && duplicate=true
    done
    $duplicate || files+=("$file")
  done < <(find "$root" -maxdepth 1 -type f -readable \
    \( -iname '*.rom' -o -iname '*.mx1' -o -iname '*.mx2' \) -print0 2>/dev/null)
done
case ${#files[@]} in
  0) exit 1 ;;
  1) printf '%s\n' "${files[0]}" ;;
  *) echo "[cart] ROM이 여러 개입니다. 사용할 팩 하나에 ROM 하나만 남기세요." >&2; exit 2 ;;
esac
