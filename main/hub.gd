extends Control
## 미니게임 선택 화면(작전본부실). 임시 버전: 모양은 미니게임이 다 모인 뒤에 만든다.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const LIST: MinigameList = preload("res://main/minigame_list.tres")


func _ready() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = PALETTE.background
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var status: Label = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.text = "작전본부실   민초 %.1f%%" % GameState.mincho_percent
	if GameState.grades.size() >= GameState.MINIGAME_COUNT:
		status.text += "\n모든 작전 완료! (최종 개표는 아직 없음)"
	box.add_child(status)

	for entry in LIST.entries:
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2(600, 0)
		if GameState.is_done(entry.id):
			b.text = "%s  [%s]" % [entry.display_name, Grade.NAMES[GameState.grades[entry.id]]]
			b.disabled = true
		elif entry.scene.is_empty():
			b.text = "%s  (준비 중)" % entry.display_name
			b.disabled = true
		else:
			b.text = entry.display_name
			b.pressed.connect(Flow.start.bind(entry))
		box.add_child(b)

	# shortcut: 테스트용 초기화 버튼, 최종 개표/타이틀이 생기면 제거
	var reset: Button = Button.new()
	reset.text = "처음부터 (테스트용)"
	reset.pressed.connect(func() -> void:
		GameState.reset()
		get_tree().reload_current_scene())
	box.add_child(reset)
