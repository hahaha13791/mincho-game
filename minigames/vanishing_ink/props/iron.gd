extends Node3D
## 다리미 겉모습. 로직은 위치만 옮긴다. 원점 = 예전 상자 중심, 바닥판 밑면 = 원점에서 0.3 아래.
## 앞(뾰족한 쪽)이 -x. 바닥판은 종이 안쪽(3.5 x 2.5)을 덮어 기표를 가린다. 색은 팔레트에서만.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const BOTTOM: float = -0.3
# 바닥판 윤곽(위에서 본 모양, x = 앞뒤, y = 좌우). 앞이 뾰족하고 뒤 모서리는 둥글게
const SOLE: PackedVector2Array = [
	Vector2(-1.95, 0.0), Vector2(-0.5, -1.32), Vector2(1.6, -1.32), Vector2(1.8, -1.2), Vector2(1.85, -1.0),
	Vector2(1.85, 1.0), Vector2(1.8, 1.2), Vector2(1.6, 1.32), Vector2(-0.5, 1.32),
]


func _ready() -> void:
	var metal: Color = PALETTE.iron.lightened(0.35)
	var body: Color = PALETTE.iron_body
	var dark: Color = PALETTE.stamp
	var handle: Color = PALETTE.iron_body.darkened(0.35)
	_slab(SOLE, 1.0, BOTTOM, 0.14, metal) # 금속 바닥판
	_slab(SOLE, 0.94, BOTTOM + 0.14, 0.05, dark) # 몸체와 바닥판 사이 줄
	_slab(SOLE, 0.94, BOTTOM + 0.19, 0.45, body) # 몸체 아래층
	_slab(SOLE, 0.74, BOTTOM + 0.64, 0.3, body) # 몸체 위층(계단식으로 좁아짐)
	# 손잡이: 뒤 기둥 + 앞 기둥 + 둥근 손잡이
	_part(_box(Vector3(0.4, 0.7, 0.42)), Vector3(1.05, BOTTOM + 1.25, 0), handle)
	var front_post: MeshInstance3D = _part(_box(Vector3(0.28, 0.75, 0.34)), Vector3(-0.6, BOTTOM + 1.2, 0), handle)
	front_post.rotation.z = -0.35
	var grip: MeshInstance3D = _part(_capsule(0.22, 2.1), Vector3(0.25, BOTTOM + 1.65, 0), handle)
	grip.rotation.z = PI / 2.0 # 앞뒤로 눕힘
	# 온도 다이얼과 전선
	_part(_cylinder(0.24, 0.08), Vector3(0.35, BOTTOM + 0.98, 0), PALETTE.paper)
	_part(_box(Vector3(0.06, 0.03, 0.26)), Vector3(0.35, BOTTOM + 1.03, 0), dark) # 다이얼 눈금
	var cord: MeshInstance3D = _part(_capsule(0.06, 1.4), Vector3(1.9, BOTTOM + 0.55, 0), dark)
	cord.rotation.z = PI / 2.0 + 0.25


## 바닥 윤곽을 scale배 한 다각형을 y부터 위로 h만큼 밀어 올린 판
func _slab(outline: PackedVector2Array, scale: float, y: float, h: float, color: Color) -> void:
	var p: PackedVector2Array = PackedVector2Array()
	for v in outline:
		p.append(v * scale)
	var slab: CSGPolygon3D = CSGPolygon3D.new()
	slab.polygon = p
	slab.depth = h
	slab.rotation.x = PI / 2.0 # 다각형을 바닥에 눕히고 위로 밀어 올린다
	slab.position.y = y
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	slab.material = mat
	add_child(slab)


func _part(mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	m.position = pos
	add_child(m)
	return m


func _box(size: Vector3) -> BoxMesh:
	var b: BoxMesh = BoxMesh.new()
	b.size = size
	return b


func _capsule(r: float, h: float) -> CapsuleMesh:
	var c: CapsuleMesh = CapsuleMesh.new()
	c.radius = r
	c.height = h
	return c


func _cylinder(r: float, h: float) -> CylinderMesh:
	var c: CylinderMesh = CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	return c
