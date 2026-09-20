# 라즈베리파이 — OS 설치와 설정

## 1. 어떤 OS를 쓸까

**Raspberry Pi OS / Bookworm** 를 쓴다. Debian 기반이라 **openMSX가 apt 저장소에 있다**.

- **Pi 4 이상** → 64-bit / **Pi 3 (RAM 1GB)** → **32-bit** (64-bit는 메모리만 더 먹는다)
- 이 문서는 Bookworm(Debian 12) 기준이지만 **Trixie(Debian 13)도 무방하다** — 경로·절차가 같고 apt의 openMSX가 더 최신이다

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

💡 **Desktop을 깔았어도 다시 굽을 필요 없다.** Desktop 이미지 = Lite + 데스크톱 패키지라서,
`sudo raspi-config` → System Options → Boot / Auto Login → **Console Autologin** 으로 바꾸면
데스크톱이 안 떠서 사실상 Lite처럼 동작한다 (`kmsdrm` 그대로 사용 가능). 차이는 SD 용량뿐.

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

### ⚡ low voltage warning이 뜨면

경고 기준은 4.63V. 저전압이면 **CPU가 600MHz로 스로틀링**돼 openMSX 성능이 깎이고, 심하면 SD가 상한다.

1. **microUSB 케이블 교체가 먼저다** — 짧고(≤1m) 굵은 충전 전용급으로. 얇은 데이터 케이블이 제일 흔한 원인
2. 어댑터는 5V 2.5A 이상. QC(고속충전) 어댑터·모니터 USB 포트·PC USB는 부적합
3. 확인: `vcgencmd get_throttled` → `0x0` 정상 / `0x50000` 과거에 있었음 / `0x50005` 지금도 저전압

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
- Pi 3 — 돌지만 여유가 적다 → 아래 튜닝 절 참조
- Pi 5 — 과분하다

### Pi 3 튜닝

Pi 3(Cortex-A53 4코어 1.2GHz, RAM 1GB)에서 병목은 Z80 에뮬레이션이 아니라 **렌더링과 리샘플러**다. CPC-300은 SCC·MSX-MUSIC 같은 무거운 확장이 없는 표준 MSX2 구성이라, 아래만 깎으면 100% 속도가 나온다.

| 항목 | 설정 | 이유 |
|---|---|---|
| OS | **32-bit Lite** 권장 | RAM 1GB에서 64-bit는 메모리를 더 먹는다. openMSX는 armhf apt 패키지가 있다 |
| 화면 | `set scale_factor 1` (부족하면 2) | 스케일링이 제일 비싸다 |
| 셰이더 | `set scale_algorithm simple` | scanline·hq 계열 효과를 끈다 |
| 소리 | `set resampler fast` | 기본 리샘플러가 의외로 CPU를 먹는다 |
| 되감기 | `set auto_enable_reverse off` | reverse 버퍼가 1GB RAM에서 부담이다 |

설정은 openMSX 콘솔(`F10`)에서 치면 `settings.xml` 에 저장돼 다음부터 유지된다.
Desktop 환경 자체가 Pi 3에는 무거우므로, 검증만 Desktop에서 하고 **전용기는 Lite + `kmsdrm`** 로 가는 편이 좋다.

## 7. 왜 레트로 배포판(RetroPie·Batocera)을 안 쓰는가

이들에도 MSX 코어가 있지만 대부분 **blueMSX·fMSX 기반**이다.
**`Daewoo CPC-300` 머신 정의 + 한글 ROM 조합이 확실히 검증된 것은 openMSX** 다 — Windows에서 「아이큐 교실」이 뜬 그 조합이 openMSX였다.
애써 맞춘 환경을 그대로 옮기는 것이 안전하다.

## 8. 콘솔 전용기 전환 체크리스트

Desktop에서 검증이 끝났으면 아래 순서로 전용기가 된다. **각 단계를 검증하고 다음으로 넘어갈 것.**

### ① USB 자동 마운트를 데스크톱 독립으로

데스크톱의 자동 마운트는 파일 관리자가 해주는 것이라 콘솔 모드에선 사라진다. udev 규칙으로 대체한다:

```bash
sudo cp systemd/99-msx-cart.rules /etc/udev/rules.d/
sudo udevadm control --reload
# 검증: USB를 뺐다 꽂고
ls /media/cart          # 롬 파일이 보여야 한다
```

- `/media/cart` 에 **읽기전용**으로 마운트된다 — 아무 때나 확 뽑아도 안전
- 파일 관리자의 자동 마운트 옵션은 이제 꺼도 된다 (이중 마운트 방지)

### ② systemd 유닛 설치

```bash
sudo cp systemd/openmsx-cart.service /etc/systemd/system/
sudo sed -i "s/User=pi/User=$USER/; s|/home/pi|$HOME|g" /etc/systemd/system/openmsx-cart.service
sudo systemctl daemon-reload
```

아직 `enable` 하지 말 것 — ③에서 콘솔 부팅을 먼저 확인한다.

### ③ 콘솔 부팅 전환 + kmsdrm 검증

```bash
sudo raspi-config    # System Options → Boot / Auto Login → Console Autologin
sudo reboot
```

재부팅 후 콘솔(또는 SSH)에서 **수동으로 한 번** 띄워본다:

```bash
SDL_VIDEODRIVER=kmsdrm ~/iq2000-reborn/scripts/cart-watch.sh
```

화면에 openMSX가 뜨면 성공. `Ctrl+C` 로 끄고 ④로.
(안 뜨면 이 단계에서 잡는다 — 유닛까지 켜놓고 헤매지 말 것)

### ④ 자동 실행 활성화

```bash
sudo systemctl enable --now openmsx-cart
journalctl -u openmsx-cart -f    # 로그 확인
```

이제 **전원만 꽂으면 아이큐 교실, 팩 꽂으면 게임**이다.

### 되돌리기

- 데스크톱으로: `raspi-config` → Desktop Autologin
- 자동 실행 끄기: `sudo systemctl disable --now openmsx-cart`

## 9. 소리 — 디스플레이에 스피커가 없을 때

MSX의 PSG 사운드는 **모노**이고, 실기도 TV 스피커 하나로 소리를 냈다. 작은 모노 스피커 하나면 오히려 그 시절에 충실하다.

| 방법 | 비용·난이도 | 비고 |
|---|---|---|
| **3.5mm 잭 + 앰프 내장 스피커** | ⭐ 제일 쉽다 | Pi 3의 AV 잭에 꽂는다. PWM 방식이라 음질은 평범하지만 PSG에는 충분 |
| USB 스피커 / USB 오디오 동글 | ⭐ | 잭 음질이 거슬리면 |
| HDMI 디스플레이의 내장 스피커 | — | 키트에 스피커가 있으면 그걸로 끝. DSI 디스플레이는 소리가 안 나온다 |
| **I2S 앰프 보드(MAX98357A 등) + 스피커** | ⭐⭐ 납땜 | GPIO에 물리고 케이스에 스피커를 내장 — **전용기답다.** 모노라 한 채널이면 된다 |

출력 경로가 HDMI로 잡혀 있으면 잭에서 소리가 안 난다. `sudo raspi-config` → System Options → Audio 에서 출력을 고른다.

### 구글 AIY Voice Kit V1 / KT AI 메이커스 키트 재활용

구글 AIY Voice Kit **V1**의 Voice HAT — 그리고 그 설계를 그대로 쓴 **KT 기가지니 AI 메이커스 키트**(아크릴 큐브 케이스) — 에는 I2S 클래스D 앰프(MAX98357A 계열)와 스피커 단자가 있다. **AIY 소프트웨어 없이** 사운드카드로만 쓸 수 있다.

1. HAT를 Pi에 얹고 스피커를 단자에 연결
2. `/boot/firmware/config.txt` 에 추가:
   ```
   dtoverlay=googlevoicehat-soundcard
   ```
   (이 오버레이는 현행 Raspberry Pi OS 커널에 기본 포함돼 있다)
3. 재부팅 후 확인:
   ```bash
   aplay -l                      # snd_rpi_googlevoicehat… 카드가 보여야 한다
   speaker-test -t sine -c 2     # 삑— 소리 확인
   ```
4. 카드가 여럿이면 `raspi-config` 또는 `~/.asoundrc` 로 기본 출력을 지정한다

**HDMI 오디오와 공존한다.** 오버레이를 넣어도 HDMI 사운드카드(`vc4hdmi`)는 그대로 살아 있어, 스피커 달린 모니터로 옮길 때 **배선 변경 없이 출력만 바꾸면 된다.**

- 기본 출력 전환: `sudo raspi-config` → System Options → Audio
- openMSX만 지정하려면 systemd 유닛에 환경변수로: `Environment=AUDIODEV=sysdefault:CARD=vc4hdmi` (HAT로 되돌릴 땐 해당 카드명으로 — 카드명은 `aplay -l` 로 확인)

- 7인치 공식 터치스크린(DSI)은 GPIO를 쓰지 않으므로 HAT와 **같이 쓸 수 있다.** 단, HAT가 GPIO 핀을 덮으므로 디스플레이 전원을 점퍼선으로 못 준다 → **Pi의 USB-A → 디스플레이 microUSB** 케이블로 주거나(어댑터는 5V 3A급), 디스플레이에 전원을 따로 꽂는다. 소리 날 때 화면이 깜빡이면 저전압이니 후자로 전환
- 키트의 **아케이드 버튼**은 `SELECT` 물리 버튼으로 재활용할 수 있다 → [`keyboard.md`](keyboard.md)의 GPIO 버튼 절
- 마이크 보드는 이 프로젝트에서 쓸 일이 없다
- ⚠️ **V2(작은 Bonnet + Pi Zero 동봉)는 해당 없음** — 전용 드라이버가 방치돼 최신 커널에서 빌드가 어렵다. 스피커만 떼서 다른 앰프에 물릴 것

**HAT가 케이스와 간섭돼 못 쓸 때** (뒷면 관통 핀이 튀어나와 걸리는 경우):

- 관통 핀은 미사용 브레이크아웃이라 **니퍼로 바짝 잘라도 된다** — HAT를 살리고 싶으면 이 방법
- **HAT 없이 가도 기능 손실이 거의 없다**:
  - 소리 → **HDMI(모니터/TV 스피커)**. 실기가 TV로 소리를 내던 방식 그대로다. 또는 Pi의 3.5mm 잭
  - 아케이드 버튼 → HAT 불필요. 버튼에서 점퍼선 2가닥을 **GPIO23(물리핀 16)과 GND(물리핀 14)** 에 직접 꽂으면 `gpio-key` 오버레이가 그대로 동작한다
  - 키트 스피커 → 보류. 나중에 원하면 PAM8403(천 원)이나 트랜지스터 앰프로 3.5mm 잭에 물린다
