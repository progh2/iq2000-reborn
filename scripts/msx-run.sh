#!/usr/bin/env bash
# openMSX 실행. 인자로 롬 경로를 주면 카트리지로 꽂아 띄운다.
#   MSX_MACHINE 환경변수로 머신 변경 가능 (기본 Daewoo_CPC-300)
set -uo pipefail

MACHINE="${MSX_MACHINE:-Daewoo_CPC-300}"
CART="${1:-}"

if (( $# > 1 )) || { (( $# == 1 )) && [[ ! -f "$CART" || ! -r "$CART" ]]; }; then
  echo "[msx] 읽을 수 있는 ROM 파일 하나를 지정하세요: $CART" >&2
  exit 2
fi
if ! command -v openmsx >/dev/null 2>&1; then
  echo "[msx] openmsx가 없습니다. scripts/install.sh를 먼저 실행하세요." >&2
  exit 127
fi

if [[ -n "$CART" ]]; then
  echo "[msx] $MACHINE + cart: $CART"
  exec openmsx -machine "$MACHINE" -cart "$CART"
else
  echo "[msx] $MACHINE (카트리지 없음 → 아이큐 교실)"
  exec openmsx -machine "$MACHINE"
fi
