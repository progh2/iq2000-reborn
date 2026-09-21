---
title: 진단과 관리
description: IQ-2000 재현기의 환경 진단, 설정 백업, 업데이트와 개발 검증 절차.
---

# 진단과 관리

[설치와 사용 안내](../README.md) · [프로젝트 홈](../index.html)

## 빠른 진단

저장소 디렉터리에서 실행한다. 시스템 설정을 바꾸지 않는다.

```bash
./scripts/doctor.sh
journalctl -u openmsx-cart -n 50 --no-pager
```

진단은 openMSX 설치, 키 스크립트, USB 팩 검색, 서비스 상태와 Pi 저전압 상태를 보여준다. BIOS는 파일명이나 개수로 정상 여부를 판정하지 않는다. `./scripts/msx-run.sh`로 실제 한글 부팅을 확인한다.

## 팩 검색과 자동 복구

- 기본 검색: `/media`, `/run/media`, `/mnt` 아래에 마운트된 **FAT USB의 루트**만 검색한다.
- `.rom`, `.mx1`, `.mx2`를 대소문자 구분 없이 찾는다. 공백과 한글 파일명을 지원한다.
- 팩 하나에 ROM 하나만 둔다. 여러 ROM이 발견되면 오류를 한 번 기록하고 아이큐 교실로 돌아간다. 다른 USB 저장장치의 ROM도 발견될 수 있으므로 게임 팩만 연결한다.
- 같은 장치의 중복 마운트는 같은 파일로 취급한다. 줄바꿈이 포함된 파일명은 거부한다.
- openMSX가 종료되면 다음 감시 시점에 감지하고 기본 3초 후 다시 실행한다. 반복 실패하면 로그에서 BIOS·비디오·오디오 오류를 확인한다.
- 감시기는 사용자별 하나만 실행할 수 있다. 수동 실행 전에 `sudo systemctl stop openmsx-cart`로 서비스를 중지한다.
- 팩을 바꿀 때는 기존 팩을 빼고 아이큐 교실로 돌아온 뒤 새 팩을 꽂는다. 감시 주기 사이에 같은 경로로 교체한 모든 경우를 구분할 수는 없다.

| 환경변수 | 기본값 | 역할 |
|---|---|---|
| `MSX_MACHINE` | `Daewoo_CPC-300` | openMSX 머신 |
| `MSX_POLL` | `2` | 감시 주기, 1~300초 정수 |
| `MSX_RESTART_DELAY` | `3` | 종료 감지 후 재실행 대기, 1~300초 정수 |
| `MSX_CART_ROOT` | 미지정 | 지정한 디렉터리 하나의 루트만 검색. 수동 마운트·개발용 |

수동 검색 예시:

```bash
MSX_CART_ROOT="/media/iq2000/sda1" ./scripts/cart-find.sh
```

`MSX_CART_ROOT`는 일반 폴더도 허용하므로 읽기전용 USB 여부를 보장하지 않는다. 서비스에 적용하려면 유닛의 `[Service]`에 `Environment=...`를 추가한 뒤 `daemon-reload`와 서비스 재시작을 한다.

## 설정 백업

openMSX를 종료한 뒤 사용자 설정을 백업한다. ROM을 포함한 백업이므로 개인적으로 보관한다.

```bash
sudo systemctl stop openmsx-cart
mkdir -p ~/iq2000-backups
tar -czf ~/iq2000-backups/openmsx-$(date +%Y%m%d-%H%M%S).tar.gz -C ~ .openMSX
```

`install.sh --keys`는 기존 Tcl 파일을 `.~1~` 같은 번호 백업으로 보관한다. `install.sh --system`은 기존 서비스·udev 파일을 `.previous`로 보관하며, 재실행하면 이전 백업은 교체된다. 장기 보관이 필요하면 별도로 복사한다.

## 업데이트

기존 설치의 USB 팩을 먼저 빼고 진행한다.

```bash
sudo systemctl stop openmsx-cart
cd ~/iq2000-reborn
git pull --ff-only
./scripts/install.sh --keys
./scripts/install.sh --system
```

기존 서비스의 `AUDIODEV` 등 사용자 변경은 `/etc/systemd/system/openmsx-cart.service.previous`와 비교해 새 유닛에 반영한다. 이전 `/media/cart`가 남아 있으면 `findmnt /media/cart`로 확인하고 `sudo systemd-umount /media/cart`로 정리한다. 새 규칙은 `/media/iq2000/<장치명>`에 마운트한다.

```bash
sudo systemctl daemon-reload
# 팩을 다시 연결한 뒤
./scripts/doctor.sh
sudo systemctl start openmsx-cart
```

데스크톱으로 돌아가려면 `sudo systemctl disable --now openmsx-cart` 후 `sudo raspi-config`에서 Desktop Autologin으로 바꾼다. USB 규칙도 제거하려면 `/etc/udev/rules.d/99-msx-cart.rules`를 삭제하고 `sudo udevadm control --reload` 후 팩을 다시 연결한다.

## 검증 기록

| 항목 | 기록 |
|---|---|
| 최초 실기 검증 | 2026-09-20 |
| 보드 | Raspberry Pi 3 B+ |
| 디스플레이 | 공식 7″ 터치스크린 |
| OS | Raspberry Pi OS Trixie 32-bit, Desktop 설치 후 콘솔 전환 |
| 확인된 기능 | 한글 아이큐 교실, USB 롬팩, 부팅 자동 실행, 키 매핑·치트 |
| 당시 openMSX 버전·OS 이미지 날짜 | 기존 기록에 없음. 다음 실기 검증 시 `doctor.sh` 결과와 함께 기록 |
| 이후 변경 | 감시기 복구, USB 마운트 분리, 설치·진단, 웹페이지 개선. 자동 테스트와 실기 검증을 구분해 관리 |

새 USB 규칙 적용 후에는 **콜드 부팅, 팩 삽입·제거, 다른 USB 제거, 여러 팩 연결, openMSX 종료 후 복구, 정상 전원 종료**를 실제 Pi에서 확인한다. 모의 테스트는 kmsdrm·udev·실제 BIOS의 동작 검증을 대신하지 않는다.

## 개발 검증

ROM과 관리자 권한 없이 테스트한다.

```bash
python3 -m unittest discover -s tests -v
bash -n scripts/cart-watch.sh
shellcheck scripts/*.sh
```

웹페이지는 GitHub Pages/Jekyll로 빌드한다. Ruby와 Bundler 설치 후:

```bash
bundle install
bundle exec jekyll serve --host 127.0.0.1
```

미리보기: `http://127.0.0.1:4000/iq2000-reborn/`. README는 `/guide/`, 프로젝트 소개는 `/`에 게시된다. 이전 홈페이지의 목차 북마크는 설치 안내로 연결된다.

CI는 셸 검사, 스크립트 회귀 테스트, Jekyll 빌드 및 내부 링크·앵커 검사를 수행한다.
