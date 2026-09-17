# 라즈베리파이 4 — OS 설치와 설정

## 1. 어떤 OS를 쓸까

**Raspberry Pi OS (64-bit) / Bookworm** 를 쓴다. Debian 기반이라 **openMSX가 apt 저장소에 있다**.

변종이 둘인데 목적에 따라 갈린다.

| | **Desktop 버전** | **Lite 버전** |
|---|---|---|
| 데스크톱 | 있음 (Bookworm은 **Wayland/wayfire 기본**) | 없음 (콘솔만) |
| 난이도 | ⭐ **쉽다 — 여기서 시작할 것** | ⭐⭐⭐ |
| 자동 실행 | `~/.config/autostart/` 에 `.desktop` 넣기 | systemd 서비스 |
| `SDL_VIDEODRIVER` | `wayland` 또는 `x11` | **`kmsdrm`** |
| 부팅 속도·군더더기 | 느리고 많다 | 빠르고 깔끔 — **전용기답다** |

👉 **권장 순서: Desktop 버전으로 먼저 동작을 검증하고, 그다음 Lite로 옮긴다.**
처음부터 Lite로 가면 «화면이 안 뜨는데 원인이 openMSX인지 비디오 드라이버인지» 구분이 안 돼 시간을 버린다.

> ⚠️ **Bookworm은 Wayland가 기본이다.** 이 저장소의 `systemd/openmsx-cart.service` 는 `SDL_VIDEODRIVER=kmsdrm` 으로 되어 있어 **Lite 기준**이다. Desktop 버전에서 systemd로 띄우려면 이 값을 `wayland` 로 바꾸거나, 아예 데스크톱 autostart(`A` 방법)를 쓴다.

## 2. 설치

1. **Raspberry Pi Imager** 로 microSD에 굽는다 — https://www.raspberrypi.com/software/
2. Imager의 **⚙️ 고급 설정**에서 미리 해두면 편하다
   - 호스트명 (예: `iq2000`)
   - **SSH 활성화** ← 헤드리스로 작업하려면 필수
   - Wi-Fi, 사용자명·비밀번호, 로케일/키보드
3. 부팅 후

```bash
sudo apt update && sudo apt full-upgrade -y
sudo reboot
```

## 3. openMSX 설치

```bash
./scripts/install.sh          # 이 저장소의 스크립트
# 또는 직접:  sudo apt install openmsx
```

⚠️ **apt 버전은 최신이 아닐 수 있다.** Debian 저장소 버전이 한두 해 뒤처지는 경우가 있다.
`Daewoo_CPC-300` 머신 정의는 오래전부터 포함돼 있어 구버전으로도 동작하지만, 최신 기능이 필요하면 소스 빌드를 한다.

```bash
openmsx -v                    # 설치된 버전 확인
openmsx -machine Daewoo_CPC-300   # 부팅 시험
```

**소스 빌드가 필요할 때** (최신판을 쓰고 싶거나 apt에 없을 때)

```bash
sudo apt install -y build-essential pkg-config libsdl2-dev libsdl2-ttf-dev \
                    libpng-dev libogg-dev libvorbis-dev libtheora-dev \
                    tcl-dev zlib1g-dev
git clone https://github.com/openMSX/openMSX.git
cd openMSX && ./configure && make -j"$(nproc)" && sudo make install
```
※ 의존 패키지 목록은 버전에 따라 달라질 수 있다. `./configure` 가 알려주는 대로 채운다.

## 4. ROM 배치

```bash
mkdir -p ~/.openMSX/share/systemroms
# cpc-300_basic-bios2.rom / cpc-300_msx2sub.rom / cpc-300_hangul.rom 복사
```

플랫폼별 경로가 다르다.

| OS | 경로 |
|---|---|
| **라즈베리파이 / Linux** | `~/.openMSX/share/systemroms/` |
| macOS | `~/.openMSX/share/systemroms/` |
| **Windows** | `%USERPROFILE%\Documents\openMSX\share\systemroms\` |

## 5. 전체화면

한 번 띄운 뒤 OSD 메뉴에서 전체화면을 켜면 `~/.openMSX/share/settings.xml` 에 저장돼 다음부터 유지된다.

## 6. 성능

**Pi 4면 MSX2 에뮬레이션에 충분하다.** openMSX는 정확도를 우선하는 에뮬레이터라 fMSX·blueMSX보다 무겁지만, MSX2는 1986년 기계다.

- Pi 4 (2GB 이상) — 여유롭다
- Pi 3 — 돌지만 여유가 적다. 전체화면 스케일링·셰이더를 끄는 편이 낫다
- Pi 5 — 과분하다

## 7. 왜 레트로 배포판(RetroPie·Batocera)을 안 쓰는가

이들에도 MSX 코어가 있지만 대부분 **blueMSX·fMSX 기반**이다.
**`Daewoo CPC-300` 머신 정의 + 한글 ROM 조합이 확실히 검증된 것은 openMSX** 다 — Windows에서 「아이큐 교실」이 뜬 그 조합이 openMSX였다.
애써 맞춘 환경을 그대로 옮기는 것이 안전하다.
