class_name Villager
extends Node3D
## 주민. 겉모습은 이 서브씬에만 있다. 로직은 setup()과 is_mincho만 쓴다.
## 모델은 assets/figure/figure.glb(하얀 인형 Body, 옷 Shirt, 모자 Hat, 애니메이션 walk/idle).

const PALETTE: Palette = preload("res://common/style/palette.tres")

var is_mincho: bool = true

@onready var _figure: Node3D = $Figure


func _ready() -> void:
	var anim: AnimationPlayer = _figure.find_child("AnimationPlayer", true, false)
	anim.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
	anim.play("walk")


## 옷 색은 is_mincho가 정한다. decoy_hat이면 반대 편 색 모자를 쓴다(헷갈리게 하는 단서, 판정에는 무관)
func setup(mincho: bool, decoy_hat: bool) -> void:
	is_mincho = mincho
	_part("Body").material_override = _mat(PALETTE.doll)
	_part("Shirt").material_override = _mat(PALETTE.mincho if mincho else PALETTE.anti_mincho)
	var hat: MeshInstance3D = _part("Hat")
	hat.visible = decoy_hat
	hat.material_override = _mat(PALETTE.anti_mincho if mincho else PALETTE.mincho)


func _part(part_name: String) -> MeshInstance3D:
	return _figure.find_child(part_name, true, false) as MeshInstance3D


func _mat(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	return m
