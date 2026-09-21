---
layout: default
title: 설치와 사용 안내
description: IQ-2000 전용기의 준비물, OS 설치, 한글 ROM 배치, USB 롬팩과 자동 실행 안내.
permalink: /guide/
---

# IQ-2000 설치와 사용 안내

**대우 IQ-2000 (CPC-300) — 국산 MSX2를 라즈베리파이로 재현한 전용기.**

전원을 꽂으면 「아이큐 교실」이 뜨고, USB 메모리를 롬팩처럼 꽂으면 게임이 뜨고, 뽑으면 아이큐 교실로 돌아온다.
목표였던 **한글이 표시되는 국산 MSX2 환경의 재현** — 일본 MSX2로는 대체되지 않는 그 부분 — 이 완성됐다.

> ✅ **2026-09-20 완성.** Raspberry Pi 3 B+ / 공식 7" 터치스크린 / Raspberry Pi OS(Trixie) 32-bit
> 당시 구성에서 부팅 자동 실행 · USB 롬팩 · 한글(SCREEN 9) · 마성전설 치트를 검증했습니다. 이후 코드 변경의 검증 범위는 [진단·관리](docs/maintenance.md#검증-기록)를 참고하세요.

---

## 차례

1. [이 물건은 무엇인가](#1-이-물건은-무엇인가)
2. [준비물](#2-준비물)
3. [OS 설치](#3-os-설치)
4. [openMSX 설치와 ROM 배치](#4-openmsx-설치와-rom-배치)
5. [화면·키보드·치트 설정](#5-화면키보드치트-설정)
6. [USB 롬팩 만들기와 시험](#6-usb-롬팩-만들기와-시험)
7. [전용기 전환 (부팅 자동 실행)](#7-전용기-전환-부팅-자동-실행)
8. [일상 운용 매뉴얼](#8-일상-운용-매뉴얼)
9. [트러블슈팅](#9-트러블슈팅)
10. [부록 — 선택 확장](#10-부록--선택-확장)
11. [프로젝트 여정 (로드맵의 최후)](#11-프로젝트-여정)

---

## 1. 이 물건은 무엇인가

대우 MSX 계열 중 **한글 지원 + 키보드 일체형 + FDD 없음 + 조이스틱 포트**를 동시에 만족하는 기종이 **IQ-2000(CPC-300)** 이다 (1986~87, MSX2, RAM/VRAM 128KB, 한글 2.0 조합형 고딕체 내장).

| 조건 | 이유 |
|---|---|
| **한글 ROM 내장** | 일본 MSX에는 한글 ROM이 없다 → IQ-1000(CPC-88)은 한글 미지원이라 제외 |
| **키보드 일체형** | 분리형인 X-II(CPC-400)·CPC-400S 제외 |
| **FDD 없음** | 〃 (CPC-400 계열은 FDD 내장) |
| **조이스틱 포트** | 학교 납품용 CPC-300E는 조이스틱 포트가 없다 |

전원을 켜면 BASIC이 아니라 내장 교육 프로그램 **「아이큐 교실」(MSX-TUTOR)** 로 먼저 들어간다.
**카트리지를 꽂고 켜도 마찬가지다** — 아이큐 교실이 먼저 뜨고, `SELECT` 키를 누르면 게임/BASIC으로 넘어간다.
이 재현기는 그 동작까지 그대로다.

기종 판별 근거·대우/재믹스 계열 비교 → [`docs/hardware.md`](docs/hardware.md)

## 2. 준비물

| 품목 | 비고 |
|---|---|
| **Raspberry Pi 3 B+** 이상 | Pi 3는 튜닝하면 충분하다 ([docs/raspberry-pi.md](docs/raspberry-pi.md) 성능 절). Pi 4 이상이면 여유 |
| **화면** | 공식 7" 터치스크린(전용 케이스 포함)이면 본체·화면·케이스가 한 번에 해결된다. HDMI 모니터도 무방 |
| microSD (8GB+) · **5V 2.5A+ 전원** | 전원이 부실하면 저전압 스로틀로 고생한다 (→ 트러블슈팅) |
| USB 키보드 | MSX 키보드 역할 |
| **저용량 USB 메모리 여러 개** | 롬팩용. 128MB~1GB 구형이 물건의 무게감까지 그 시절 같다 |
| 소리 (선택) | 3.5mm 잭에 이어폰이나 앰프 내장 스피커. HDMI 모니터에 스피커가 있으면 그걸로 |
| **ROM 3개** | 아래 참고. **본인 실기에서 직접 덤프하는 것이 정당한 경로이며, 이 저장소는 ROM을 포함하지 않는다** |

### 필요한 ROM 3개

| 파일 | 역할 | 필수 |
|---|---|---|
| `cpc-300_basic-bios2.rom` | 메인 ROM — BIOS + MSX-BASIC | ✅ |
| `cpc-300_msx2sub.rom` | MSX2 SUB-ROM | ✅ |
| `cpc-300_hangul.rom` | 🇰🇷 **한글 ROM** — `SCREEN 9` / 아이큐 교실의 실체 | ✅ **핵심** |

- **파일명은 무관하다.** openMSX는 SHA1 해시로 판별하고, 실행 시 어느 ROM이 없는지 알려준다.
- 🔴 한글 ROM만 빠지면 부팅은 되지만 `SCREEN 9`에서 한글이 안 나온다. 증상으로 바로 구분된다.

## 3. OS 설치

**Raspberry Pi OS 32-bit Desktop** 을 쓴다. (Bookworm/Trixie 어느 쪽이든 된다 — Trixie 쪽이 openMSX가 더 최신이다)

- **32-bit인 이유**: Pi 3는 RAM 1GB라 64-bit는 메모리만 더 먹는다.
- **Desktop으로 시작하는 이유**: 검증이 쉽다. 검증이 끝나면 7절에서 콘솔 전용기로 전환하는데, **재설치가 아니라 부팅 설정만 바꾸는 것**이라 손해가 없다.

절차:

1. [Raspberry Pi Imager](https://www.raspberrypi.com/software/)에서 — Device: 본인 Pi / OS: **Raspberry Pi OS (other) → 32-bit Desktop**
2. **⚙️ 고급 설정(Ctrl+Shift+X)에서 반드시**: 호스트명(예: `iq2000`) · **SSH 활성화** · Wi-Fi · 사용자/비밀번호
3. 부팅 후:

```bash
sudo apt update && sudo apt full-upgrade -y
sudo reboot
```

## 4. openMSX 설치와 ROM 배치

```bash
git clone https://github.com/progh2/iq2000-reborn.git ~/iq2000-reborn
cd ~/iq2000-reborn
./scripts/install.sh          # openMSX 설치 + systemroms 디렉터리 생성
```

ROM 3개를 `~/.openMSX/share/systemroms/` 에 넣는다. Windows에 있다면 **Windows의 cmd 창에서** (Pi에 접속한 SSH 창이 아니다!):

```cmd
scp "C:\경로\systemroms\*.rom" 사용자명@iq2000:.openMSX/share/systemroms/
```

> 💡 Windows에서 openMSX를 쓰고 있었다면 ROM은 `문서\openMSX\share\systemroms\` 에 있다.
> OneDrive를 쓰면 실제 경로가 `C:\Users\이름\OneDrive\문서\...` 일 수 있다. `where /r C:\Users\이름 cpc-300*` 으로 찾자.

부팅 시험:

```bash
./scripts/msx-run.sh
```

**「아이큐 교실」 한글 화면이 뜨면 성공.** F12… 는 아직 안 통한다. 다음 절에서 키를 깐다.

## 5. 화면·키보드·치트 설정

### 전체화면 — 순서가 중요하다

**① 먼저 `F11`로 전체화면을 켠다** (설정이 자동 저장돼 계속 유지된다). **② 그다음** 키 바인딩을 깐다 — 바인딩이 F11을 MSX `STOP`으로 덮어쓰기 때문이다.

키 바인딩 설치 후 전체화면을 바꾸려면 **F10** 콘솔에서 `set fullscreen on` 또는 `set fullscreen off`를 입력한다.

### MSX 전용 키 바인딩

PC 키보드에는 MSX의 `SELECT`·`STOP`·`GRAPH`·`CODE` 키가 없다. 이 키들이 실제로 필요하다:

```bash
./scripts/install.sh --keys   # 기존 설정 파일은 번호를 붙여 백업
```

`~/.openMSX/share/scripts/` 의 `.tcl` 은 openMSX 시작 시 자동 실행된다. **openMSX를 재시작하면 적용:**

| PC 키 | 동작 | 비고 |
|---|---|---|
| **F12** | **SELECT** | 아이큐 교실 → 게임/BASIC 진입, 마성전설 무적 발동 |
| F11 | STOP | BASIC 중단 |
| F9 | GRAPH | 그래픽 문자 |
| F8 | CODE (한/영) | `SCREEN 9`에서 한글 입력 전환 |
| **F7** | **빨리감기 (누르는 동안)** | 아이큐 교실의 한 글자씩 찍는 연출 스킵 |
| F10 | openMSX 콘솔 | 명령 입력용 (openMSX 기본) |
| F1 | 게임 일시정지 | 코나미 게임들의 전통 (게임 자체 기능) |

### 기본 조작 흐름

- 부팅 → 아이큐 교실 → **F12** → 게임 또는 BASIC
- BASIC에서 `SCREEN 9` = 한글 화면 (이 프로젝트의 존재 이유), `SCREEN 0` = 복귀
- 상세와 키 매트릭스 표 → [`docs/keyboard.md`](docs/keyboard.md)

### 마성전설 치트

원래 조작은 타이틀에서 `←+→+Y+SELECT` 4키를 게임 시작까지 누르고 있는 것 — PC 키보드는 고스팅으로 흘리고 SELECT는 없다. 그래서 키 매트릭스를 직접 누르는 스크립트를 쓴다. **타이틀 화면에서 F10 콘솔:**

```tcl
cheat     ;# 투명화 무한 장전 — 콘솔 닫고 4초 안에 SPACE로 게임 시작
lives     ;# 목숨25 + 투명3 버전
sel       ;# 게임 중 SELECT 한 번 (연타 대용)
```

장전된 판에서 **게임 중 F12를 누르면 투명화(무적)가 발동·유지**된다.

조건 없이 쓰는 **openMSX 내장 트레이너**도 있다 (게임 중 아무 때나):

```tcl
trainer "Majyo Densetsu - Knightmare"    ;# 항목 목록 — 등록명이 이것이다
trainer "Majyo Densetsu - Knightmare" "Lives: Lives" "Invulnerable: Invulnerable"
trainer deactivate
```

무적·목숨99 외에 스테이지 점프, 무기 선택, 보스 한 방 등. `all`은 상충 항목까지 켜지므로 골라 켜자.

## 6. USB 롬팩 만들기와 시험

### 팩 만들기

- USB를 **FAT32**로 포맷, 게임 롬(`.rom`/`.mx1`/`.mx2`) 하나를 루트에 넣는다. **압축(.zip)은 풀어서.**
- **볼륨 라벨을 영문 게임명으로** (예: `KNIGHTMARE`) — 감시기 로그에 쓰인다. 한글 라벨은 깨져 보인다.
- USB 하나에 게임 하나. **게임 팩은 한 번에 하나만 연결한다.** 여러 ROM이 발견되면 로그로 알리고 아이큐 교실로 돌아간다.
- 기본 검색 대상은 `/media`, `/run/media`, `/mnt` 아래에 마운트된 **FAT USB의 루트**다. 하위 폴더와 다른 저장장치는 검색하지 않는다.

### Desktop에서 시험

파일 관리자(작업표시줄 폴더 아이콘) → Edit → Preferences → **Volume Management**:
"Mount removable media automatically" **켜고**, "Show available options…" 팝업은 **끈다**.

```bash
cd ~/iq2000-reborn
./scripts/cart-watch.sh
```

- 시작하면 아이큐 교실 → **USB 꽂으면 몇 초 안에 게임으로 재시작 → 뽑으면 아이큐 교실 복귀**
- 실기 MSX도 팩은 전원을 끄고 갈았다. **"꽂으면 재시작"은 편법이 아니라 원래 동작의 재현이다.**
- openMSX 창을 ✕로 닫거나 프로세스가 종료되면 감지 후 기본 3초를 기다려 다시 띄운다. 감시기 종료는 터미널에서 `Ctrl+C`.

## 7. 전용기 전환 (부팅 자동 실행)

Desktop 검증이 끝났으면 콘솔 전용기로 바꾼다. **각 단계를 검증하고 다음으로 넘어갈 것.**

### ① 서비스와 USB 자동 마운트 설치

```bash
cd ~/iq2000-reborn
./scripts/install.sh --system
# 검증: USB를 뺐다 꽂고
findmnt -t vfat -o TARGET,SOURCE,OPTIONS
./scripts/cart-find.sh
```

현재 계정과 저장소 경로로 서비스 파일을 만들고 udev 규칙을 설치한다. **자동 실행 활성화는 ④에서 한다.** 기존 서비스와 규칙은 `.previous`로 백업된다.

USB는 `/media/iq2000/sda1` 같은 **장치별 경로**에 읽기전용으로 붙는다. 해당 장치를 빼면 그 장치의 마운트만 정리된다. Desktop에서 시험할 때는 파일 관리자의 자동 마운트를 꺼서 중복 마운트를 피한다.

기존 `/media/cart` 규칙에서 업데이트했다면 팩을 먼저 빼고 설치한 뒤 다시 꽂는다. 자세한 업데이트 절차는 [진단·관리](docs/maintenance.md#업데이트)를 참고한다.

### ② 계정·경로와 소리 확인

```bash
systemctl cat openmsx-cart
./scripts/doctor.sh
```

**소리를 3.5mm 잭으로 낼 거라면** `/etc/systemd/system/openmsx-cart.service`의 `#Environment=AUDIODEV=...` 주석을 해제하고 `sudo systemctl daemon-reload`를 실행한다. 재설치한 경우 기존 `.previous` 파일의 오디오 설정도 확인한다.

### ③ 콘솔 부팅 전환 + 화면 검증

```bash
sudo raspi-config    # System Options → Boot / Auto Login → Console Autologin
sudo reboot
```

재부팅 후 콘솔에서 **한 줄로** (환경변수와 명령은 같은 줄이어야 한다):

```bash
SDL_VIDEODRIVER=kmsdrm ~/iq2000-reborn/scripts/cart-watch.sh
```

openMSX가 화면에 뜨면 통과. `Ctrl+C`로 끄고 ④로.

### ④ 자동 실행 활성화 — 완성

```bash
sudo systemctl enable openmsx-cart
sudo reboot
```

재부팅 후 **아무것도 만지지 않아도** 아이큐 교실이 떠야 한다. 로그는 `journalctl -u openmsx-cart -f`.

## 8. 일상 운용 매뉴얼

| 하고 싶은 것 | 방법 |
|---|---|
| 켜기 | 전원 꽂기 → 잠시 후 아이큐 교실 |
| 게임 | USB 롬팩 꽂기 → 몇 초 후 게임 |
| 게임 끝 | **팩 뽑기** → 아이큐 교실 복귀 (읽기전용이라 안전) |
| BASIC 구경 | 아이큐 교실에서 F12 → 메뉴 따라 진행, `SCREEN 9` / `SCREEN 0` |
| 무적 | 5절 치트/트레이너 |
| **끄기** | ⚠️ 시스템 SD카드는 읽기/쓰기 상태다. 가급적 SSH에서 `sudo poweroff` 후 전원을 뽑자. 그냥 뽑아도 대개는 무사하지만 언젠가 SD가 상할 수 있다 |
| TV로 크게 | HDMI 연결 후 재부팅 — openMSX가 어느 화면에 뜨는지는 감지 순서에 달렸다. 7" 화면이 꺼지지는 않는다 |
| 데스크톱으로 복귀 | `sudo raspi-config` → Desktop Autologin. 자동 실행 끄기는 `sudo systemctl disable --now openmsx-cart` |

## 9. 트러블슈팅

| 증상 | 원인과 해법 |
|---|---|
| ⚡ low voltage warning / 전반적으로 굼뜸 | 전원 문제. **microUSB 케이블(짧고 굵은 것)부터 교체**, 어댑터 5V 2.5A+. 확인: `vcgencmd get_throttled` → `0x0`이 정상 |
| `SDL init failed: x11 not available` | 콘솔에서 환경변수 없이 실행했다. `SDL_VIDEODRIVER=kmsdrm 명령` 을 **한 줄로**. systemd 유닛에는 이미 들어 있다 |
| 소리가 안 남 (콘솔 모드) | ① 기본 출력이 오디오 없는 HDMI로 간 것 — 유닛에 `Environment=AUDIODEV=sysdefault:CARD=Headphones` (3.5mm 잭. 카드명은 `aplay -l`) ② openMSX 음소거 — F10 콘솔에서 `set mute off`, `set master_volume 100` |
| `ALSA ... error 524` | 그 출력 장치(주로 HDMI)가 오디오를 지원하지 않는다. 다른 카드로 |
| ROM이 여러 개라는 로그 | 다른 게임 USB를 빼고 팩 루트에 ROM 하나만 남긴다 |
| openMSX가 반복해서 재실행됨 | `./scripts/doctor.sh`와 `journalctl -u openmsx-cart -n 50`로 ROM·화면 설정을 확인한다 |
| 아이큐 교실만 뜨고 게임이 안 뜸 | 정상일 수 있다 — **F12로 진입**하는 것이 실기 동작. 그게 아니면 `./scripts/cart-find.sh` 로 롬을 찾는지 확인 (zip 풀기, 확장자 `.rom`) |
| 에뮬레이션이 느림 | [docs/raspberry-pi.md](docs/raspberry-pi.md)의 Pi 3 튜닝 절 (`scale_factor 1` 등). 지루한 연출은 F7 빨리감기 |
| 터치스크린에 가상 키보드가 자꾸 뜸 (Desktop) | Raspberry Pi Configuration → Display → On-screen Keyboard → Disabled. 또는 `sudo apt purge squeekboard` |
| 팩 라벨이 깨져 보임 | FAT 라벨의 한글 문제. 영문 라벨을 쓰자 |

## 10. 부록 — 선택 확장

필수는 아니지만 해두면 재미있는 것들:

- **스피커 내장** — 3.5mm 잭에 PAM8403 앰프 모듈(천 원 안팎) + 아무 소형 스피커. MSX 소리는 원래 모노다.
- **물리 SELECT 버튼** — 아케이드 버튼을 GPIO23(핀16)+GND(핀14)에 직결하고 `/boot/firmware/config.txt`에 `dtoverlay=gpio-key,gpio=23,active_low=1,gpio_pull=up,keycode=88` 한 줄이면 버튼이 F12가 된다. **버튼 한 방에 무적** — 키보드 없는 재믹스에선 불가능했던 치트가 버튼이 된다. 상세 → [`docs/keyboard.md`](docs/keyboard.md)
- **USB 독** — USB 포트에 슬롯/독 형태의 연장 어댑터를 달면 "팩 꽂는 맛"이 산다. 굴러다니는 독을 발견하면 그게 마지막 퍼즐.
- **오디오 되는 모니터/TV** — 유닛의 `AUDIODEV`를 `sysdefault:CARD=vc4hdmi`로 바꾸면 소리가 TV로 간다. 실기도 TV로 소리를 냈다.

## 11. 프로젝트 여정

- [x] 1단계 — openMSX + 한글 ROM 부팅 (2026-09-18, Windows)
- [x] 2단계 — 라즈베리파이 이식, 부팅 자동 실행 (2026-09-20)
- [x] 3단계 — USB 롬팩 감시 (2026-09-20)
- [x] 4단계 — 키 매핑 + 마성전설 치트 (2026-09-20)
- [x] ~~5단계 — 케이스~~ → **폐기.** 공식 7" 디스플레이의 전용 케이스로 충분했다
- [x] ~~6단계 — GPIO 조이스틱·버튼~~ → **폐기.** 요즘 조이스틱은 버튼이 많아 MSX(2버튼)에는 낭비고 값도 아깝다. SELECT 버튼만 부록으로 남김
- [x] ~~7단계 — Pico 카트리지 덤퍼 / 8단계 — 롬팩 자작~~ → **폐기.** 오버엔지니어링이었다

**이 프로젝트는 완성됐다.** 이후는 운용과 소소한 확장(부록)만 남는다.

## 스크립트·문서

| 파일 | 역할 |
|---|---|
| `scripts/install.sh` | 패키지 설치 / `--keys` 키 설정 / `--system` 서비스·USB 규칙 설치 |
| `scripts/doctor.sh` | 환경·설정·팩 검색·서비스 상태 진단 |
| `scripts/msx-run.sh` | openMSX 실행 (인자로 롬 경로 = 카트리지) |
| `scripts/cart-find.sh` / `cart-label.sh` | 마운트된 USB에서 롬/라벨 찾기 |
| `scripts/cart-watch.sh` | USB 감시 → 변화 시 openMSX 재시작 |
| `scripts/msx-keys.tcl` | F키 바인딩 (F12=SELECT 등) |
| `scripts/cheat-knightmare.tcl` | 마성전설 치트 (`cheat`/`lives`/`sel`) |
| `systemd/openmsx-cart.service` | 부팅 자동 실행 유닛 |
| `systemd/99-msx-cart.rules` | USB → `/media/iq2000/<장치명>` 읽기전용 자동 마운트 |
| [`docs/raspberry-pi.md`](docs/raspberry-pi.md) | OS·성능 튜닝·전용기 전환·소리 상세 |
| [`docs/keyboard.md`](docs/keyboard.md) | 키 매트릭스·치트 원리·GPIO 버튼 |
| [`docs/hardware.md`](docs/hardware.md) | 기종 계보·판별 근거 |

환경변수: `MSX_MACHINE`(기본 `Daewoo_CPC-300`) · `MSX_POLL`(감시 주기 초, 기본 `2`) · `MSX_RESTART_DELAY`(재실행 대기 초, 기본 `3`) · `MSX_CART_ROOT`(검색 디렉터리 직접 지정). 시간은 1~300의 정수. [진단·관리 및 개발 검증](docs/maintenance.md) 참고.

## 링크

- [openMSX](https://openmsx.org)
- [IQ-2000 한글 ROM + openMSX 설정 안내](https://sarc.io/articles/daewoo-iq2000-cpc-300-msx2-openmsx)
- [MSX Resource Center](https://www.msx.org) · [Generation MSX](https://www.generation-msx.nl)
- [JoyNets — MSX-TUTOR 아이큐 교실](https://hwado.org/249)
- [대우전자의 MSX 컴퓨터 (나무위키)](https://namu.wiki/w/대우전자의%20MSX%20컴퓨터)
- 실기 구하기 — [중고나라 IQ-2000](https://web.joongna.com/search/IQ-2000) (점검: 전원부 콘덴서·키보드 멤브레인(`SELECT` 필수!)·슬롯 접점·영상 출력)

## 라이선스

스크립트·문서: MIT ([`LICENSE`](LICENSE))
**MSX BIOS·한글 ROM·게임 ROM은 각 권리자의 저작물이며 이 저장소에 포함되지 않는다.**
