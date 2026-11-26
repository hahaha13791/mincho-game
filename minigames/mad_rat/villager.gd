class_name Villager
extends Node3D
## 주민. 겉모습은 이 서브씬에만 있다. 로직은 setup()과 is_mincho만 쓴다.

const PALETTE: Palette = preload("res://common/style/palette.tres")

var is_mincho: bool = true

@onready var _outfit: Node3D = $Outfit # 옷 파츠(셔츠, 소매)는 모두 이 아래에 둔다
@onready var _hat: MeshInstance3D = $Hat


## 옷 색은 is_mincho가 정한다. decoy_hat이면 반대 편 색 모자를 쓴다(헷갈리게 하는 단서, 판정에는 무관)
func setup(mincho: bool, decoy_hat: bool) -> void:
	is_mincho = mincho
	$Body.material_override = _mat(PALETTE.doll)
	var cloth: StandardMaterial3D = _mat(PALETTE.mincho if mincho else PALETTE.anti_mincho)
	for part in _outfit.get_children():
		(part as MeshInstance3D).material_override = cloth
	_hat.visible = decoy_hat
	_hat.material_override = _mat(PALETTE.anti_mincho if mincho else PALETTE.mincho)


func _mat(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	return m
