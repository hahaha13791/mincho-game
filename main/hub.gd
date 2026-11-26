extends Control
## 작전본부실: 코르크 수사 보드. 미니게임 메모(자유 고정 배치)가 빨간 실로 가운데 '개표 당일' 카드와 이어져 있다.
## 배치는 hub/hub_layout.gd, 메모 겉모습은 hub/memo_card.gd. 아래쪽은 책상 자리(2단계에서 3D 책상·주인공).

const PALETTE: Palette = preload("res://common/style/palette.tres")
const LIST: MinigameList = preload("res://main/minigame_list.tres")
const PINS: Array[String] = ["danger", "accent", "ballot_box", "mincho"] # 팔레트 이름. 메모마다 돌려 쓴다
# 테스트용 채우기 프리셋(이름 -> 등급 목록). 목록은 순서대로 미니게임에 배정되고 모자라면 마지막 값을 쓴다
const FILL_PRESETS: Dictionary = {
	"전부 완전범죄": [Grade.Rank.PERFECT],
	"전부 미션성공": [Grade.Rank.SUCCESS],
	"미션성공 5 + 적발 1": [Grade.Rank.SUCCESS, Grade.Rank.SUCCESS, Grade.Rank.SUCCESS, Grade.Rank.SUCCESS, Grade.Rank.SUCCESS, Grade.Rank.CAUGHT],
	"완전범죄 4 + 적발 2": [Grade.Rank.PERFECT, Grade.Rank.PERFECT, Grade.Rank.PERFECT, Grade.Rank.PERFECT, Grade.Rank.CAUGHT, Grade.Rank.CAUGHT],
	"전부 적발": [Grade.Rank.CAUGHT],
	"무작위": [],
}

var _memos: Dictionary = {} # id -> MemoCard
var _decor: Array[MemoCard] = []
var _center: MemoCard
var _strings: Control


func _ready() -> void:
	var wall: ColorRect = ColorRect.new()
	wall.color = PALETTE.background.darkened(0.12)
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(wall)
	_build_board()
	_build_desk_placeholder()
	_build_tools()


func _process(_delta: float) -> void:
	_strings.queue_redraw() # 메모가 들릴 때 실이 따라간다


# --- 보드 ---

func _build_board() -> void:
	var frame: Panel = _panel(HubLayout.BOARD, PALETTE.wood, 6)
	add_child(frame)
	var cork_rect: Rect2 = HubLayout.BOARD.grow(-HubLayout.CORK_MARGIN)
	add_child(_panel(cork_rect, PALETTE.cork, 0))
	var speck: Control = Control.new() # 코르크 알갱이
	speck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speck.set_anchors_preset(Control.PRESET_FULL_RECT)
	speck.draw.connect(func() -> void:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 7
		for i in 900:
			var p: Vector2 = cork_rect.position + Vector2(rng.randf() * cork_rect.size.x, rng.randf() * cork_rect.size.y)
			speck.draw_circle(p, rng.randf_range(1.0, 3.0), PALETTE.cork.darkened(rng.randf_range(0.08, 0.2))))
	add_child(speck)

	for i in HubLayout.DECOR.size():
		_decor.append(_make_decor(HubLayout.DECOR[i], i))

	var done: int = GameState.grades.size()
	var c: Dictionary = HubLayout.CENTER
	_center = _card(c["pos"], c["size"], c["tilt"], PALETTE.paper, PALETTE.danger)
	_center.add_picture(PALETTE.ballot_box, 130.0)
	_center.add_line("개표 당일", 1.15)
	_center.add_line("작전 %d / %d" % [done, GameState.MINIGAME_COUNT], 0.85)
	if done >= GameState.MINIGAME_COUNT:
		_center.set_stamp("개표 개시!", PALETTE.danger)
		_center.make_clickable()
		_center.pressed.connect(Flow.go_final)

	var n: int = 0
	for entry in LIST.entries:
		var lay: Variant = HubLayout.MEMOS.get(entry.id)
		if lay == null:
			continue # 배치가 없는 미니게임은 보드에 붙이지 않는다
		var pin: Color = PALETTE.get(PINS[n % PINS.size()])
		n += 1
		var memo: MemoCard = _card(lay["pos"], HubLayout.MEMO_SIZE, lay["tilt"], PALETTE.memo, pin)
		memo.add_line(entry.display_name)
		if GameState.is_done(entry.id):
			var rank: Grade.Rank = GameState.grades[entry.id]
			memo.set_stamp(Grade.NAMES[rank], _rank_color(rank))
		else:
			memo.make_clickable()
			memo.pressed.connect(Flow.start.bind(entry))
		_memos[entry.id] = memo

	_strings = Control.new() # 빨간 실과 핀 머리. 메모 위에 그린다
	_strings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strings.set_anchors_preset(Control.PRESET_FULL_RECT)
	_strings.draw.connect(_draw_strings)
	add_child(_strings)


func _make_decor(d: Dictionary, i: int) -> MemoCard:
	var kind: String = d["kind"]
	var paper: Color = PALETTE.memo if kind == "note" else PALETTE.paper
	var card: MemoCard = _card(d["pos"], d["size"], d["tilt"], paper, PALETTE.get(PINS[(i + 1) % PINS.size()]))
	match kind:
		"title":
			card.add_line(d["text"], 1.25)
		"news":
			card.add_line("마을 일보", 1.0)
			card.add_line("민초 %.1f%% vs 반민초 %.1f%%" % [GameState.mincho_percent, 100.0 - GameState.mincho_percent], 0.85)
		"photo":
			card.add_picture(PALETTE.road, d["size"].y - 80.0)
			card.add_line(d["text"], 0.75)
		"map":
			card.add_picture(PALETTE.water.lightened(0.45), d["size"].y - 70.0)
			card.add_line(d["text"], 0.75)
		_:
			card.add_line(d["text"], 0.9)
	return card


func _card(pos: Vector2, size_px: Vector2, tilt: float, paper: Color, pin: Color) -> MemoCard:
	var card: MemoCard = MemoCard.new()
	add_child(card)
	card.setup(pos, size_px, tilt, paper, pin)
	return card


func _draw_strings() -> void:
	var center_pin: Vector2 = _center.pin_in_parent()
	for id in _memos:
		_rope(_memos[id].pin_in_parent(), center_pin)
	for pair in HubLayout.EXTRA_STRINGS:
		var a: MemoCard = _decor[pair[0]]
		var b: MemoCard = _memos.get(pair[1])
		if b != null:
			_rope(a.pin_in_parent(), b.pin_in_parent())
	# 실이 핀에 감겨 보이도록 핀 머리를 실 위에 다시 그린다
	var cards: Array[MemoCard] = [_center]
	cards.append_array(_decor)
	for m in _memos.values():
		cards.append(m)
	for card in cards:
		var p: Vector2 = card.pin_in_parent()
		_strings.draw_circle(p + Vector2(2, 3), MemoCard.PIN_R, Color(0, 0, 0, 0.3))
		_strings.draw_circle(p, MemoCard.PIN_R, card.pin_color)
		_strings.draw_circle(p + Vector2(-3, -3), MemoCard.PIN_R * 0.35, card.pin_color.lightened(0.5))


# 살짝 처진 실(2차 베지어)과 그림자
func _rope(a: Vector2, b: Vector2) -> void:
	var ctrl: Vector2 = (a + b) / 2.0 + Vector2(0, a.distance_to(b) * 0.08)
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 17:
		var t: float = i / 16.0
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	var shadow: PackedVector2Array = PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(3, 5))
	_strings.draw_polyline(shadow, Color(0, 0, 0, 0.22), 3.0, true)
	_strings.draw_polyline(pts, PALETTE.yarn, 3.0, true)


func _rank_color(rank: Grade.Rank) -> Color:
	match rank:
		Grade.Rank.PERFECT:
			return PALETTE.mincho.darkened(0.35)
		Grade.Rank.SUCCESS:
			return PALETTE.ballot_box.darkened(0.2)
	return PALETTE.danger


func _panel(rect: Rect2, color: Color, shadow: int) -> Panel:
	var p: Panel = Panel.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0, shadow)
	p.add_theme_stylebox_override("panel", style)
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


# --- 책상 자리 ---

# shortcut: 2단계(3D 책상·주인공) 전까지 나무판과 리더보드 버튼만 둔다
func _build_desk_placeholder() -> void:
	var top: float = HubLayout.BOARD.end.y + 20.0
	add_child(_panel(Rect2(0, top, 1920, 1080 - top), PALETTE.wood.lightened(0.15), 8))
	var board: Button = Button.new()
	board.text = "리더보드"
	board.position = Vector2(60, top + 60)
	board.pressed.connect(Flow.go_leaderboard)
	add_child(board)


# shortcut: 테스트용 버튼들. 전시 전에 숨긴다
func _build_tools() -> void:
	var tools: HBoxContainer = HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)
	tools.position = Vector2(1000, 1010)
	tools.modulate.a = 0.6
	add_child(tools)
	var reset: Button = Button.new()
	reset.text = "처음부터 (테스트)"
	reset.pressed.connect(func() -> void:
		GameState.reset()
		get_tree().reload_current_scene())
	tools.add_child(reset)
	var preset: OptionButton = OptionButton.new()
	for p in FILL_PRESETS:
		preset.add_item(p)
	tools.add_child(preset)
	var fill: Button = Button.new()
	fill.text = "전부 완료 (테스트)"
	fill.pressed.connect(func() -> void:
		_fill_all(preset.selected)
		get_tree().reload_current_scene())
	tools.add_child(fill)


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
