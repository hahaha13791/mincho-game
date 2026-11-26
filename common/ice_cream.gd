class_name IceCream
extends Node3D
## 민트초코 아이스크림: 콘 + 민트 한 덩이 + 초코칩. 원점은 콘 가운데, 크기는 scale로 맞춘다.
## 표지판 사보타주 가게 지붕과 타이틀이 같이 쓴다.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CHIPS: Array[Vector3] = [Vector3(0.3, 0.25, 0.4), Vector3(-0.35, 0.1, 0.38), Vector3(0.05, 0.42, 0.35), Vector3(0.45, -0.05, 0.25)]


func _ready() -> void:
	var cone_mesh: CylinderMesh = CylinderMesh.new()
	cone_mesh.top_radius = 0.45
	cone_mesh.bottom_radius = 0.0
	cone_mesh.height = 1.0
	_part(cone_mesh, Vector3.ZERO, PALETTE.cardboard)
	var scoop_mesh: SphereMesh = SphereMesh.new()
	scoop_mesh.radius = 0.55
	scoop_mesh.height = 1.0
	var scoop: Vector3 = Vector3(0.0, 0.65, 0.0)
	_part(scoop_mesh, scoop, PALETTE.mincho)
	for chip in CHIPS:
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.14, 0.14, 0.14)
		_part(box, scoop + chip, PALETTE.chocolate)


func _part(mesh: Mesh, pos: Vector3, color: Color) -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material = mat
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	add_child(m)
