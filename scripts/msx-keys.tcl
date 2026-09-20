# openMSX 시작 시 자동 적용되는 키 바인딩
#
# 설치:
#   mkdir -p ~/.openMSX/share/scripts
#   cp scripts/msx-keys.tcl ~/.openMSX/share/scripts/
#
# ~/.openMSX/share/scripts/ 안의 .tcl 은 openMSX 시작 시 자동 실행된다.
#
# ⚠️ 매트릭스 행/비트는 MSX 표준 배열 기준이다. docs/keyboard.md 참조.

# ── PC 키보드에 없는 MSX 키를 F키에 붙인다 ──
# SELECT = 행7 bit6
bind F12          "keymatrixdown 7 0x40"
bind F12,release  "keymatrixup   7 0x40"
# STOP   = 행7 bit4
bind F11          "keymatrixdown 7 0x10"
bind F11,release  "keymatrixup   7 0x10"
# GRAPH  = 행6 bit2
bind F9           "keymatrixdown 6 0x04"
bind F9,release   "keymatrixup   6 0x04"
# CODE(한/영 계열) = 행6 bit4
bind F8           "keymatrixdown 6 0x10"
bind F8,release   "keymatrixup   6 0x10"

# ── F7 = 누르는 동안 빨리감기 ──
# 아이큐 교실의 한 글자씩 찍는 연출 등을 스킵할 때. 떼면 정상 속도로 복귀.
bind F7           "set throttle off"
bind F7,release   "set throttle on"

puts "MSX 키 바인딩: F12=SELECT  F11=STOP  F9=GRAPH  F8=CODE  F7=빨리감기(홀드)"
