class_name MemoCard
extends Control
## 수사 보드에 핀으로 꽂힌 메모지(또는 사진·스크랩). 누를 수 있으면 마우스를 올릴 때 들리고 똑바로 펴진다.

signal pressed

const PALETTE: Palette = preload("res://common/style/palette.tres")
const PIN_R: float = 11.0

var clickable: bool = false
var pin_color: Color
var _tilt: float = 0.0
var _lines: VBoxContainer
var _tween: Tween


## pos = 보드 위 중심 좌표, tilt = 기울기(도)
func setup(pos: Vector2, size_px: Vector2, tilt: float, paper: Color, pin: Color) -> void:
	size = size_px
	position = pos - size_px / 2.0
	pivot_offset = size_px / 2.0
	rotation_degrees = tilt
	_tilt = tilt
	pin_color = pin
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg: Panel = Panel.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = paper
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 6
	style.shadow_offset = Vector2(4, 7)
	bg.add_theme_stylebox_override("panel", style)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_lines = VBoxContainer.new()
	_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lines.offset_left = 16
	_lines.offset_right = -16
	_lines.offset_top = 26
	_lines.offset_bottom = -12
	_lines.alignment = BoxContainer.ALIGNMENT_CENTER
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lines)

	var head: Panel = Panel.new() # 핀 머리
	var pin_style: StyleBoxFlat = StyleBoxFlat.new()
	pin_style.bg_color = pin
	pin_style.set_corner_radius_all(int(PIN_R))
	pin_style.shadow_color = Color(0, 0, 0, 0.35)
	pin_style.shadow_size = 3
	pin_style.shadow_offset = Vector2(2, 3)
	head.add_theme_stylebox_override("panel", pin_style)
	head.size = Vector2(PIN_R, PIN_R) * 2.0
	head.position = pin_local() - Vector2(PIN_R, PIN_R)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)


## 사진(폴라로이드) 칸: 위쪽에 색 사각형을 넣고 글은 아래로 내린다
func add_picture(color: Color, height: float) -> void:
	var pic: ColorRect = ColorRect.new()
	pic.color = color
	pic.position = Vector2(14, 30)
	pic.size = Vector2(size.x - 28, height)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pic)
	move_child(pic, 1) # 글보다 아래
	_lines.offset_top = 30 + height
	_lines.alignment = BoxContainer.ALIGNMENT_BEGIN


## 손글씨 한 줄. 크기 배율을 줄 수 있다
func add_line(text: String, scale_font: float = 1.0) -> Label:
	var l: Label = Label.new()
	l.theme_type_variation = &"HandLabel"
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 배율은 트리 밖에서 읽는 기본 글자 크기(28) 기준이다. 보드 장식 크기가 이 기준으로 맞춰져 있다
	var scaled: int = int(l.get_theme_font_size("font_size") * scale_font)
	_lines.add_child(l) # 손글씨 글꼴·크기를 읽으려면 트리에 먼저 넣는다
	_fit(l, scaled if scale_font != 1.0 else l.get_theme_font_size("font_size"))
	return l


# 메모 밖으로 글자가 나가지 않게 맞춘다. 자동 줄바꿈은 한글을 음절 중간("사라지/다")에서 끊어서 쓰지 않고,
# 넘치면 가운데에 가장 가까운 띄어쓰기에서 한 번 끊고, 그래도 넘치는 줄이 있으면 글자를 줄인다
func _fit(l: Label, font_size: int) -> void:
	var width: float = size.x + _lines.offset_right - _lines.offset_left
	var font: Font = l.get_theme_font("font")
	var text: String = l.text
	if not text.contains("\n") and _line_width(font, text, font_size) > width:
		var best: int = -1
		for i in text.length():
			if text[i] == " " and (best < 0 or absi(i - text.length() / 2) < absi(best - text.length() / 2)):
				best = i
		if best >= 0:
			text = text.substr(0, best) + "\n" + text.substr(best + 1)
	l.text = text
	var widest: float = 0.0
	for line in text.split("\n"):
		widest = maxf(widest, _line_width(font, line, font_size))
	if widest > width:
		font_size = int(font_size * width / widest)
	l.add_theme_font_size_override("font_size", font_size)


func _line_width(font: Font, line: String, font_size: int) -> float:
	return font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


## 메모 위에 비스듬히 찍힌 도장(등급 등)
func set_stamp(text: String, color: Color) -> void:
	var s: Label = Label.new()
	s.text = text
	s.add_theme_color_override("font_color", color)
	s.add_theme_font_size_override("font_size", 38)
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = color
	box.set_border_width_all(4)
	box.set_corner_radius_all(6)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	s.add_theme_stylebox_override("normal", box)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(s)
	s.reset_size()
	s.pivot_offset = s.size / 2.0
	# 글은 위쪽으로 올리고 도장은 아래쪽에 찍어 서로 가리지 않게
	_lines.offset_bottom = -s.size.y - 30.0
	s.position = Vector2(size.x / 2.0 - s.size.x / 2.0, size.y - s.size.y - 22.0)
	s.rotation_degrees = -9.0
	s.modulate.a = 0.85


## 누를 수 있게 한다. 마우스를 올리면 살짝 커지며 똑바로 펴진다
func make_clickable() -> void:
	clickable = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_lift.bind(true))
	mouse_exited.connect(_lift.bind(false))
	gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			pressed.emit())


func pin_local() -> Vector2:
	return Vector2(size.x / 2.0, 14.0)


## 핀 위치(부모 좌표계). 회전·확대를 반영한다
func pin_in_parent() -> Vector2:
	return get_transform() * pin_local()


func _lift(on: bool) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE * (1.08 if on else 1.0), 0.15)
	_tween.tween_property(self, "rotation_degrees", 0.0 if on else _tilt, 0.15)
	z_index = 1 if on else 0
