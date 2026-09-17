# 키보드 매핑 — MSX에만 있는 키들

## 왜 매핑이 필요한가

MSX 키보드에는 **PC 키보드에 없는 키**가 있다. 이 키들이 있어야 되는 일이 실제로 있다.

| MSX 키 | 쓰임 |
|---|---|
| **`SELECT`** | 🔴 **마성전설 투명화(무적) 발동.** 일부 게임의 메뉴·모드 전환 |
| **`STOP`** | BASIC 실행 중단 (PC의 Break에 해당) |
| **`GRAPH`** | 그래픽 문자 입력 |
| **`CODE` / `かな`** | 한국 기종에서 **한/영 전환** 계열 |
| **`DEAD`** | 액센트 문자 |

PC 키보드로 치려면 **어느 호스트 키를 어느 MSX 키로 보낼지** 정해야 한다.

## 방법 1 — 현재 매핑 확인

openMSX는 호스트 키를 MSX 키로 자동 매핑한다. 기본값이 무엇인지는 **버전·플랫폼·`kbd_mapping_mode` 설정에 따라 달라지므로** 먼저 확인한다.

openMSX **Tcl 콘솔**을 열고(기본 단축키는 빌드마다 다르다 — OSD 메뉴의 Tools 항목에서 찾을 수 있다):

```tcl
set kbd_mapping_mode        ;# 현재 매핑 방식
help keymatrixdown          ;# 키 매트릭스 조작 도움말
```

## 방법 2 — 키 매트릭스를 직접 두드린다 (확실한 방법)

가장 확실한 길은 **호스트 키를 MSX 키 매트릭스에 직접 연결**하는 것이다. openMSX의 `keymatrixdown` / `keymatrixup` 명령을 쓴다.

```tcl
keymatrixdown <행> <비트마스크>    ;# 누름
keymatrixup   <행> <비트마스크>    ;# 뗌
```

### MSX 표준 키 매트릭스 (참고용)

| 행 | bit0 | bit1 | bit2 | bit3 | bit4 | bit5 | bit6 | bit7 |
|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| 1 | 8 | 9 | - | = | \ | [ | ] | ; |
| 2 | ' | ` | , | . | / | DEAD | A | B |
| 3 | C | D | E | F | G | H | I | J |
| 4 | K | L | M | N | O | P | Q | R |
| 5 | S | T | U | V | W | X | **Y** | Z |
| 6 | SHIFT | CTRL | GRAPH | CAPS | CODE | F1 | F2 | F3 |
| 7 | F4 | F5 | ESC | TAB | STOP | BS | **SELECT** | RETURN |
| 8 | SPACE | HOME | INS | DEL | **LEFT** | UP | DOWN | **RIGHT** |

> ⚠️ **이 표는 MSX 표준 배열 기준이다.** 실제 동작이 다르면 openMSX 문서(`doc/` 또는 공식 매뉴얼)와 대조해 바로잡을 것. 아래 스크립트도 그때 같이 고친다.

### 예 — `F12` 를 `SELECT` 로 쓰기

`SELECT` = **행 7, bit 6** → 마스크 `0x40`

```tcl
bind F12       "keymatrixdown 7 0x40"
bind F12,release "keymatrixup 7 0x40"
```

이러면 F12를 누르고 있는 동안 MSX는 `SELECT`가 눌린 것으로 본다. **마성전설에서 F12를 연타하면 투명화가 유지된다.**

## 🔴 마성전설 치트 — 4키 동시입력 문제와 해법

원래 조작은 **타이틀 화면에서 `← + → + Y + SELECT` 를 게임 화면이 나올 때까지 누르고 있는 것**이다.

문제는 **PC 키보드가 4키 동시입력을 흘리는 경우가 많다**(고스팅). 게다가 `SELECT`는 아예 없다.

**해법: 매트릭스를 한꺼번에 눌러버린다.** 키보드를 거치지 않으니 동시입력 제한이 사라진다.

필요한 값
- `LEFT` = 행 8, bit 4 → `0x10`
- `RIGHT` = 행 8, bit 7 → `0x80` → 둘이 같은 행이므로 합쳐서 `0x90`
- `Y` = 행 5, bit 6 → `0x40`
- `SELECT` = 행 7, bit 6 → `0x40`

→ 준비된 스크립트: [`scripts/cheat-knightmare.tcl`](../scripts/cheat-knightmare.tcl)

```tcl
source scripts/cheat-knightmare.tcl   ;# openMSX Tcl 콘솔에서
knightmare_cheat                       ;# 타이틀 화면에서 실행
```

## 설정을 영구 저장하기

`bind` 는 기본적으로 세션 한정이다. 매번 쓰려면 openMSX 시작 스크립트에 넣는다.

```bash
mkdir -p ~/.openMSX/share/scripts
cp scripts/msx-keys.tcl ~/.openMSX/share/scripts/
```

`~/.openMSX/share/scripts/` 안의 `.tcl` 파일은 **openMSX 시작 시 자동 실행**된다.

## GPIO 버튼으로 SELECT 만들기 (확장)

전용기 케이스를 만들 때, GPIO 버튼을 `SELECT` 에 연결하면 실기 감각이 살아난다.

1. GPIO 입력을 읽는 작은 파이썬·C 프로그램을 띄운다
2. 버튼이 눌리면 openMSX **외부 제어 인터페이스**(`openmsx -control stdio`)로 `keymatrixdown 7 0x40` 을 보낸다
3. 떼면 `keymatrixup 7 0x40`

📌 **재믹스에는 키보드가 없어 이 조작을 아예 할 수 없었다**(수퍼 V부터 키보드 별매 연결 가능). GPIO 버튼을 달면 **재믹스에서는 불가능했던 치트를 재믹스 형태의 기계에서 쓸 수 있게** 된다.
