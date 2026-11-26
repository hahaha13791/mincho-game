class_name HubDesk
extends Node3D
## 작전본부실 보드 아래 책상과 소품(3D). 허브가 투명 배경 SubViewport로 보드 위에 겹친다.
## 카메라는 정면에서 살짝 내려다보는 직교(화면 1px ≈ 0.01m). 책상 윗면은 화면 아래쪽 약 25% 높이.
## 반복 소품이 적어 코드로 배치한다. 색은 팔레트에서만.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const TOP_Y: float = -2.7 # 책상 윗면 높이(월드). 화면 약 805px
const DEPTH: float = 1.6
const PROTAGONIST: PackedScene = preload("res://main/hub/protagonist.tscn")
const HERO_SCALE: float = 1.8

var _camera: Camera3D
var _folder: Node3D
var _hero: Protagonist


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
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 25, 0)
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.45
	add_child(sun)
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.6
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_build()


## 주인공 복장 단계(끝낸 작전 수)
func set_stage(done: int) -> void:
	_hero.set_stage(done)


## 리더보드 서류철이 화면에 찍히는 위치(버튼을 얹을 자리)
func folder_screen_pos() -> Vector2:
	return _camera.unproject_position(_folder.global_position)


func _build() -> void:
	var wood: Color = PALETTE.wood.lightened(0.12)
	_box(Vector3(22, 0.16, DEPTH), Vector3(0, TOP_Y - 0.08, 0), wood) # 상판
	_box(Vector3(22, 0.06, 0.06), Vector3(0, TOP_Y - 0.03, DEPTH / 2.0), wood.lightened(0.15)) # 앞 모서리
	_box(Vector3(22, 5.0, 0.1), Vector3(0, TOP_Y - 2.6, DEPTH / 2.0 - 0.05), wood.darkened(0.15)) # 앞판(화면 아래 끝까지)
	for x in [-6.0, 0.0, 6.0]: # 서랍 손잡이
		_box(Vector3(0.6, 0.08, 0.08), Vector3(x, TOP_Y - 0.6, DEPTH / 2.0 + 0.02), PALETTE.iron)

	# 주인공: 책상 뒤에 서서 허리 아래는 책상에 가린다
	_hero = PROTAGONIST.instantiate()
	_hero.scale = Vector3.ONE * HERO_SCALE
	_hero.position = Vector3(4.4, TOP_Y - 1.05, -0.5)
	add_child(_hero)

	# 스탠드(왼쪽)
	var lamp: Node3D = _group(Vector3(-7.6, TOP_Y, -0.2))
	_cyl(lamp, 0.45, 0.08, Vector3(0, 0.04, 0), PALETTE.stamp)
	var arm1: MeshInstance3D = _cap(lamp, 0.06, 1.6, Vector3(0.25, 0.8, 0), PALETTE.stamp)
	arm1.rotation.z = -0.35
	var arm2: MeshInstance3D = _cap(lamp, 0.06, 1.2, Vector3(0.8, 1.75, 0), PALETTE.stamp)
	arm2.rotation.z = 1.0
	var shade: MeshInstance3D = _cone(lamp, 0.12, 0.5, 0.55, Vector3(1.35, 1.6, 0), PALETTE.mincho.darkened(0.25))
	shade.rotation.z = 0.5

	# 커피잔
	var mug: Node3D = _group(Vector3(-5.6, TOP_Y, 0.2))
	_cyl(mug, 0.3, 0.55, Vector3(0, 0.275, 0), PALETTE.paper)
	_cyl(mug, 0.26, 0.02, Vector3(0, 0.55, 0), PALETTE.wood.darkened(0.45)) # 커피
	var handle: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.17
	handle.mesh = torus
	handle.material_override = _mat(PALETTE.paper)
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
	add_child(n)
	return n


func _mat(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	return m


func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	return _box_in(self, size, pos, color)


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
