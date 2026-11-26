extends Node3D
## 표에 찍힌 기표 자국: 동그라미 안의 '卜'. ink는 add_child 전에 정한다(기본 인주색).

const PALETTE: Palette = preload("res://common/style/palette.tres")

var ink: Color = PALETTE.danger


func _ready() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = ink
	$Ring.material_override = mat
	$Glyph.rotation.x = -PI / 2.0 # 눕혀서 위를 보게. 글자 위쪽이 화면 위(-z)
	$Glyph.modulate = ink
	$Glyph.outline_modulate = ink
