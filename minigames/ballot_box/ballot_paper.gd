class_name BallotPaper
extends RigidBody3D
## 접힌 표 한 장. 몸 중심 기준 직사각형(Rect2) 조각을 이어 붙인 모양. 평면(z=0)에서만 움직인다.

const DEPTH: float = 0.5

var rects: Array = []


func setup(shape: Array, color: Color) -> void:
	rects = shape
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	var pm: PhysicsMaterial = PhysicsMaterial.new()
	pm.friction = 0.7
	pm.bounce = 0.0
	physics_material_override = pm
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	for r: Rect2 in rects:
		var center: Vector3 = Vector3(r.get_center().x, r.get_center().y, 0.0)
		var col: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(r.size.x, r.size.y, DEPTH)
		col.shape = box
		col.position = center
		add_child(col)
		var m: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = box.size
		mesh.material = mat
		m.mesh = mesh
		m.position = center
		add_child(m)


## 월드 좌표 점이 이 표 위인지 (집을 때 사용)
func contains(point: Vector3) -> bool:
	var local: Vector3 = to_local(point)
	for r: Rect2 in rects:
		if r.has_point(Vector2(local.x, local.y)):
			return true
	return false


## 현재 가장 높은 지점의 y (선 넘음 판정용)
func top_y() -> float:
	var top: float = -INF
	for r: Rect2 in rects:
		for corner: Vector2 in [r.position, r.end, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y)]:
			top = maxf(top, to_global(Vector3(corner.x, corner.y, 0.0)).y)
	return top
