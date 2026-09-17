# ─────────────────────────────────────────────────────────────
#  마성전설 (Knightmare, 1986 코나미) 투명화 치트
#
#  원래 조작:
#    타이틀 화면("PUSH SPACE KEY")에서
#    ← + → + Y + SELECT 를 게임 화면이 나올 때까지 누르고 있는다
#      → Y  : 투명화 무한
#      → I  : 투명화 3회
#      → N  : 목숨 25개
#      → I+N: 목숨 25개 + 투명화 3회
#    게임 중에는 SELECT 를 연타하면 투명 상태가 유지된다.
#
#  문제:
#    PC 키보드는 4키 동시입력을 흘리는 경우가 많고(고스팅),
#    SELECT 키는 애초에 없다.
#
#  해법:
#    MSX 키 매트릭스를 직접 눌러버린다. 키보드를 거치지 않으므로
#    동시입력 제한이 사라진다.
#
#  ⚠️ 매트릭스 행/비트는 MSX 표준 배열 기준이다.
#     동작하지 않으면 docs/keyboard.md 의 표와 openMSX 문서를 대조할 것.
# ─────────────────────────────────────────────────────────────

# LEFT = 행8 bit4(0x10), RIGHT = 행8 bit7(0x80)  → 같은 행이라 0x90
set ::KM_ARROWS_ROW  8
set ::KM_ARROWS_MASK 0x90
set ::KM_Y_ROW       5
set ::KM_Y_MASK      0x40
set ::KM_SELECT_ROW  7
set ::KM_SELECT_MASK 0x40
set ::KM_I_ROW       3
set ::KM_I_MASK      0x40   ;# 행3: C D E F G H I J → I = bit6
set ::KM_N_ROW       4
set ::KM_N_MASK      0x08   ;# 행4: K L M N O P Q R → N = bit3

# 지정한 조합을 hold_ms 밀리초 동안 누른다
proc _kn_hold {rows_masks hold_ms} {
    foreach {r m} $rows_masks { keymatrixdown $r $m }
    after $hold_ms [list _kn_release $rows_masks]
}
proc _kn_release {rows_masks} {
    foreach {r m} $rows_masks { keymatrixup $r $m }
    puts "\[cheat\] 해제됨"
}

# 투명화 무한 (← + → + Y + SELECT)
proc knightmare_cheat {{hold_ms 4000}} {
    puts "\[cheat\] 투명화 무한 — ←+→+Y+SELECT ${hold_ms}ms 유지"
    _kn_hold [list $::KM_ARROWS_ROW $::KM_ARROWS_MASK \
                   $::KM_Y_ROW      $::KM_Y_MASK \
                   $::KM_SELECT_ROW $::KM_SELECT_MASK] $hold_ms
}

# 목숨 25개 + 투명화 3회 (← + → + I + N + SELECT)
proc knightmare_cheat_lives {{hold_ms 4000}} {
    puts "\[cheat\] 목숨25+투명3 — ←+→+I+N+SELECT ${hold_ms}ms 유지"
    _kn_hold [list $::KM_ARROWS_ROW $::KM_ARROWS_MASK \
                   $::KM_I_ROW      $::KM_I_MASK \
                   $::KM_N_ROW      $::KM_N_MASK \
                   $::KM_SELECT_ROW $::KM_SELECT_MASK] $hold_ms
}

# 게임 중 투명화 발동용 — SELECT 한 번 톡
proc msx_select {{hold_ms 60}} {
    keymatrixdown $::KM_SELECT_ROW $::KM_SELECT_MASK
    after $hold_ms [list keymatrixup $::KM_SELECT_ROW $::KM_SELECT_MASK]
}

puts "마성전설 치트 로드됨:"
puts "  knightmare_cheat        타이틀에서 실행 → 투명화 무한"
puts "  knightmare_cheat_lives  타이틀에서 실행 → 목숨25 + 투명3"
puts "  msx_select              게임 중 SELECT 한 번 (연타 대용)"
