extends Control
## 타이틀. 민초단 입단 문구와 현재 득표(민초 열세)를 보여주고 허브로 보낸다. 임시 버전: 모양은 디자인 단계에서 만든다.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const BAR_W: float = 1200.0
const BAR_H: float = 80.0


func _ready() -> void:
	GameState.reset() # 타이틀은 항상 새 방문자의 시작점
	var bg: ColorRect = ColorRect.new()
	bg.color = PALETTE.background
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	center.add_child(box)

	box.add_child(_label("민초의, 민초를 위한, 민초에 의한", 72))
	box.add_child(_label("작은 마을의 소수파, 민초단에 입단하시겠습니까?", 36))
	box.add_child(_bar(GameState.mincho_percent))
	box.add_child(_label("현재 득표   민초 %.0f%%  :  반민초 %.0f%%" % [GameState.mincho_percent, 100.0 - GameState.mincho_percent], 36))

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	var start: Button = Button.new()
	start.text = "입단하기"
	start.custom_minimum_size = Vector2(300, 90)
	start.pressed.connect(Flow.go_hub)
	var board: Button = Button.new()
	board.text = "리더보드"
	board.custom_minimum_size = Vector2(300, 90)
	board.pressed.connect(Flow.go_leaderboard)
	buttons.add_child(start)
	buttons.add_child(board)
	box.add_child(buttons)


func _label(text: String, size: int) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	return l


# 득표 막대: 왼쪽 초록 = 민초, 오른쪽 갈색 = 반민초
func _bar(mincho_percent: float) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	var m: ColorRect = ColorRect.new()
	m.color = PALETTE.mincho
	m.custom_minimum_size = Vector2(BAR_W * mincho_percent / 100.0, BAR_H)
	var a: ColorRect = ColorRect.new()
	a.color = PALETTE.anti_mincho
	a.custom_minimum_size = Vector2(BAR_W * (100.0 - mincho_percent) / 100.0, BAR_H)
	row.add_child(m)
	row.add_child(a)
	return row
