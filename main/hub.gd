extends Control
## 미니게임 선택 화면(작전본부실). 임시 버전: 모양은 미니게임이 다 모인 뒤에 만든다.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const LIST: MinigameList = preload("res://main/minigame_list.tres")
const CENTER_INDEX: int = 4
const CARD_SIZE: Vector2 = Vector2(420, 180)
# 테스트용 채우기 프리셋(이름 -> 등급 목록). 목록은 순서대로 미니게임에 배정되고 모자라면 마지막 값을 쓴다
const FILL_PRESETS: Dictionary = {
	"전부 완전범죄": [Grade.Rank.PERFECT],
	"전부 미션성공": [Grade.Rank.SUCCESS],
	"미션성공 6 + 적발 1": [Grade.Rank.SUCCESS, Grade.Rank.SUCCESS, Grade.Rank.SUCCESS, Grade.Rank.SUCCESS, Grade.Rank.SUCCESS, Grade.Rank.SUCCESS, Grade.Rank.CAUGHT],
	"완전범죄 5 + 적발 2": [Grade.Rank.PERFECT, Grade.Rank.PERFECT, Grade.Rank.PERFECT, Grade.Rank.PERFECT, Grade.Rank.PERFECT, Grade.Rank.CAUGHT, Grade.Rank.CAUGHT],
	"전부 적발": [Grade.Rank.CAUGHT],
	"무작위": [],
}


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

	# shortcut: 테스트용 버튼들. 타이틀과 리더보드가 생기면 제거
	var tools: HBoxContainer = HBoxContainer.new()
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 16)
	box.add_child(tools)
	var reset: Button = Button.new()
	reset.text = "처음부터 (테스트용)"
	reset.pressed.connect(func() -> void:
		GameState.reset()
		get_tree().reload_current_scene())
	tools.add_child(reset)
	var preset: OptionButton = OptionButton.new()
	for p in FILL_PRESETS:
		preset.add_item(p)
	tools.add_child(preset)
	var fill: Button = Button.new()
	fill.text = "7개 모두 완료 (테스트용)"
	fill.pressed.connect(func() -> void:
		_fill_all(preset.selected)
		get_tree().reload_current_scene())
	tools.add_child(fill)


func _card(entry: MinigameEntry) -> Button:
	var b: Button = Button.new()
	b.custom_minimum_size = CARD_SIZE
	if entry == null:
		b.text = "(준비 중)"
		b.disabled = true
	elif GameState.is_done(entry.id):
		b.text = "%s\n[%s]" % [entry.display_name, Grade.NAMES[GameState.grades[entry.id]]]
		b.disabled = true
	elif entry.scene.is_empty():
		b.text = "%s\n(준비 중)" % entry.display_name
		b.disabled = true
	else:
		b.text = entry.display_name
		b.pressed.connect(Flow.start.bind(entry))
	return b


func _final_card(done: int) -> Button:
	var b: Button = Button.new()
	b.custom_minimum_size = CARD_SIZE
	if done >= GameState.MINIGAME_COUNT:
		b.text = "개표 당일\n개표를 시작한다"
		b.pressed.connect(Flow.go_final)
	else:
		b.text = "개표 당일\n작전 %d개를 모두 끝내면 열린다" % GameState.MINIGAME_COUNT
		b.disabled = true
	return b


# shortcut: 테스트용. 득표와 등급을 초기화한 뒤 씬이 있는 미니게임을 프리셋대로 채운다
func _fill_all(preset: int) -> void:
	GameState.reset()
	var ranks: Array = FILL_PRESETS.values()[preset]
	var i: int = 0
	for entry in LIST.entries:
		if entry.scene.is_empty():
			continue
		var rank: Grade.Rank = Grade.Rank.values().pick_random() if ranks.is_empty() else ranks[mini(i, ranks.size() - 1)]
		GameState.submit_result(entry.id, rank)
		i += 1
