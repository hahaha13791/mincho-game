extends Control
## 최종 개표(개표 당일). 득표 막대가 올라가는 연출 뒤에 승패, 칭호, 종합점수, 미니게임별 등급을 차례로 보여준다.
## 리더보드는 아직 없다. 임시 버전: 모양은 디자인 단계에서 만든다.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const LIST: MinigameList = preload("res://main/minigame_list.tres")
const BAR_W: float = 1200.0
const BAR_H: float = 80.0
const COUNT_TIME: float = 3.5
const SPECIAL_TEXT: String = "추가 개표: 민초 표가 투표자 수보다 많이 나왔다.\n개표원은 말없이 계산기를 내려놓았다."

var _mincho_bar: ColorRect
var _anti_bar: ColorRect
var _percent: Label
var _reveal: Array[Control] = []


func _ready() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = PALETTE.background
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	var heading: Label = _label("개표 당일", 56)
	box.add_child(heading)
	box.add_child(_build_bar())
	_percent = _label("", 40)
	box.add_child(_percent)

	var ranks: Array = GameState.grades.values()
	var percent: float = GameState.mincho_percent
	var win: bool = FinalRules.is_win(percent)
	box.add_child(_hidden(_label("민초 승리!" if win else "반민초 승리...", 48)))
	box.add_child(_hidden(_label("칭호: %s" % FinalRules.title(ranks, percent), 44)))
	box.add_child(_hidden(_label("종합점수 %d점" % GameState.total_score(), 36)))
	box.add_child(_hidden(_label(_detail(), 28)))
	if FinalRules.is_special(ranks):
		box.add_child(_hidden(_label(SPECIAL_TEXT, 36)))
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	var register: Button = Button.new()
	register.text = "리더보드에 등록"
	register.pressed.connect(func() -> void:
		register.disabled = true # 연타로 두 번 등록되지 않게
		_register(ranks, percent))
	var again: Button = Button.new()
	again.text = "등록하지 않고 처음부터"
	again.pressed.connect(func() -> void:
		GameState.reset()
		Flow.go_title())
	buttons.add_child(register)
	buttons.add_child(again)
	box.add_child(_hidden(buttons))

	await _play(GameState.config.start_mincho_percent, percent)


# 개표 연출: 막대를 시작 득표에서 최종 득표까지 올린 뒤 결과를 하나씩 드러낸다
func _play(from_percent: float, to_percent: float) -> void:
	_show_percent(from_percent)
	var tween: Tween = create_tween()
	tween.tween_method(_show_percent, from_percent, to_percent, COUNT_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	for c in _reveal:
		await get_tree().create_timer(0.7).timeout
		c.show()


# 리더보드에 등록하고 새 방문자를 위해 득표와 등급을 초기화한다
func _register(ranks: Array, percent: float) -> void:
	var entries: Array[Dictionary] = Leaderboard.load_all()
	var entry: Dictionary = Leaderboard.add(entries, GameState.total_score(), percent, FinalRules.title(ranks, percent), ranks, int(Time.get_unix_time_from_system()))
	if not Leaderboard.save(entries):
		push_error("리더보드를 저장하지 못했다: " + Leaderboard.PATH)
	Leaderboard.highlight_id = entry["id"]
	GameState.reset()
	Flow.go_leaderboard()


func _show_percent(p: float) -> void:
	_mincho_bar.size.x = BAR_W * p / 100.0
	_anti_bar.position.x = _mincho_bar.size.x
	_anti_bar.size.x = BAR_W - _mincho_bar.size.x
	_percent.text = "민초 %.1f%%  :  반민초 %.1f%%" % [p, 100.0 - p]


func _detail() -> String:
	var lines: PackedStringArray = []
	for entry in LIST.entries:
		if GameState.is_done(entry.id):
			lines.append("%s  [%s]" % [entry.display_name, Grade.NAMES[GameState.grades[entry.id]]])
	return "\n".join(lines)


# --- 화면 ---

func _label(text: String, size: int) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	return l


func _hidden(c: Control) -> Control:
	c.hide()
	_reveal.append(c)
	return c


# 막대 한가운데에 50% 선을 그어 승패 기준을 보여준다
func _build_bar() -> Control:
	var holder: Control = Control.new()
	holder.custom_minimum_size = Vector2(BAR_W, BAR_H)
	_mincho_bar = ColorRect.new()
	_mincho_bar.color = PALETTE.mincho
	_mincho_bar.size = Vector2(0.0, BAR_H)
	_anti_bar = ColorRect.new()
	_anti_bar.color = PALETTE.anti_mincho
	_anti_bar.size = Vector2(BAR_W, BAR_H)
	var line: ColorRect = ColorRect.new()
	line.color = PALETTE.accent
	line.position = Vector2(BAR_W / 2.0 - 3.0, -10.0)
	line.size = Vector2(6.0, BAR_H + 20.0)
	for n in [_mincho_bar, _anti_bar, line]:
		holder.add_child(n)
	return holder
