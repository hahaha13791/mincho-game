class_name ResultScreen
extends CanvasLayer
## 공통 결과 화면. 등급 + 득표 변화를 보여 주고 선택 화면으로 돌려보낸다.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const WIDTH: float = 900.0
const FOCUS_DELAY: float = 0.8


## 미니게임이 끝났을 때 host(미니게임 루트)에 붙여 띄운다. GameState.submit_result()를 먼저 호출해야 득표가 반영된다.
static func open(host: Node, rank: Grade.Rank, message: String, before_percent: float) -> void:
	var screen: ResultScreen = ResultScreen.new()
	screen.layer = 10
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72) # 튜토리얼과 같게. 0.5면 밝은 글씨가 회색 위에서 흐리다
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	center.add_child(box)
	var grade: Label = _label(Grade.NAMES[rank], 96)
	grade.theme_type_variation = &"HandLabel"
	box.add_child(grade)
	var label: Label = _label("%s\n민초 %.1f%% → %.1f%%" % [message, before_percent, GameState.mincho_percent], 34)
	box.add_child(label)
	var button: Button = Button.new()
	button.text = "작전본부실로"
	button.custom_minimum_size = Vector2(300, 80)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(Flow.go_hub)
	box.add_child(button)
	host.add_child(screen)
	Tutorial.wrap_words(label, WIDTH)
	# Space·Enter로도 누른다. 바로 잡으면 게임 중 연타하던 Space에 결과를 못 보고 넘어가서 조금 뒤에
	screen.get_tree().create_timer(FOCUS_DELAY).timeout.connect(button.grab_focus)


static func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(WIDTH, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", PALETTE.paper) # 기본 글씨색(진한 잉크)은 어두운 배경에 묻힌다
	return label
