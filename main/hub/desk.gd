class_name HubDesk
extends Node3D
## 작전본부실 보드 아래 책상과 소품(3D). 허브가 투명 배경 SubViewport로 보드 위에 겹친다.
## 카메라는 정면에서 살짝 내려다보는 직교(화면 1px ≈ 0.01m). 책상 윗면은 화면 아래쪽 약 25% 높이.
## 반복 소품이 적어 코드로 배치한다. 색은 팔레트에서만.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const TOP_Y: float = -2.7 # 책상 윗면 높이(월드). 화면 약 805px
const DEPTH: float = 1.6
## 책상(상판·소품) 앞뒤 위치. 뒷면이 주인공(z -0.5) 몸 앞에 오게 앞으로 뺀다. 겹치면 다리가 상판을 뚫고 잘려 보인다
const DESK_Z: float = 0.75
const FLOOR_Y: float = TOP_Y - 1.2 # 바닥 = 주인공 발. 책상 높이 1.2 : 주인공 키 약 3 (실제 책상 비율)
const DESK_W: float = 18.6 # 양 끝 다리가 화면(폭 약 19.2) 안에 보이게
const PROTAGONIST: PackedScene = preload("res://main/hub/protagonist.tscn")
const HERO_SCALE: float = 1.8
## 주인공의 작전 행동. xs = 설 수 있는 위치(x) 후보, face = 바라보는 방향(0 = 화면, PI = 보드),
## lift = 의자 위에 올라선 높이, prop = 손에 드는 소품, hide = 손에 들면 책상에서 숨길 소품, desk = 책상에 펼칠 소품
const ACTIONS: Dictionary = {
	&"think": {"xs": [-3.2, 0.6, 4.0], "face": 0.0},
	&"point": {"xs": [-4.5, 1.8], "face": 2.6, "prop": &"pointer"},
	&"coffee": {"xs": [-1.5, 3.0], "face": 2.2, "prop": &"mug", "hide": "mug"},
	&"map": {"xs": [-2.0, 2.2], "face": 0.0, "desk": "map"},
	&"phone": {"xs": [-4.0, 4.5], "face": 0.5, "prop": &"phone"},
	&"pin": {"xs": [-3.5, 0.0, 3.2], "face": PI, "lift": 0.1, "prop": &"pin"},
	&"magnifier": {"xs": [-0.8, 3.6], "face": 2.9, "prop": &"magnifier", "hide": "magnifier"},
	&"write": {"xs": [-3.0, 1.5], "face": 0.2, "prop": &"pen", "desk": "notepad"},
}

## 직전에 한 행동. 작전본부실에 다시 들어와도 같은 행동은 고르지 않는다(게임이 켜져 있는 동안 유지)
static var last_action: StringName = &""

var _camera: Camera3D
var _folder: Node3D
var _hero: Protagonist
var _desk_props: Dictionary = {} # 이름 -> Node3D (mug, magnifier)
var _desk_root: Node3D # 책상과 그 위 소품. DESK_Z만큼 앞에
var _shade: MeshInstance3D # 스탠드 갓. 조명 덮개가 빛 방향을 잰다


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 10.8
	# 원점을 바라보며 11도 내려다본다. 그래야 화면 높이 ≈ 월드 y * 100px 로 보드(2D)와 맞춰 놓기 쉽다
	var tilt: float = deg_to_rad(11.0)
	_camera.position = Vector3(0, 12.0 * sin(tilt), 12.0 * cos(tilt))
	_camera.rotation.x = -tilt
	_camera.current = true
	add_child(_camera)
	var sun: DirectionalLight3D = DirectionalLight3D.new() # 위에서 비추는 따뜻한 백색 조명
	sun.rotation_degrees = Vector3(-78, 12, 0)
	sun.light_color = PALETTE.lamp_light
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.45
	add_child(sun)
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = PALETTE.lamp_light
	env.ambient_light_energy = 0.55
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_build()


## 주인공 복장 단계(끝낸 작전 수)를 정하고, 직전과 다른 작전 행동을 무작위 위치에서 시작한다
## force는 확인용(비우면 무작위)
func set_stage(done: int, force: StringName = &"") -> void:
	_hero.set_stage(done)
	var choices: Array = ACTIONS.keys().filter(func(k: StringName) -> bool: return k != last_action)
	var act_name: StringName = force if not force.is_empty() else choices.pick_random()
	last_action = act_name
	var a: Dictionary = ACTIONS[act_name]
	var x: float = a["xs"].pick_random()
	# 책상을 앞으로 뺀 만큼(DESK_Z × tan 11°) 내려야 책상 위로 보이는 몸 높이가 같다
	_hero.position = Vector3(x, FLOOR_Y + a.get("lift", 0.0), -0.5)
	_hero.rotation.y = a["face"]
	_hero.act(String(act_name), a.get("prop", &""))
	if a.has("hide"):
		_desk_props[a["hide"]].hide()
	match a.get("desk", ""):
		"map": # 책상에 펼친 마을 지도
			var map: MeshInstance3D = _box(Vector3(1.8, 0.02, 1.1), Vector3(x, TOP_Y + 0.01, 0.15), PALETTE.water.lightened(0.45))
			map.rotation.y = 0.08
			_box(Vector3(1.2, 0.025, 0.04), Vector3(x - 0.1, TOP_Y + 0.02, 0.1), PALETTE.road)
			_box(Vector3(0.04, 0.025, 0.8), Vector3(x + 0.3, TOP_Y + 0.02, 0.15), PALETTE.road)
		"notepad":
			_box(Vector3(0.8, 0.04, 0.55), Vector3(x - 0.2, TOP_Y + 0.02, 0.2), PALETTE.memo)


## 리더보드 서류철이 화면에 찍히는 위치(버튼을 얹을 자리)
func folder_screen_pos() -> Vector2:
	return _camera.unproject_position(_folder.global_position)


## 스탠드 빛이 화면에 찍히는 위치: [갓 입구, 갓이 향하는 방향으로 닿는 책상 위]. 허브 조명 덮개가 쓴다
func lamp_screen_pos() -> PackedVector2Array:
	var mouth: Vector3 = _shade.to_global(Vector3(0, -0.275, 0)) # 원뿔의 넓은 쪽(-y)
	var aim: Vector3 = _shade.global_basis * Vector3.DOWN
	var pool: Vector3 = mouth + aim * ((TOP_Y - mouth.y) / aim.y)
	return PackedVector2Array([_camera.unproject_position(mouth), _camera.unproject_position(pool)])


func _build() -> void:
	_desk_root = Node3D.new()
	_desk_root.position.z = DESK_Z
	add_child(_desk_root)
	var wood: Color = PALETTE.wood.lightened(0.12)
	_box(Vector3(DESK_W, 0.16, DEPTH), Vector3(0, TOP_Y - 0.08, 0), wood) # 상판
	_box(Vector3(DESK_W, 0.06, 0.06), Vector3(0, TOP_Y - 0.03, DEPTH / 2.0), wood.lightened(0.15)) # 앞 모서리
	# 상판 아래 앞뒤 띠 + 다리 4개. 다리 사이로 책상 밑(어두운 벽·바닥·주인공 다리)이 보여야 책상으로 읽힌다
	for z in [DEPTH / 2.0 - 0.1, -DEPTH / 2.0 + 0.1]:
		_box(Vector3(DESK_W - 0.4, 0.12, 0.06), Vector3(0, TOP_Y - 0.22, z), wood.darkened(0.1))
		for x in [-DESK_W / 2.0 + 0.3, DESK_W / 2.0 - 0.3]:
			_box(Vector3(0.22, TOP_Y - FLOOR_Y, 0.22), Vector3(x, (TOP_Y + FLOOR_Y) / 2.0, z), wood.darkened(0.1))
	# 바닥(화면 아래 끝까지)과 책상 밑 뒷벽. 책상과 따로 앞뒤 위치를 잡는다
	_box_in(self, Vector3(26, 0.1, 12), Vector3(0, FLOOR_Y - 0.05, 4.0), PALETTE.wood.darkened(0.4))
	# 뒷벽은 뒤에 있어 화면에서 더 높이 찍힌다. 상판 위로 삐져나오지 않게 낮춘다
	var wall_top: float = TOP_Y - 0.4
	_box_in(self, Vector3(26, wall_top - FLOOR_Y, 0.1), Vector3(0, (wall_top + FLOOR_Y) / 2.0, -1.6), PALETTE.wood.darkened(0.6)) # 책상 밑 그늘

	# 주인공: 책상 뒤에 서서 허리 아래는 책상에 가린다. 위치·행동은 set_stage()에서 정한다
	_hero = PROTAGONIST.instantiate()
	_hero.scale = Vector3.ONE * HERO_SCALE
	add_child(_hero)

	# 스탠드(왼쪽)
	var lamp: Node3D = _group(Vector3(-7.6, TOP_Y, -0.2))
	_cyl(lamp, 0.45, 0.08, Vector3(0, 0.04, 0), PALETTE.stamp)
	var arm1: MeshInstance3D = _cap(lamp, 0.06, 1.6, Vector3(0.25, 0.8, 0), PALETTE.stamp)
	arm1.rotation.z = -0.35
	# 윗팔: 아랫팔 끝(0.52, 1.55)에서 오른쪽 위로 올라가 갓을 높이 든다
	var arm2: MeshInstance3D = _cap(lamp, 0.06, 1.03, Vector3(0.92, 1.765, 0), PALETTE.stamp)
	arm2.rotation.z = -1.08
	# 갓은 팔 끝에 매달려 아래를 본다(빛이 곧게 내려와 책상 웅덩이와 이어지게)
	var shade: MeshInstance3D = _cone(lamp, 0.12, 0.5, 0.55, Vector3(1.32, 1.735, 0), PALETTE.mincho.darkened(0.25))
	_shade = shade

	# 커피잔
	var mug: Node3D = _group(Vector3(-5.6, TOP_Y, 0.2))
	_desk_props["mug"] = mug
	_cyl(mug, 0.3, 0.55, Vector3(0, 0.275, 0), PALETTE.mincho)
	_cyl(mug, 0.26, 0.02, Vector3(0, 0.55, 0), PALETTE.wood.darkened(0.45)) # 커피
	var handle: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.17
	handle.mesh = torus
	handle.material_override = _mat(PALETTE.mincho)
	handle.position = Vector3(0.32, 0.3, 0)
	handle.rotation.x = PI / 2.0
	mug.add_child(handle)

	# 서류 더미(가운데 왼쪽)
	var papers: Node3D = _group(Vector3(-2.6, TOP_Y, 0.0))
	for i in 6:
		var sheet: MeshInstance3D = _box_in(papers, Vector3(1.5, 0.04, 1.0), Vector3(randf_range(-0.06, 0.06), 0.02 + i * 0.045, 0), PALETTE.paper.darkened(randf_range(0, 0.06)))
		sheet.rotation.y = randf_range(-0.15, 0.15)

	# 돋보기(가운데 오른쪽)
	var mag: Node3D = _group(Vector3(3.2, TOP_Y + 0.05, 0.25))
	_desk_props["magnifier"] = mag
	mag.rotation.y = 0.5
	var ring: MeshInstance3D = MeshInstance3D.new()
	var rt: TorusMesh = TorusMesh.new()
	rt.inner_radius = 0.32
	rt.outer_radius = 0.4
	ring.mesh = rt
	ring.material_override = _mat(PALETTE.iron.lightened(0.2))
	mag.add_child(ring)
	var glass: MeshInstance3D = _cyl(mag, 0.33, 0.02, Vector3.ZERO, PALETTE.water.lightened(0.5))
	var glass_mat: StandardMaterial3D = glass.material_override
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color.a = 0.5
	var grip: MeshInstance3D = _cap(mag, 0.07, 0.8, Vector3(0.75, 0, 0), PALETTE.wood.darkened(0.3))
	grip.rotation.z = PI / 2.0

	# 리더보드 서류철(오른쪽)
	_folder = _group(Vector3(6.4, TOP_Y, 0.1))
	_folder.rotation.y = -0.12
	_box_in(_folder, Vector3(2.0, 0.12, 1.3), Vector3(0, 0.06, 0), PALETTE.memo.darkened(0.15))
	_box_in(_folder, Vector3(0.7, 0.12, 0.2), Vector3(-0.55, 0.06, -0.72), PALETTE.memo.darkened(0.15)) # 탭
	_box_in(_folder, Vector3(1.7, 0.02, 1.1), Vector3(0.05, 0.13, 0.05), PALETTE.paper)


func _group(pos: Vector3) -> Node3D:
	var n: Node3D = Node3D.new()
	n.position = pos
	_desk_root.add_child(n)
	return n


func _mat(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	return m


func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	return _box_in(_desk_root, size, pos, color)


func _box_in(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var b: BoxMesh = BoxMesh.new()
	b.size = size
	return _put(parent, b, pos, color)


func _cyl(parent: Node3D, r: float, h: float, pos: Vector3, color: Color) -> MeshInstance3D:
	return _cone(parent, r, r, h, pos, color)


func _cone(parent: Node3D, top_r: float, bottom_r: float, h: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var c: CylinderMesh = CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = h
	return _put(parent, c, pos, color)


func _cap(parent: Node3D, r: float, h: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var c: CapsuleMesh = CapsuleMesh.new()
	c.radius = r
	c.height = h
	return _put(parent, c, pos, color)


func _put(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = _mat(color)
	m.position = pos
	parent.add_child(m)
	return m
