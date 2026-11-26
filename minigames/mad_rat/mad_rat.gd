extends Node3D
## 미친 쥐(id: mad_rat). 갈림길로 걸어오는 주민은 가운데 표지판이 가리키는 쪽으로 간다.
## 버튼은 표지판만 돌린다. 민초는 왼쪽 투표소, 반민초는 오른쪽 민트초코 아이스크림가게.
## 웨이브식: 웨이브가 시작될 때마다 세로길 옆에 새 규칙 표지판이 꽂히고, 규칙은 쌓인다(MadRatRules.Twist).

enum State { TUTORIAL, PLAYING, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: MadRatConfig = preload("res://minigames/mad_rat/mad_rat_config.tres")
const VILLAGER: PackedScene = preload("res://minigames/mad_rat/villager.tscn")
const SPAWN_Z: float = -9.0
const JUNCTION_Z: float = 0.0 # 이 선에 닿는 순간 표지판 방향으로 간다
const EXIT_X: float = 6.5
const SIGN_POS: Vector3 = Vector3(0.0, 0.0, 1.6) # 갈림길 바로 앞(카메라 쪽). 주민 길을 막지 않는다
const SHOP_WAIT: float = 0.7 # 가게 앞에서 멈칫하는 시간
const TUTORIAL_TEXT: String = "주민이 갈림길로 걸어옵니다. 가운데 표지판이 가리키는 쪽으로 갑니다.\n버튼으로 표지판을 돌리세요. 민초는 [투표소], 반민초는 [민트초코 아이스크림가게]!\n웨이브마다 길가에 새 규칙 표지판이 꽂힙니다. 규칙은 계속 쌓입니다!"
# 웨이브 순서대로 꽂히는 규칙 표지판 [문구, 자리]. 세로길 양옆 빈 땅에 앞 왼쪽 → 앞 오른쪽 → 뒤 왼쪽 → 뒤 오른쪽
const RULE_SIGNS: Array = [
	["민트 셔츠 → 투표소\n갈색 셔츠 → 가게", Vector3(-3.5, 0.0, -2.6)],
	["모자는 무시!", Vector3(3.5, 0.0, -2.6)],
	["코트를 입었으면\n완장 색을 봐라", Vector3(-3.5, 0.0, -6.6)],
	["선글라스 = 변장\n셔츠 색 반대로!", Vector3(3.5, 0.0, -6.6)],
]

@export var id: StringName = &"mad_rat"

var _state: State = State.TUTORIAL
var _wave: int = -1
var _wave_left: int = 0 # 이번 웨이브에서 아직 안 나온 주민 수
var _spawned: int = 0
var _total: int = 0
var _wrong: int = 0
var _next_spawn: float = 0.0
var _sfx: AudioStreamPlayer
var _queue: Array[Villager] = [] # 갈림길에 가까운 주민이 앞(0번)
var _sign_dir: MadRatRules.Dir = MadRatRules.Dir.LEFT
var _sign_arrow: Node3D
var _sign_tween: Tween
var _shop: Node3D

@onready var _camera: Camera3D = $Camera3D
@onready var _villagers: Node3D = $Villagers
@onready var _hint: Label = $HUD/HintLabel


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 20.0, 0.0)
	_camera.look_at_from_position(Vector3(0.0, 9.0, 8.0), Vector3(0.0, 0.0, -2.0))
	_build_visuals()
	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	for n in CONFIG.wave_counts:
		_total += n
	$HUD/LeftButton.pressed.connect(_turn_sign.bind(MadRatRules.Dir.LEFT))
	$HUD/RightButton.pressed.connect(_turn_sign.bind(MadRatRules.Dir.RIGHT))
	Tutorial.open(self, TUTORIAL_TEXT, _start)


func _process(delta: float) -> void:
	if _state != State.PLAYING:
		return
	if _wave_left > 0:
		_next_spawn -= delta
		if _next_spawn <= 0.0:
			_spawn()
			_next_spawn = CONFIG.wave_gap[_wave]
	var step: float = CONFIG.wave_speed[_wave] * delta
	for v in _queue:
		v.position.z += step
	if not _queue.is_empty() and _queue[0].position.z >= JUNCTION_Z:
		_send(_queue.pop_front())
	if _wave_left == 0 and _queue.is_empty() and _villagers.get_child_count() == 0:
		# 이번 웨이브 마지막 주민이 가게로 끌려 들어가는 것까지 보고 넘어간다
		if _wave + 1 < CONFIG.wave_counts.size():
			_begin_wave(_wave + 1)
		else:
			_finish()


func _start() -> void:
	_state = State.PLAYING
	_begin_wave(0)


func _begin_wave(w: int) -> void:
	_wave = w
	_wave_left = CONFIG.wave_counts[w]
	_next_spawn = CONFIG.wave_pause
	if w < RULE_SIGNS.size():
		_hint.text = "새 규칙!" if w > 0 else ""
		_plant_sign(w)
	else:
		_hint.text = "규칙은 그대로, 한 번 더!"
	_refresh()


func _spawn() -> void:
	var v: Villager = VILLAGER.instantiate()
	_villagers.add_child(v)
	v.position = Vector3(0.0, 0.0, SPAWN_Z)
	var twist: MadRatRules.Twist = MadRatRules.Twist.NONE
	var unlocked: Array[MadRatRules.Twist] = MadRatRules.unlocked_twists(_wave)
	if not unlocked.is_empty() and randf() < CONFIG.twist_ratio:
		twist = unlocked.pick_random()
	v.setup(randf() < CONFIG.mincho_ratio, twist)
	_queue.append(v)
	_wave_left -= 1
	_spawned += 1
	_hint.text = ""
	_refresh()


func _turn_sign(dir: MadRatRules.Dir) -> void:
	if _state != State.PLAYING:
		return
	_sign_dir = dir
	if _sign_tween != null:
		_sign_tween.kill()
	_sign_tween = create_tween()
	_sign_tween.tween_property(_sign_arrow, "rotation:y", 0.0 if dir == MadRatRules.Dir.LEFT else PI, 0.12)


# 갈림길에 닿은 주민을 표지판 방향으로 보낸다
func _send(v: Villager) -> void:
	var dir: MadRatRules.Dir = _sign_dir
	if MadRatRules.is_correct(v.is_mincho, dir):
		_hint.text = ""
	else:
		_wrong += 1
		_hint.text = "엉뚱한 곳으로 갔다!"
	_refresh()
	var dest: Vector3 = Vector3(-EXIT_X if dir == MadRatRules.Dir.LEFT else EXIT_X, 0.0, JUNCTION_Z)
	v.rotation.y = atan2(dest.x - v.position.x, dest.z - v.position.z) # 주민 앞은 +z
	var t: Tween = create_tween()
	t.tween_property(v, "position", dest, 0.6)
	if dir == MadRatRules.Dir.RIGHT: # 가게에 빨려 들어간 뒤 안에서 반응: 반민초는 기겁, 민초는 홀딱 반해 투표를 잊는다
		t.tween_property(v, "position", dest + Vector3(2.0, 0.0, 0.0), 0.25).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(v, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN)
		t.tween_callback(_shop_react.bind(v.is_mincho))
	t.tween_callback(v.queue_free)


# 가게가 들썩이고 문 위에 반응이 뜬다
func _shop_react(mincho: bool) -> void:
	var label: Label3D = Label3D.new()
	label.text = "♥" if mincho else "?!"
	label.font_size = 128
	label.pixel_size = 0.01
	label.outline_size = 24
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = _shop.position + Vector3(-1.0, 2.8, 1.2)
	_villagers.add_child(label) # Villagers 밑에 두어야 반응이 끝난 뒤에 웨이브가 넘어간다
	label.scale = Vector3.ZERO
	var t: Tween = create_tween()
	t.tween_property(label, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_shop, "scale", Vector3(1.12, 0.88, 1.12), 0.08)
	t.chain().tween_property(_shop, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(SHOP_WAIT)
	t.tween_callback(label.queue_free)


func _finish() -> void:
	_state = State.ENDED
	var rank: Grade.Rank = MadRatRules.judge(_wrong, CONFIG.perfect_wrong, CONFIG.success_wrong)
	var msg: String
	match rank:
		Grade.Rank.PERFECT:
			msg = "반민초 주민들은 민트초코 아이스크림가게에서 아직도 나오지 못하고 있다."
		Grade.Rank.SUCCESS:
			msg = "몇 명이 길을 헤맸지만 대체로 계획대로다."
		_:
			msg = "민초 주민들이 아이스크림을 먹느라 투표를 잊었다. 투표소는 반민초로 북적인다."
	var before: float = GameState.mincho_percent
	GameState.submit_result(id, rank)
	ResultScreen.open(self, rank, msg, before)


func _refresh() -> void:
	$HUD/ProgressLabel.text = "웨이브 %d / %d   %d / %d명  실수 %d" % [_wave + 1, CONFIG.wave_counts.size(), _spawned, _total, _wrong]


# --- 화면 ---

func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material = mat
	m.mesh = mesh
	return m


func _place(size: Vector3, pos: Vector3, color: Color, text: String) -> void:
	var m: MeshInstance3D = _box(size, color)
	m.position = pos
	add_child(m)
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = 96
	label.pixel_size = 0.01
	label.position = Vector3(pos.x, size.y + 0.8, pos.z)
	add_child(label)


# 겉모습은 이 함수에만 모아 두어 스타일 확정 때 한 곳에서 교체한다
func _build_visuals() -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = PALETTE.background
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.6
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var ground: MeshInstance3D = _box(Vector3(24.0, 0.2, 22.0), PALETTE.background.darkened(0.15))
	ground.position = Vector3(0.0, -0.1, -2.0)
	add_child(ground)

	var road: MeshInstance3D = _box(Vector3(2.0, 0.05, 11.0), PALETTE.road)
	road.position = Vector3(0.0, 0.02, -4.5)
	add_child(road)
	var cross: MeshInstance3D = _box(Vector3(2.0 * EXIT_X + 1.0, 0.05, 2.0), PALETTE.road)
	cross.position = Vector3(0.0, 0.02, JUNCTION_Z)
	add_child(cross)

	_place(Vector3(3.0, 1.5, 3.0), Vector3(-EXIT_X - 1.5, 0.75, JUNCTION_Z), PALETTE.ballot_box, "투표소")

	# 민트초코 아이스크림가게: 초코 벽, 민트 지붕, 지붕 위 큰 콘
	var shop_x: float = EXIT_X + 2.0 # 지붕이 가게 앞에 멈춘 주민을 가리지 않게 길 끝에서 띄운다
	_shop = Node3D.new() # 가게 전체. 손님이 들어가면 들썩인다
	_shop.position = Vector3(shop_x, 0.0, JUNCTION_Z)
	add_child(_shop)
	var walls: MeshInstance3D = _box(Vector3(3.0, 1.8, 3.0), PALETTE.chocolate)
	walls.position = Vector3(0.0, 0.9, 0.0)
	_shop.add_child(walls)
	var roof: MeshInstance3D = _box(Vector3(3.4, 0.4, 3.4), PALETTE.mincho)
	roof.position = Vector3(0.0, 2.0, 0.0)
	_shop.add_child(roof)
	var door: MeshInstance3D = _box(Vector3(0.05, 1.2, 1.0), PALETTE.mincho.darkened(0.3)) # 길 쪽(왼쪽) 벽의 문
	door.position = Vector3(-1.52, 0.6, 0.0)
	_shop.add_child(door)
	var cone: MeshInstance3D = MeshInstance3D.new()
	var cone_mesh: CylinderMesh = CylinderMesh.new()
	cone_mesh.top_radius = 0.45
	cone_mesh.bottom_radius = 0.0
	cone_mesh.height = 1.0
	var cone_mat: StandardMaterial3D = StandardMaterial3D.new()
	cone_mat.albedo_color = PALETTE.cardboard
	cone_mesh.material = cone_mat
	cone.mesh = cone_mesh
	cone.position = Vector3(0.0, 2.7, 0.0)
	_shop.add_child(cone)
	var scoop: MeshInstance3D = MeshInstance3D.new()
	var scoop_mesh: SphereMesh = SphereMesh.new()
	scoop_mesh.radius = 0.55
	scoop_mesh.height = 1.0
	var scoop_mat: StandardMaterial3D = StandardMaterial3D.new()
	scoop_mat.albedo_color = PALETTE.mincho
	scoop_mesh.material = scoop_mat
	scoop.mesh = scoop_mesh
	scoop.position = Vector3(0.0, 3.35, 0.0)
	_shop.add_child(scoop)
	for chip in [Vector3(0.3, 0.25, 0.4), Vector3(-0.35, 0.1, 0.38), Vector3(0.05, 0.42, 0.35), Vector3(0.45, -0.05, 0.25)]:
		var c: MeshInstance3D = _box(Vector3(0.14, 0.14, 0.14), PALETTE.chocolate)
		c.position = scoop.position + chip
		_shop.add_child(c)
	var shop_label: Label3D = Label3D.new()
	shop_label.text = "민트초코\n아이스크림"
	shop_label.font_size = 72
	shop_label.pixel_size = 0.01
	shop_label.position = Vector3(shop_x, 4.6, JUNCTION_Z - 1.5) # 콘 뒤쪽 위. 위에서 보는 카메라라 콘과 겹치지 않게
	add_child(shop_label)

	_build_turn_sign()


# 규칙 표지판: 위에서 떨어져 땅에 쿵 꽂힌다. 꽂힌 표지판은 끝까지 남는다
func _plant_sign(w: int) -> void:
	var s: Node3D = Node3D.new()
	add_child(s)
	var post: MeshInstance3D = _box(Vector3(0.18, 1.6, 0.18), PALETTE.wood)
	post.position.y = 0.8
	s.add_child(post)
	var board: Node3D = Node3D.new()
	board.position.y = 1.9
	board.rotation.x = deg_to_rad(-25.0) # 위에서 내려다보는 카메라 쪽으로 살짝 눕힌다
	s.add_child(board)
	board.add_child(_box(Vector3(4.0, 1.4, 0.1), PALETTE.paper))
	var label: Label3D = Label3D.new()
	label.text = RULE_SIGNS[w][0]
	label.font_size = 50
	label.pixel_size = 0.01
	label.outline_size = 0
	label.modulate = PALETTE.stamp
	label.position.z = 0.06
	board.add_child(label)
	var ground: Vector3 = RULE_SIGNS[w][1]
	s.position = ground + Vector3(0.0, 8.0, 0.0)
	var t: Tween = create_tween()
	t.tween_property(s, "position", ground, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(Beep.play.bind(_sfx, 80.0, 0.2))
	t.tween_property(s, "scale", Vector3(1.1, 0.85, 1.1), 0.06)
	t.tween_property(s, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_turn_sign() -> void:
	# 표지판: 기둥 + 회전하는 화살표 판. rotation.y 0 = 왼쪽(투표소), PI = 오른쪽(가게)
	var post: MeshInstance3D = _box(Vector3(0.15, 1.6, 0.15), PALETTE.wood)
	post.position = SIGN_POS + Vector3(0.0, 0.8, 0.0)
	add_child(post)
	_sign_arrow = Node3D.new()
	_sign_arrow.position = SIGN_POS + Vector3(0.0, 1.5, 0.0)
	add_child(_sign_arrow)
	var board: MeshInstance3D = _box(Vector3(1.3, 0.45, 0.08), PALETTE.paper)
	board.position.x = -0.35
	_sign_arrow.add_child(board)
	var tip: MeshInstance3D = _box(Vector3(0.4, 0.4, 0.08), PALETTE.paper) # 45도 돌린 네모 = 화살촉
	tip.position.x = -1.0
	tip.rotation.z = PI / 4.0
	_sign_arrow.add_child(tip)
