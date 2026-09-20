# iq2000-reborn

**대우 IQ-2000 (CPC-300) — 국산 MSX2를 라즈베리파이로 재현하는 프로젝트.**

openMSX로 IQ-2000을 부팅하고, 저용량 USB 메모리를 「롬팩」처럼 갈아 끼우는 전용기를 만든다.
목표는 **한글이 표시되는 국산 MSX2 환경의 재현** — 일본 MSX2로는 대체되지 않는 부분이다.

> ✅ **2026-09-18**: Windows에서 openMSX 21.0 / `Daewoo CPC-300` 부팅 확인.
> **「MSX-TUTOR / 아이큐 교실」** 한글 표시 정상 — 한글 ROM 인식 검증 완료.

---

## 왜 CPC-300인가

대우 MSX 계열 중 **한글 지원 + 키보드 일체형 + FDD 없음** 조건을 동시에 만족하는 기종이 CPC-300이다.

| 조건 | 이유 |
|---|---|
| **한글 ROM 내장** | 일본 MSX에는 한글 ROM이 없다. 국산 기종이어야 한다 → **IQ-1000(CPC-88)은 한글 미지원**이라 제외 |
| **키보드 일체형** | 분리형인 **X-II(CPC-400)·CPC-400S** 제외 |
| **FDD 없음** | 〃 (CPC-400 계열은 FDD 내장) |
| **조이스틱 포트 있음** | 학교 납품 교육용 **CPC-300E는 조이스틱 포트가 없다** |

👉 **대우 IQ-2000 (CPC-300)** — MSX2, RAM/VRAM 128KB, **한글 2.0 조합형 고딕체** 내장, 1986~87.
전원을 켜면 BASIC이 아니라 내장 교육 프로그램 **「아이큐 교실」(MSX-TUTOR)** 로 먼저 진입한다.

계열 전체 비교표 → [`docs/hardware.md`](docs/hardware.md)

## 어떤 OS로 시작하나

**Raspberry Pi OS (64-bit) / Bookworm.** Debian 기반이라 openMSX가 apt 저장소에 있다.

| | Desktop 버전 | Lite 버전 |
|---|---|---|
| 난이도 | ⭐ **여기서 시작** | ⭐⭐⭐ |
| 자동 실행 | `~/.config/autostart/` | systemd |
| `SDL_VIDEODRIVER` | `wayland` 또는 `x11` | **`kmsdrm`** |
| 성격 | 검증하기 쉽다 | **전용기답다** |

👉 **Desktop으로 먼저 동작을 확인하고 Lite로 옮긴다.** 처음부터 Lite로 가면 화면이 안 뜰 때 원인을 못 가린다.
⚠️ **Bookworm은 Wayland가 기본이다.** 이 저장소의 systemd 유닛은 `kmsdrm`(=Lite 기준)이므로 Desktop에서 쓰려면 값을 바꿔야 한다.

**Pi 4면 MSX2에 충분하고, Pi 3도 설정을 깎으면 된다.** 설치·빌드·경로·Pi 3 튜닝 상세 → [`docs/raspberry-pi.md`](docs/raspberry-pi.md)

## 빠른 시작

```bash
git clone https://github.com/progh2/iq2000-reborn.git ~/iq2000-reborn
cd ~/iq2000-reborn
./scripts/install.sh          # openMSX 설치 + systemroms 디렉터리 생성
# 아래 3개 ROM을 ~/.openMSX/share/systemroms/ 에 넣는다
./scripts/msx-run.sh          # 카트리지 없이 부팅 → 「아이큐 교실」
./scripts/msx-run.sh /path/to/game.rom   # 팩 꽂고 부팅
```

### 필요한 ROM 3개

| 파일 | 역할 | 필수 |
|---|---|---|
| `cpc-300_basic-bios2.rom` | 메인 ROM — BIOS + MSX-BASIC (부팅·파란 BASIC 화면) | ✅ |
| `cpc-300_msx2sub.rom` | MSX2 SUB-ROM — 확장 기능·화면 모드 | ✅ |
| `cpc-300_hangul.rom` | 🇰🇷 **한글 ROM** — `SCREEN 9` / 「아이큐 교실」의 실체 | ✅ **핵심** |
| ~~`cpc-300e_msx2sub.rom`~~ | 교육용 CPC-300E 전용 | ❌ 불필요 |

- **파일명은 무관하다.** openMSX는 SHA1 해시로 판별한다. 해시가 다른 판본이면 인식하지 못하고, 실행 시 어느 ROM이 없는지 알려준다.
- 🔴 **한글 ROM만 빠지면 부팅은 되지만 `SCREEN 9`에서 한글이 안 나온다.** 증상으로 바로 구분된다.
- ⚠️ openMSX에 기본 포함된 **C-BIOS**(자유 라이선스)로는 **BASIC이 없어 `SCREEN 9`을 칠 수 없다.** 게임 팩 구동만 된다.

> ⚖️ **ROM 저작권** — CPC-300의 BIOS·한글 ROM은 대우전자 저작물이다.
> 정당한 경로는 **본인 실기에서 직접 덤프**하는 것이며, **이 저장소는 ROM을 포함하지 않는다**(`.gitignore`로 차단).

## 한글 화면 보기

부팅 후 BASIC 프롬프트(`Ok`)에서

```basic
SCREEN 9
```

📌 **CPC-300은 전원을 켜면 BASIC이 아니라 내장 교육 프로그램 「아이큐 교실」로 먼저 들어간다.** BASIC으로 빠져나가려면 메뉴의 종료 항목이나 `ESC`를 시도한다.

## ⌨️ 키보드 매핑 — `SELECT` 키가 없다

MSX에는 **PC 키보드에 없는 키**가 있고, 그게 실제로 필요하다.

| MSX 키 | 쓰임 |
|---|---|
| **`SELECT`** | 🔴 **마성전설 투명화(무적) 발동** |
| `STOP` | BASIC 실행 중단 |
| `GRAPH` | 그래픽 문자 |
| `CODE` | 한국 기종의 한/영 전환 계열 |

**해결: MSX 키 매트릭스를 직접 두드린다.** 준비된 바인딩을 깔면 F키로 쓸 수 있다.

```bash
mkdir -p ~/.openMSX/share/scripts
cp scripts/msx-keys.tcl ~/.openMSX/share/scripts/
#  → F12=SELECT  F11=STOP  F9=GRAPH  F8=CODE  F7=빨리감기(홀드)
```

`~/.openMSX/share/scripts/` 안의 `.tcl` 은 **openMSX 시작 시 자동 실행**된다.

### 🔴 마성전설 치트의 4키 동시입력 문제

원래 조작은 타이틀에서 **`← + → + Y + SELECT` 를 게임 화면이 나올 때까지 누르고 있는 것**인데, **PC 키보드가 4키 동시입력을 흘리는 경우가 많다**(고스팅). `SELECT`는 아예 없다.

**해법 — 매트릭스를 한꺼번에 눌러버린다.** 키보드를 거치지 않으니 제한이 사라진다.

```tcl
source scripts/cheat-knightmare.tcl
knightmare_cheat          ;# 타이틀에서 → 투명화 무한
knightmare_cheat_lives    ;# 타이틀에서 → 목숨25 + 투명3
msx_select                ;# 게임 중 SELECT 한 번 (연타 대용)
```

상세·매트릭스 표·GPIO 버튼 확장 → [`docs/keyboard.md`](docs/keyboard.md)

## 🎮 USB 롬팩 — 이 프로젝트의 핵심

저용량 USB 메모리를 팩처럼 갈아 끼운다. **꽂으면 그 안의 ROM으로 openMSX가 다시 뜨고, 빼면 「아이큐 교실」로 돌아온다.**

```
[USB 팩] → 자동 마운트 → cart-watch.sh (감시)
                              ↓
              openMSX (-machine Daewoo_CPC-300 -cart …)
                              ↓
                   HDMI 모니터 + USB 키보드
```

### 📌 왜 「재시작」이 옳은가

실기 MSX도 **카트리지는 전원을 끄고 갈아야 했다.** 켠 상태로 뽑으면 멈추거나 상했다.
그러므로 **"꽂으면 재시작"은 편법이 아니라 원래 동작에 충실한 방식이다.**

(openMSX의 외부 제어 인터페이스 `-control stdio` 로 재시작 없이 교체하는 것도 가능하지만, 그러면 전원 끄고 갈아 끼우는 맛이 사라진다.)

### 실행

```bash
./scripts/cart-watch.sh
```

### 부팅 시 자동 실행

**A. 데스크톱 환경 (쉬움)**
```bash
cp systemd/openmsx-desktop.desktop ~/.config/autostart/
# Exec= 경로를 본인 환경으로 수정
```

**B. 콘솔 전용기 (전용기답게)**
```bash
sudo cp systemd/openmsx-cart.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now openmsx-cart
journalctl -u openmsx-cart -f     # 로그
```
⚠️ `User=` 와 `ExecStart=` 경로를 고칠 것. 데스크톱 없이 띄울 때 `SDL_VIDEODRIVER=kmsdrm` 이 안 잡히면 로그를 보고 조정한다. **A로 먼저 검증하고 B로 옮기는 편이 편하다.**

### 팩 느낌을 살리는 디테일

| 아이디어 | |
|---|---|
| **USB 하나에 게임 하나** | 여러 개 사두고 갈아 끼운다 |
| **저용량 구형 USB** (128MB~1GB) | 롬이 32KB~256KB라 딱 맞고, 물건의 무게감도 그 시절 같다 |
| **볼륨 레이블에 게임명** | `cart-label.sh` 가 읽어 로그·화면에 표시 |
| **라벨 스티커** | 팩 라벨처럼 붙인다 |
| **3D 프린터 케이스** | USB를 감싸 MSX 팩 모양으로 |

## 스크립트

| 파일 | 역할 |
|---|---|
| `scripts/install.sh` | openMSX 설치 + `~/.openMSX/share/systemroms` 생성 |
| `scripts/msx-run.sh` | openMSX 실행. 인자로 롬 경로를 주면 카트리지로 꽂는다 |
| `scripts/cart-find.sh` | 마운트된 USB에서 `*.rom` / `*.mx1` / `*.mx2` 를 찾아 경로 출력 |
| `scripts/cart-label.sh` | 해당 USB의 볼륨 레이블 출력 (없으면 파일명) |
| `scripts/cart-watch.sh` | **USB 감시 → 변화 시 openMSX 재시작** |
| `scripts/msx-keys.tcl` | MSX 전용 키를 F키에 바인딩 (F12=SELECT 등) |
| `scripts/cheat-knightmare.tcl` | 마성전설 치트 — 키 매트릭스 직접 조작으로 동시입력 제한 우회 |

환경변수: `MSX_MACHINE`(기본 `Daewoo_CPC-300`) · `MSX_POLL`(감시 주기 초, 기본 `2`)

⚠️ **자동 마운트 경로는 USB마다 다를 수 있다**(`/media/usb0`, `/media/<LABEL>` 등). `cart-find.sh` 는 `/media`·`/run/media`·`/mnt` 아래 3단계까지 훑어 첫 롬을 쓴다.

## 로드맵

- [x] **1단계 — openMSX + 한글 ROM으로 부팅** (2026-09-18 Windows에서 확인)
- [ ] **2단계 — 라즈베리파이 이식**, 부팅 시 자동 실행
- [ ] **3단계 — USB 롬팩 감시** 동작 검증
- [ ] **4단계 — 키보드 매핑 + 마성전설 치트 재현** (`msx-keys.tcl` · `cheat-knightmare.tcl` 작성 완료, **동작 검증 필요**)
- [ ] **5단계 — 케이스** (라즈베리파이 숨기고 USB 슬롯만 앞으로)
- [ ] 6단계 — GPIO 조이스틱·버튼
- [ ] 7단계 — **Pico(RP2040) 카트리지 덤퍼** → 실물 팩을 ROM으로 (→ [`docs/hardware.md`](docs/hardware.md))
- [ ] 8단계 — 32KB 단순 롬팩 자작 (EPROM + 디코더)

## 문서

| 문서 | 내용 |
|---|---|
| [`docs/raspberry-pi.md`](docs/raspberry-pi.md) | OS 선택(Desktop vs Lite)·설치·openMSX 빌드·ROM 경로·성능 |
| [`docs/keyboard.md`](docs/keyboard.md) | MSX 전용 키·키 매트릭스 표·치트 우회·GPIO 버튼 확장 |
| [`docs/hardware.md`](docs/hardware.md) | 기종 판별 근거·대우/재믹스 계열 비교·카트리지 슬롯 50핀·덤퍼 경로 |

## 링크

**에뮬레이터**
- openMSX 공식 — https://openmsx.org
- IQ-2000 한글 ROM + openMSX 설정 안내 — https://sarc.io/articles/daewoo-iq2000-cpc-300-msx2-openmsx

**자료**
- MSX Resource Center — https://www.msx.org
- Generation MSX (소프트 DB) — https://www.generation-msx.nl
- JoyNets — MSX-TUTOR 아이큐 교실 — https://hwado.org/249
- 대우전자의 MSX 컴퓨터 (나무위키) — https://namu.wiki/w/대우전자의%20MSX%20컴퓨터
- 마성전설 (치트 정보) — https://namu.wiki/w/마성전설

**하드웨어 (참고)**
- MegaFlashROM SCC+ SD — https://www.msx.org/wiki/MSX_Cartridge_Shop_MegaFlashROM_SCC+_SD
- Carnivore2 — https://www.8bits4ever.net/product-page/carnivore2
- SX-E MSX2+ FPGA — https://www.8bits4ever.net/product-page/sxe-msx2-fpga-computer
- Zemmix Neo (100대 한정·비상용) — https://www.msx.org/wiki/Zemmix_Neo

**실기 구하기**
- 중고나라 IQ-2000 — https://web.joongna.com/search/IQ-2000
- 중고나라 MSX — https://web.joongna.com/search/Msx

🔎 실기 구입 시 점검: 전원부 전해 콘덴서 · 키보드 멤브레인(**`SELECT` 키 필수**) · 롬팩 슬롯 접점 산화 · 영상 출력(RF/컴포지트 → RGB 개조나 업스케일러 필요)

## 라이선스

스크립트·문서: MIT ([`LICENSE`](LICENSE))
**MSX BIOS·한글 ROM·게임 ROM은 각 권리자의 저작물이며 이 저장소에 포함되지 않는다.**
