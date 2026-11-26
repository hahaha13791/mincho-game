class_name OwlBallotBox
extends Node3D
## 올빼미표 투표함 겉모습. 로직은 set_done()만 쓴다. 처리하면 몸통이 민초색이 된다.

const PALETTE: Palette = preload("res://common/style/palette.tres")

@onready var _body: MeshInstance3D = $Body


func _ready() -> void:
	$Band.material_override = _mat(PALETTE.paper)
	$Slot.material_override = _mat(PALETTE.burnt)
	$Label.modulate = PALETTE.paper
	$Label.outline_modulate = PALETTE.paper # 같은 색 외곽선으로 글씨를 굵게
	set_done(false)


func set_done(done: bool) -> void:
	_body.material_override = _mat(PALETTE.mincho if done else PALETTE.ballot_box)


func _mat(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	return m
