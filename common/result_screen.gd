class_name ResultScreen
extends CanvasLayer
## 공통 결과 화면. 등급 + 득표 변화를 보여 주고 선택 화면으로 돌려보낸다.


## 미니게임이 끝났을 때 host(미니게임 루트)에 붙여 띄운다. GameState.submit_result()를 먼저 호출해야 득표가 반영된다.
static func open(host: Node, rank: Grade.Rank, message: String, before_percent: float) -> void:
	var screen: ResultScreen = ResultScreen.new()
	screen.layer = 10
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	center.add_child(box)
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(900, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "%s\n%s\n민초 %.1f%% → %.1f%%" % [Grade.NAMES[rank], message, before_percent, GameState.mincho_percent]
	box.add_child(label)
	var button: Button = Button.new()
	button.text = "작전본부실로"
	button.pressed.connect(Flow.go_hub)
	box.add_child(button)
	host.add_child(screen)
