#!/usr/bin/env bash
# openMSX 실행. 인자로 롬 경로를 주면 카트리지로 꽂아 띄운다.
#   MSX_MACHINE 환경변수로 머신 변경 가능 (기본 Daewoo_CPC-300)
set -uo pipefail

MACHINE="${MSX_MACHINE:-Daewoo_CPC-300}"
CART="${1:-}"

if [[ -n "$CART" && -f "$CART" ]]; then
  echo "[msx] $MACHINE + cart: $CART"
  exec openmsx -machine "$MACHINE" -cart "$CART"
else
  echo "[msx] $MACHINE (카트리지 없음 → 아이큐 교실)"
  exec openmsx -machine "$MACHINE"
fi
