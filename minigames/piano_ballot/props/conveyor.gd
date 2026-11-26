class_name Conveyor
extends Node3D
## 피아노표 컨베이어 겉모습. 로직은 scroll()만 쓴다. 벨트 윗면 높이 = 0.05, +x 방향으로 흐른다.
## 반복 부품(줄무늬·롤러·다리)이 많아 씬 대신 코드로 배치한다. 색은 팔레트에서만 가져온다.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const LENGTH: float = 30.0 # 화면(16:9에서 가로 약 ±8.9, 더 넓은 창은 그 이상)보다 길게 해 끝을 숨긴다
const WIDTH: float = 1.6
const STRIPE_GAP: float = 1.0
const ROLLER_GAP: float = 0.5
const ROLLER_R: float = 0.1
const ROLLER_Y: float = -0.13 # 롤러 윗면이 벨트 밑면(-0.03)에 닿는다
const LEG_GAP: float = 3.0
const MARK_HALF: float = 0.9 # 찍는 자리(x=0) 경고 줄무늬 반폭

var _stripes: Array[Node3D] = []
var _rollers: Array[Node3D] = []


func _ready() -> void:
	var front: float = WIDTH / 2.0
	_add(Vector3(LENGTH, 0.08, WIDTH), Vector3(0, 0.01, 0), PALETTE.belt)
	for i in int(LENGTH / STRIPE_GAP):
		_stripes.append(_add(Vector3(0.08, 0.006, WIDTH * 0.96), Vector3.ZERO, PALETTE.belt.lightened(0.18)))

	var x: float = -LENGTH / 2.0 + ROLLER_GAP / 2.0
	while x < LENGTH / 2.0:
		var pivot: Node3D = Node3D.new()
		pivot.position = Vector3(x, ROLLER_Y, 0)
		add_child(pivot)
		var roller: MeshInstance3D = _mesh(_cylinder(ROLLER_R, WIDTH + 0.1), PALETTE.iron)
		roller.rotation.x = PI / 2.0 # 축을 z 방향으로
		pivot.add_child(roller)
		var cap: MeshInstance3D = _mesh(_cylinder(ROLLER_R * 0.8, 0.02), PALETTE.iron.lightened(0.35))
		cap.rotation.x = PI / 2.0
		cap.position.z = front + 0.06
		pivot.add_child(cap)
		var dot: MeshInstance3D = _mesh(_cube(Vector3(0.035, 0.035, 0.02)), PALETTE.burnt) # 돌아가는 게 보이게
		dot.position = Vector3(0, ROLLER_R * 0.5, front + 0.075)
		pivot.add_child(dot)
		_rollers.append(pivot)
		x += ROLLER_GAP

	# 옆 프레임: 롤러 축 덮개 위아래 띠(앞뒤 양쪽). 그 사이로 롤러가 보인다
	for side in [1.0, -1.0]:
		var z: float = side * (front + 0.1)
		_add(Vector3(LENGTH, 0.06, 0.04), Vector3(0, 0.0, z), PALETTE.iron.darkened(0.2))
		_add(Vector3(LENGTH, 0.06, 0.04), Vector3(0, ROLLER_Y - ROLLER_R - 0.06, z), PALETTE.iron.darkened(0.2))
	for i in int(LENGTH / 2.0): # 볼트
		_add(Vector3(0.05, 0.05, 0.02), Vector3(-LENGTH / 2.0 + 1.0 + i * 2.0, 0.0, front + 0.13), PALETTE.iron.lightened(0.3))

	var lx: float = -LENGTH / 2.0 + LEG_GAP / 2.0
	while lx < LENGTH / 2.0:
		for side in [1.0, -1.0]:
			_add(Vector3(0.18, 1.0, 0.18), Vector3(lx, ROLLER_Y - ROLLER_R - 0.6, side * (front + 0.1)), PALETTE.iron.darkened(0.35))
		_add(Vector3(0.12, 0.12, WIDTH + 0.2), Vector3(lx, -0.95, 0), PALETTE.iron.darkened(0.35))
		lx += LEG_GAP

	# 찍는 자리 표시: 앞쪽 윗 띠에 노랑·검정 경고 줄무늬
	var n: int = 6
	for i in n:
		var w: float = MARK_HALF * 2.0 / n
		var c: Color = PALETTE.accent if i % 2 == 0 else PALETTE.burnt
		_add(Vector3(w, 0.07, 0.02), Vector3(-MARK_HALF + w * (i + 0.5), 0.0, front + 0.125), c)
	scroll(0.0)


## offset = 지금까지 벨트가 흘러간 거리(표와 같은 값)
func scroll(offset: float) -> void:
	for i in _stripes.size():
		_stripes[i].position = Vector3(fposmod(i * STRIPE_GAP + offset, LENGTH) - LENGTH / 2.0, 0.053, 0)
	for r in _rollers:
		r.rotation.z = -offset / ROLLER_R # 윗면이 +x로 움직이는 방향


func _add(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = _mesh(_cube(size), color)
	m.position = pos
	add_child(m)
	return m


func _mesh(mesh: Mesh, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	return m


func _cube(size: Vector3) -> BoxMesh:
	var b: BoxMesh = BoxMesh.new()
	b.size = size
	return b


func _cylinder(r: float, h: float) -> CylinderMesh:
	var c: CylinderMesh = CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	return c
