class_name Protagonist
extends Node3D
## 작전본부실의 주인공(민초단원). 겉모습은 이 서브씬에만 있다. 로직은 set_stage()와 act()만 쓴다.
## 끝낸 작전 수에 따라 복장이 바뀐다:
##   0~1개 민트 셔츠 / 2~3개 셔츠 대신 머리띠 / 4~5개 머리띠+완장 / 6개 중절모+깃 세운 초콜릿 코트(민트 배지)만
## 행동 애니메이션은 assets/figure/figure.glb의 think, point, coffee, map, phone, pin, magnifier, write.

const PALETTE: Palette = preload("res://common/style/palette.tres")
const HAND_BONE: String = "forearm.R"
const HAND_OFFSET: float = 0.31 # 팔꿈치에서 손까지(뼈 길이)

@onready var _figure: Node3D = $Figure


func _ready() -> void:
	FigureLook.play(_figure, "idle")


func set_stage(done: int) -> void:
	var outfit: Dictionary = {"Body": PALETTE.doll}
	if done >= GameState.MINIGAME_COUNT: # 비밀요원: 머리띠·완장은 벗는다
		outfit["Fedora"] = PALETTE.chocolate
		outfit["Coat"] = PALETTE.chocolate
		outfit["Badge"] = PALETTE.mincho
	elif done >= 2:
		outfit["Headband"] = PALETTE.mincho
		if done >= 4:
			outfit["Armband"] = PALETTE.mincho
	else:
		outfit["Shirt"] = PALETTE.mincho
	FigureLook.dress(_figure, outfit)


## 행동 애니메이션을 반복하고 오른손에 소품을 든다(prop이 비면 빈손)
func act(anim: String, prop: StringName) -> void:
	FigureLook.play(_figure, anim)
	if prop.is_empty():
		return
	var skeleton: Skeleton3D = _figure.find_child("Skeleton3D", true, false)
	var hand: BoneAttachment3D = BoneAttachment3D.new()
	hand.bone_name = HAND_BONE
	skeleton.add_child(hand)
	var holder: Node3D = Node3D.new() # 뼈 방향(+y)으로 손끝까지
	holder.position = Vector3(0, HAND_OFFSET, 0)
	hand.add_child(holder)
	_build_prop(holder, prop)


# 손에 드는 소품. 뼈의 +y가 손끝 방향
func _build_prop(at: Node3D, prop: StringName) -> void:
	match prop:
		&"pointer": # 지시봉: 손에서 앞으로 길게
			_part(at, _capsule(0.015, 0.9), Vector3(0, 0.4, 0), Vector3.ZERO, PALETTE.wood.darkened(0.3))
			_part(at, _sphere(0.03), Vector3(0, 0.85, 0), Vector3.ZERO, PALETTE.danger)
		&"mug":
			_part(at, _cylinder(0.07, 0.15), Vector3(0, 0.03, 0.06), Vector3(PI / 2.0, 0, 0), PALETTE.paper)
		&"phone": # 구식 수화기
			_part(at, _capsule(0.03, 0.26), Vector3(0, 0.05, 0.05), Vector3(0, 0, PI / 2.0), PALETTE.stamp)
		&"pin": # 핀을 쥔 손
			_part(at, _sphere(0.035), Vector3(0, 0.06, 0), Vector3.ZERO, PALETTE.danger)
		&"magnifier":
			_part(at, _capsule(0.02, 0.18), Vector3(0, 0.05, 0), Vector3.ZERO, PALETTE.wood.darkened(0.3))
			var ring: TorusMesh = TorusMesh.new()
			ring.inner_radius = 0.085
			ring.outer_radius = 0.105
			_part(at, ring, Vector3(0, 0.24, 0), Vector3(PI / 2.0, 0, 0), PALETTE.iron.lightened(0.2))
		&"pen":
			_part(at, _capsule(0.01, 0.16), Vector3(0, 0.04, 0.03), Vector3(0.6, 0, 0), PALETTE.stamp)


func _part(at: Node3D, mesh: Mesh, pos: Vector3, rot: Vector3, color: Color) -> void:
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	m.position = pos
	m.rotation = rot
	at.add_child(m)


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


func _sphere(r: float) -> SphereMesh:
	var s: SphereMesh = SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s
