extends Node
## 다그닥-바와스(id: tally_board). 칠판의 숫자 몇 칸을 고쳐 민초 득표를 올린다. 참관인이 반별 합, 전체 합, 투표자 수를 검산한다.
## 숫자 위주의 2D 화면이라 3D 장면 없이 HUD만 쓴다.

enum State { TUTORIAL, PLAYING, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: TallyConfig = preload("res://minigames/tally_board/tally_config.tres")
const TUTORIAL_TEXT: String = "칠판의 숫자를 몰래 고쳐 민초 득표를 올리세요. 칸마다 [−] [+]로 고칩니다.\n고칠 수 있는 칸은 %d칸뿐이고, 한 칸에서 바꿀 수 있는 폭은 원래 값의 ±%d%%까지입니다. 넘으면 필체가 달라 들킵니다.\n참관인이 검산합니다: ① 반별 합(민초+반민초=반 합계) ② 전체 합(반별 합이 맨 아랫줄과 같다) ③ 투표자 수(맨 아랫줄 합이 투표자 수와 같다)\n민초를 올리면 같은 반의 반민초를 내리고, 맨 아랫줄도 맞춰 고치세요."

@export var id: StringName = &"tally_board"

var _state: State = State.TUTORIAL
var _t_left: float = 0.0
var _s: Array[int] = [] # 반별 합(고정)
var _v: int # 투표자 수(고정)
var _orig: Dictionary = {} # 칸 id -> 원래 값
var _val: Dictionary = {} # 칸 id -> 현재 값
var _labels: Dictionary = {} # 칸 id -> Label
var _best: int
var _action: Callable

@onready var _board: GridContainer = $HUD/Board
@onready var _overlay: Control = $HUD/Overlay
@onready var _message: Label = $HUD/Overlay/Center/Box/Message
@onready var _action_button: Button = $HUD/Overlay/Center/Box/Action
@onready var _hint: Label = $HUD/HintLabel


func _ready() -> void:
	$HUD/Bg.color = PALETTE.background
	$HUD/SubmitButton.pressed.connect(_submit)
	_action_button.pressed.connect(func() -> void: _action.call())
	_show_overlay(TUTORIAL_TEXT % [CONFIG.cell_budget, roundi(CONFIG.cap_ratio * 100.0)], "시작", _start)


func _start() -> void:
	_overlay.hide()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var b: Dictionary = TallyRules.make_board(CONFIG, rng)
	var m: Array[int] = b["m"]
	var a: Array[int] = b["a"]
	_best = TallyRules.best_gain(m, a, CONFIG.cap_ratio, CONFIG.cell_budget)
	var tm: int = 0
	var ta: int = 0
	for i in CONFIG.classes:
		_s.append(m[i] + a[i])
		_set_cell(StringName("m%d" % i), m[i])
		_set_cell(StringName("a%d" % i), a[i])
		tm += m[i]
		ta += a[i]
	_set_cell(&"tm", tm)
	_set_cell(&"ta", ta)
	_v = tm + ta
	_build_board()
	_t_left = CONFIG.time_limit
	_state = State.PLAYING
	_refresh()


func _process(delta: float) -> void:
	if _state != State.PLAYING:
		return
	_t_left -= delta
	$HUD/TimerLabel.text = "%.1f" % maxf(_t_left, 0.0)
	if _t_left <= 0.0:
		_submit()


func _set_cell(cell: StringName, value: int) -> void:
	_orig[cell] = value
	_val[cell] = value


func _changed_count() -> int:
	var n: int = 0
	for c in _val:
		if _val[c] != _orig[c]:
			n += 1
	return n


func _step(cell: StringName, delta: int) -> void:
	if _state != State.PLAYING:
		return
	var nv: int = _val[cell] + delta
	var cap: int = TallyRules.cap(_orig[cell], CONFIG.cap_ratio)
	if nv < 0:
		return
	if absi(nv - _orig[cell]) > cap:
		_hint.text = "필체가 달라진다! 이 칸은 ±%d까지만." % cap
		return
	if _val[cell] == _orig[cell] and _changed_count() >= CONFIG.cell_budget:
		_hint.text = "고칠 수 있는 칸은 %d칸뿐이다." % CONFIG.cell_budget
		return
	_val[cell] = nv
	_hint.text = ""
	_refresh()


func _submit() -> void:
	if _state != State.PLAYING:
		return
	_state = State.ENDED
	var m: Array[int] = []
	var a: Array[int] = []
	for i in CONFIG.classes:
		m.append(_val[StringName("m%d" % i)])
		a.append(_val[StringName("a%d" % i)])
	var failure: TallyRules.Failure = TallyRules.check(_s, _v, m, a, _val[&"tm"], _val[&"ta"])
	var gain: int = _val[&"tm"] - _orig[&"tm"]
	var rank: Grade.Rank = TallyRules.judge(failure, gain, _best, CONFIG.perfect_ratio, CONFIG.success_ratio)
	var msg: String
	match failure:
		TallyRules.Failure.ROW:
			msg = "참관인: \"어? 이 반은 민초랑 반민초를 더해도 합계가 안 맞는데요?\""
		TallyRules.Failure.TOTAL:
			msg = "참관인: \"반별로 더한 값이 맨 아랫줄이랑 다른데요?\""
		TallyRules.Failure.VOTERS:
			msg = "참관인: \"투표한 사람 수와 칠판 합계가 다릅니다.\""
		_:
			match rank:
				Grade.Rank.PERFECT:
					msg = "참관인은 계산기를 두드리고 고개를 끄덕였다. 민초 +%d표. 칠판은 원래부터 이랬다." % gain
				Grade.Rank.SUCCESS:
					msg = "검산은 통과했다. 민초 +%d표. 아쉽게도 더 올릴 수 있었다." % gain
				_:
					msg = "검산은 통과했지만 민초 +%d표뿐이다. 이래서는 고친 보람이 없다." % gain
	var before: float = GameState.mincho_percent
	GameState.submit_result(id, rank)
	ResultScreen.open(self, rank, msg, before)


func _refresh() -> void:
	for c in _labels:
		var diff: int = _val[c] - _orig[c]
		_labels[c].text = "%d" % _val[c] if diff == 0 else "%d (%+d)" % [_val[c], diff]
		_labels[c].add_theme_color_override("font_color", PALETTE.danger if diff != 0 else PALETTE.anti_mincho.darkened(0.5))
	$HUD/BudgetLabel.text = "고친 칸 %d / %d" % [_changed_count(), CONFIG.cell_budget]
	$HUD/TimerLabel.text = "%.1f" % maxf(_t_left, 0.0)


func _show_overlay(text: String, button_text: String, action: Callable) -> void:
	_message.text = text
	_action_button.text = button_text
	_action = action
	_overlay.show()


# --- 화면 ---

func _text(t: String) -> Label:
	var l: Label = Label.new()
	l.text = t
	l.add_theme_color_override("font_color", PALETTE.anti_mincho.darkened(0.5))
	l.add_theme_font_size_override("font_size", 32)
	return l


func _cell_widget(cell: StringName) -> HBoxContainer:
	var box: HBoxContainer = HBoxContainer.new()
	var minus: Button = Button.new()
	minus.text = "−"
	minus.pressed.connect(_step.bind(cell, -1))
	var value: Label = _text("")
	value.custom_minimum_size = Vector2(180, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_labels[cell] = value
	var plus: Button = Button.new()
	plus.text = "+"
	plus.pressed.connect(_step.bind(cell, 1))
	for n in [minus, value, plus]:
		box.add_child(n)
	return box


# 겉모습(배치·색)은 이 함수에만 모아 두어 스타일 확정 때 한 곳에서 교체한다
func _build_board() -> void:
	for h in ["", "민초", "반민초", "반 합계"]:
		_board.add_child(_text(h))
	for i in CONFIG.classes:
		_board.add_child(_text("%d반" % (i + 1)))
		_board.add_child(_cell_widget(StringName("m%d" % i)))
		_board.add_child(_cell_widget(StringName("a%d" % i)))
		_board.add_child(_text("%d" % _s[i]))
	_board.add_child(_text("합계"))
	_board.add_child(_cell_widget(&"tm"))
	_board.add_child(_cell_widget(&"ta"))
	_board.add_child(_text("투표자 %d명" % _v))
