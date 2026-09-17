#!/usr/bin/env bash
# openMSX 설치 + systemroms 디렉터리 준비
set -euo pipefail

echo "▶ openMSX 설치"
sudo apt update
sudo apt install -y openmsx

ROMDIR="$HOME/.openMSX/share/systemroms"
mkdir -p "$ROMDIR"

cat <<MSG

✅ 준비 완료

ROM 배치 경로: $ROMDIR

아래 3개 파일을 여기에 넣으세요 (Daewoo CPC-300 = IQ-2000):
  cpc-300_basic-bios2.rom   메인 ROM — BIOS + MSX-BASIC
  cpc-300_msx2sub.rom       MSX2 SUB-ROM
  cpc-300_hangul.rom        한글 ROM  ← SCREEN 9 / 「아이큐 교실」의 실체

※ 파일명은 무관하다. openMSX는 SHA1 해시로 판별한다.
※ cpc-300e_* 는 교육용 CPC-300E 전용이므로 필요 없다.

확인:  openmsx -machine Daewoo_CPC-300
MSG
