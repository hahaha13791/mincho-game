extends Node3D
## 표에 찍힌 기표 자국: 동그라미 안의 '卜'. 인주색.

const PALETTE: Palette = preload("res://common/style/palette.tres")


func _ready() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = PALETTE.danger
	$Ring.material_override = mat
	$Glyph.rotation.x = -PI / 2.0 # 눕혀서 위를 보게. 글자 위쪽이 화면 위(-z)
	$Glyph.modulate = PALETTE.danger
	$Glyph.outline_modulate = PALETTE.danger
