#!/usr/bin/env bash
# 기본: 패키지 설치. --keys: 사용자 키 설정. --system: 서비스/udev 설치 (활성화는 별도).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"
case "${1:-}" in
  '')
    sudo apt update
    sudo apt install -y openmsx util-linux python3
    mkdir -p "$HOME/.openMSX/share/systemroms"
    printf '\nROM 배치: %s/.openMSX/share/systemroms/\n' "$HOME"
    echo '필수: cpc-300_basic-bios2.rom / cpc-300_msx2sub.rom / cpc-300_hangul.rom'
    echo '파일명은 무관하며 openMSX가 해시로 판별합니다. ROM은 포함되지 않습니다.'
    echo '다음: ./scripts/msx-run.sh → 전체화면 설정 → ./scripts/install.sh --keys'
    ;;
  --keys)
    if (( EUID == 0 )); then echo '일반 사용자로 실행하세요 (sudo 불필요).' >&2; exit 2; fi
    target="$HOME/.openMSX/share/scripts"
    mkdir -p "$target"
    cp --backup=numbered "$HERE/msx-keys.tcl" "$HERE/cheat-knightmare.tcl" "$target/"
    echo '키 설정 설치 완료. 기존 파일은 번호가 붙은 백업으로 보관합니다.'
    echo 'openMSX를 재시작하세요. 전체화면 변경: F10 → set fullscreen on 또는 off'
    ;;
  --system)
    if (( EUID == 0 )); then echo '일반 사용자로 실행하세요. 필요한 단계에서 sudo를 사용합니다.' >&2; exit 2; fi
    command -v python3 >/dev/null || { echo 'python3를 먼저 설치하세요.' >&2; exit 1; }
    staged="$(mktemp -d)"
    trap 'rm -rf "$staged"' EXIT
    python3 - "$REPO" "$(id -un)" "$staged/openmsx-cart.service" <<'PY'
import pathlib, sys
repo, user, output = sys.argv[1:]
if any(c in repo for c in '\n\r'):
    raise SystemExit('저장소 경로에 줄바꿈을 사용할 수 없습니다.')
def escape(value):
    return value.replace('\\', '\\\\').replace('"', '\\"').replace('%', '%%').replace('$', '$$')
text = (pathlib.Path(repo) / 'systemd/openmsx-cart.service').read_text()
text = text.replace('User=pi', 'User=' + user)
text = text.replace('ExecStart=/home/pi/iq2000-reborn/scripts/cart-watch.sh',
                    'ExecStart="' + escape(repo + '/scripts/cart-watch.sh') + '"')
pathlib.Path(output).write_text(text)
PY
    sudo install -b -S .previous -m 644 "$staged/openmsx-cart.service" /etc/systemd/system/openmsx-cart.service
    sudo install -b -S .previous -m 644 "$REPO/systemd/99-msx-cart.rules" /etc/udev/rules.d/99-msx-cart.rules
    sudo systemctl daemon-reload
    sudo udevadm control --reload
    echo '서비스와 USB 규칙 설치 완료. 기존 파일은 .previous로 백업했습니다.'
    echo '기존 AUDIODEV 등 사용자 설정이 있다면 백업에서 옮겨 주세요.'
    echo 'USB를 다시 연결하고 콘솔 화면을 검증한 뒤: sudo systemctl enable --now openmsx-cart'
    ;;
  *) echo '사용법: scripts/install.sh [--keys|--system]' >&2; exit 2 ;;
esac
