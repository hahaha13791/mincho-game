extends Control
## 미니게임 선택 화면(작전본부실). 임시 버전: 모양은 미니게임이 다 모인 뒤에 만든다.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const LIST: MinigameList = preload("res://main/minigame_list.tres")
const CENTER_INDEX: int = 4
const CARD_SIZE: Vector2 = Vector2(420, 180)


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

	var done: int = GameState.grades.size()
	var status: Label = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.text = "작전본부실   민초 %.1f%%   작전 %d / %d" % [GameState.mincho_percent, done, GameState.MINIGAME_COUNT]
	box.add_child(status)

	# 3x3: 가운데(4번째 칸)는 개표 당일, 나머지 8칸이 미니게임. 8칸에 못 미치면 빈 칸은 '준비 중'
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	box.add_child(grid)
	for i in 9:
		if i == CENTER_INDEX:
			grid.add_child(_final_card(done))
			continue
		var slot: int = i if i < CENTER_INDEX else i - 1
		grid.add_child(_card(LIST.entries[slot] if slot < LIST.entries.size() else null))

	# shortcut: 테스트용 초기화 버튼, 최종 개표/타이틀이 생기면 제거
	var reset: Button = Button.new()
	reset.text = "처음부터 (테스트용)"
	reset.pressed.connect(func() -> void:
		GameState.reset()
		get_tree().reload_current_scene())
	box.add_child(reset)


func _card(entry: MinigameEntry) -> Button:
	var b: Button = Button.new()
	b.custom_minimum_size = CARD_SIZE
	if entry == null:
		b.text = "(준비 중)"
		b.disabled = true
	elif GameState.is_done(entry.id):
		b.text = "%s
[%s]" % [entry.display_name, Grade.NAMES[GameState.grades[entry.id]]]
		b.disabled = true
	elif entry.scene.is_empty():
		b.text = "%s
(준비 중)" % entry.display_name
		b.disabled = true
	else:
		b.text = entry.display_name
		b.pressed.connect(Flow.start.bind(entry))
	return b


# shortcut: 개표 당일 화면이 아직 없어 열려도 누를 수 없다. 최종 개표를 만들 때 pressed에 연결
func _final_card(done: int) -> Button:
	var b: Button = Button.new()
	b.custom_minimum_size = CARD_SIZE
	b.disabled = true
	if done >= GameState.MINIGAME_COUNT:
		b.text = "개표 당일
(준비 중)"
	else:
		b.text = "개표 당일
작전 %d개를 모두 끝내면 열린다" % GameState.MINIGAME_COUNT
	return b
