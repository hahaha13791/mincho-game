extends Control
## 타이틀: 어두운 아지트에 핀 대신 민초 아이스크림이 꽂힌 '민초단 입단 원서' 한 장. 네 귀퉁이에는 복장이 다른 주인공 넷이
## 원서 쪽을 비스듬히 보며 저마다 작전 중이다. [입단하기]를 누르면 원서에 초록 '입단' 도장이 찍히고 작전본부실로 간다.
## 아지트 조명은 작전본부실 덮개(hub/hub_light.gdshader)를 스탠드 없이 원서 위 조명만 켜서 쓴다.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const PROTAGONIST: PackedScene = preload("res://common/protagonist.tscn")
const LIGHT_SHADER: Shader = preload("res://main/hub/hub_light.gdshader")
const FORM_SIZE: Vector2 = Vector2(900, 860)
const FORM_CENTER: Vector2 = Vector2(960, 590)
const FORM_TILT: float = -0.02
const INK: Color = Color(0.17, 0.15, 0.14) # 손글씨 기본색(theme.tres HandLabel과 같게)
const PX_PER_UNIT: float = 180.0 # 3D 직교 카메라: 1 단위 = 화면 180px
const CHECKS: Array[String] = [
	"나는 민트초코를 좋아한다.",
	"마을에서 민초가 소수파라는 걸 안다.",
	"민초를 위해서라면 무슨 짓이든 할 수 있다.",
]
# 네 귀퉁이 주인공: 발 위치(3D 단위), 복장 단계(끝낸 작전 수), 행동, 소품. 왼쪽은 오른쪽을, 오른쪽은 왼쪽을 비스듬히 본다
const CREW: Array[Dictionary] = [
	{"pos": Vector2(-4.3, 0.75), "stage": 0, "anim": "phone", "prop": &"phone"},
	{"pos": Vector2(4.3, 0.75), "stage": 2, "anim": "magnifier", "prop": &"magnifier"},
	{"pos": Vector2(-4.3, -2.85), "stage": 4, "anim": "coffee", "prop": &"mug"},
	{"pos": Vector2(4.3, -2.85), "stage": GameState.MINIGAME_COUNT, "anim": "point", "prop": &"pointer"},
]
const CREW_TURN: float = 0.6
const STAMP_SIZE: float = 150.0
const NAME_MAX: int = 10 # 리더보드 한 줄에 들어가게

var _stamp_slot: Control
var _start: Button
var _sign: LineEdit
var _ice: IceCream
var _sfx: AudioStreamPlayer


func _ready() -> void:
	GameState.reset() # 타이틀은 항상 새 방문자의 시작점
	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	var wall: ColorRect = ColorRect.new()
	wall.color = PALETTE.wood.darkened(0.55)
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(wall)
	_build_form()
	_build_3d()
	_build_light()
	_sign.grab_focus() # 바로 이름을 쓰고 Enter로 입단


func _process(delta: float) -> void:
	_ice.rotation.y += delta * 0.8 # 핀 대신 꽂힌 아이스크림이 천천히 돈다


# --- 원서 ---

func _build_form() -> void:
	var form: PanelContainer = PanelContainer.new()
	var paper: StyleBoxFlat = StyleBoxFlat.new()
	paper.bg_color = PALETTE.paper
	paper.set_corner_radius_all(4)
	paper.shadow_color = Color(0, 0, 0, 0.45)
	paper.shadow_size = 18
	paper.shadow_offset = Vector2(8, 12)
	paper.content_margin_left = 70
	paper.content_margin_right = 70
	paper.content_margin_top = 170 # 위는 꽂힌 아이스크림 자리
	paper.content_margin_bottom = 50
	form.add_theme_stylebox_override("panel", paper)
	form.custom_minimum_size = FORM_SIZE
	form.size = FORM_SIZE
	form.position = FORM_CENTER - FORM_SIZE / 2.0
	form.pivot_offset = FORM_SIZE / 2.0
	form.rotation = FORM_TILT
	add_child(form)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	form.add_child(box)

	box.add_child(_hand("민초의, 민초를 위한,\n민초에 의한", 84, INK, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_hand("― 민초단 입단 원서 ―", 46, PALETTE.yarn, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_gap(10))
	box.add_child(_hand("작은 마을의 소수파, 민초단에 입단하시겠습니까?", 38, INK, HORIZONTAL_ALIGNMENT_LEFT))
	for line in CHECKS:
		box.add_child(_check(line))
	box.add_child(_gap(10))

	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 30)
	box.add_child(bottom)
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 18)
	bottom.add_child(left)
	left.add_child(_signature())
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 24)
	left.add_child(buttons)
	_start = Button.new()
	_start.text = "입단하기"
	_start.custom_minimum_size = Vector2(300, 90)
	_start.add_theme_font_override("font", get_theme_font("font", &"HandLabel"))
	_start.add_theme_font_size_override("font_size", 56)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		_start.add_theme_color_override(state, INK)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		_start.add_theme_stylebox_override(state, _pill(state))
	_start.pressed.connect(_join)
	buttons.add_child(_start)
	var board: Button = Button.new()
	board.theme_type_variation = &"HandButton"
	board.text = "리더보드"
	board.pressed.connect(Flow.go_leaderboard)
	buttons.add_child(board)
	_stamp_slot = _circle(PALETTE.furniture, 3, "도장", 34)
	_stamp_slot.custom_minimum_size = Vector2(STAMP_SIZE, STAMP_SIZE)
	bottom.add_child(_stamp_slot)


# 서명란: 밑줄 위에 손글씨로 이름을 쓴다(리더보드 이름). 비워 두면 리더보드가 '민초단원 N호'를 붙인다. Enter = 입단
func _signature() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_hand("서명:", 40, INK, HORIZONTAL_ALIGNMENT_LEFT))
	_sign = LineEdit.new()
	_sign.custom_minimum_size = Vector2(380, 0)
	_sign.max_length = NAME_MAX
	_sign.placeholder_text = "이름 (안 써도 됨)"
	_sign.add_theme_font_override("font", get_theme_font("font", &"HandLabel"))
	_sign.add_theme_font_size_override("font_size", 44)
	_sign.add_theme_color_override("font_color", INK)
	_sign.add_theme_color_override("font_uneditable_color", INK) # 입단 뒤 잠가도 서명은 진하게
	_sign.add_theme_color_override("caret_color", INK)
	_sign.add_theme_color_override("font_placeholder_color", Color(INK, 0.35))
	var line: StyleBoxFlat = StyleBoxFlat.new()
	line.bg_color = Color(0, 0, 0, 0)
	line.border_color = INK
	line.border_width_bottom = 3
	line.content_margin_left = 6
	for state: String in ["normal", "focus", "read_only"]:
		_sign.add_theme_stylebox_override(state, line)
	_sign.text_submitted.connect(func(_t: String) -> void: _join())
	row.add_child(_sign)
	return row


# [입단하기] 버튼 모양: 민트 바탕에 잉크 테두리. 마우스를 올리면 밝게, 누르면 어둡게
func _pill(state: String) -> StyleBox:
	if state == "focus":
		return StyleBoxEmpty.new() # 키보드 선택 테두리는 그리지 않는다(Space·Enter는 그대로 먹는다)
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = PALETTE.mincho
	if state == "hover":
		s.bg_color = PALETTE.mincho.lightened(0.2)
	elif state == "pressed" or state == "disabled":
		s.bg_color = PALETTE.mincho.darkened(0.15)
	s.border_color = INK
	s.set_border_width_all(4)
	s.set_corner_radius_all(14)
	return s


# 네모 칸 + 빨간 펜으로 쓴 체크 + 손글씨 문장
func _check(text: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var box: Panel = Panel.new()
	box.custom_minimum_size = Vector2(34, 34)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var frame: StyleBoxFlat = StyleBoxFlat.new()
	frame.bg_color = Color(0, 0, 0, 0)
	frame.border_color = INK
	frame.set_border_width_all(3)
	box.add_theme_stylebox_override("panel", frame)
	var tick: Label = _hand("V", 48, PALETTE.yarn, HORIZONTAL_ALIGNMENT_CENTER)
	tick.position = Vector2(-2, -14) # 칸 위로 살짝 삐져나오게 쓴 펜 체크
	tick.size = Vector2(40, 60)
	box.add_child(tick)
	row.add_child(box)
	row.add_child(_hand(text, 38, INK, HORIZONTAL_ALIGNMENT_LEFT))
	return row


# 동그란 테두리 안에 글자 하나(도장 자리·찍힌 도장)
func _circle(color: Color, border: int, text: String, font_size: int) -> Panel:
	var ring: Panel = Panel.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = color
	style.set_border_width_all(border)
	style.set_corner_radius_all(int(STAMP_SIZE / 2.0))
	ring.add_theme_stylebox_override("panel", style)
	ring.size = Vector2(STAMP_SIZE, STAMP_SIZE)
	var label: Label = _hand(text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.add_child(label)
	return ring


func _hand(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var l: Label = Label.new()
	l.theme_type_variation = &"HandLabel"
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _gap(h: float) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


# 입단: 도장 자리에 초록 '입단' 도장이 쾅 찍히고 조금 뒤 작전본부실로
func _join() -> void:
	if _start.disabled:
		return # 버튼과 Enter가 겹쳐 두 번 찍히지 않게
	_start.disabled = true
	GameState.player_name = _sign.text.strip_edges()
	_sign.editable = false
	var seal: Panel = _circle(PALETTE.mincho.darkened(0.25), 8, "입단", 64)
	seal.pivot_offset = Vector2(STAMP_SIZE, STAMP_SIZE) / 2.0
	seal.rotation = -0.25
	seal.scale = Vector2.ONE * 1.8
	seal.modulate.a = 0.0
	_stamp_slot.add_child(seal)
	var t: Tween = create_tween()
	t.tween_property(seal, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(seal, "modulate:a", 1.0, 0.12)
	t.tween_callback(_stamp_slot.get_child(0).hide) # 자리 안내 글자 '도장'이 찍힌 '입단'과 겹치지 않게
	t.tween_callback(Beep.play.bind(_sfx, 90.0, 0.18)) # 쾅
	t.tween_interval(0.6)
	t.tween_callback(Flow.go_hub)


# --- 3D: 아이스크림 + 주인공 넷 ---

# 투명 배경 3D 층을 원서 위에 겹친다(아이스크림이 원서 위에 꽂혀 보이게). 마우스는 통과
func _build_3d() -> void:
	var holder: SubViewportContainer = SubViewportContainer.new()
	holder.stretch = true
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var vp: SubViewport = SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	holder.add_child(vp)
	var cam: Camera3D = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1080.0 / PX_PER_UNIT
	cam.position = Vector3(0, 0, 20)
	vp.add_child(cam)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = PALETTE.lamp_light
	sun.rotation_degrees = Vector3(-35, 25, 0)
	vp.add_child(sun)
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = PALETTE.lamp_light
	env.ambient_light_energy = 0.55
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)

	_ice = IceCream.new()
	_ice.scale = Vector3.ONE * 0.75
	_ice.rotation.z = 0.12 # 비스듬히 꽂힘
	_ice.position = _to_3d(FORM_CENTER + Vector2(0, -FORM_SIZE.y / 2.0 + 75))
	vp.add_child(_ice)

	for c: Dictionary in CREW:
		var hero: Protagonist = PROTAGONIST.instantiate()
		vp.add_child(hero)
		hero.position = Vector3(c["pos"].x, c["pos"].y, 0)
		hero.rotation.y = CREW_TURN * (1.0 if c["pos"].x < 0.0 else -1.0)
		hero.set_stage(c["stage"])
		hero.act(c["anim"], c["prop"])


func _to_3d(px: Vector2) -> Vector3:
	return Vector3((px.x - 960.0) / PX_PER_UNIT, (540.0 - px.y) / PX_PER_UNIT, 0)


# 아지트 조명: 원서 위 조명 하나만. 스탠드는 화면 밖으로 치우고 빛줄기를 끈다
func _build_light() -> void:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = LIGHT_SHADER
	mat.set_shader_parameter("dark", PALETTE.hideout_dark)
	mat.set_shader_parameter("warm", PALETTE.lamp_light)
	mat.set_shader_parameter("ceiling", FORM_CENTER + Vector2(0, -80))
	mat.set_shader_parameter("ceiling_radius", Vector2(1250, 1000))
	mat.set_shader_parameter("max_dark", 0.7)
	mat.set_shader_parameter("beam_strength", 0.0)
	mat.set_shader_parameter("lamp_shade", Vector2(-5000, -5000))
	mat.set_shader_parameter("lamp_pool", Vector2(-5000, -4000))
	var cover: ColorRect = ColorRect.new()
	cover.material = mat
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)
