extends Control
## 리더보드 화면. 상위 10명과 방금 등록한 항목(10위 밖이면 아래에 따로)을 보여준다. 임시 버전: 모양은 디자인 단계에서 만든다.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const TOP: int = 10


func _ready() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = PALETTE.background
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var heading: Label = Label.new()
	heading.text = "리더보드"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 56)
	box.add_child(heading)

	var sorted: Array[Dictionary] = Leaderboard.sorted_entries(Leaderboard.load_all())
	if sorted.is_empty():
		box.add_child(_row_label("아직 기록이 없습니다.", false))
	for i in mini(TOP, sorted.size()):
		box.add_child(_row(i + 1, sorted[i]))
	var mine: int = Leaderboard.rank_of(sorted, Leaderboard.highlight_id)
	if mine > TOP:
		box.add_child(_row_label("…", false))
		box.add_child(_row(mine, sorted[mine - 1]))

	var back: Button = Button.new()
	back.text = "작전본부실로"
	back.pressed.connect(func() -> void:
		Leaderboard.highlight_id = -1
		Flow.go_hub())
	box.add_child(back)


func _row(rank: int, e: Dictionary) -> Label:
	var mine: bool = int(e["id"]) == Leaderboard.highlight_id
	var text: String = "%s%2d위   %s   %d점   %s   %s" % ["★ " if mine else "   ", rank, e["name"], int(e["score"]), e["title"], Leaderboard.glyphs(e["ranks"])]
	return _row_label(text, mine)


func _row_label(text: String, highlight: bool) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 32)
	if highlight:
		l.add_theme_color_override("font_color", PALETTE.danger)
	return l
