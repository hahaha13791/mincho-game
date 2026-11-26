extends Node3D
## 표에 찍힌 기표 자국: 동그라미 안의 '卜'. ink는 add_child 전에 정한다(기본 인주색).

const PALETTE: Palette = preload("res://common/style/palette.tres")

@export var ink: Color = PALETTE.danger # export여야 duplicate()로 복사할 때 색이 따라간다


func _ready() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = ink
	$Ring.material_override = mat
	$Glyph.rotation.x = -PI / 2.0 # 눕혀서 위를 보게. 글자 위쪽이 화면 위(-z)
	$Glyph.modulate = ink
	$Glyph.outline_modulate = ink


## 진하기(1 = 원래대로). 지워지다 만 옅은 기표에 쓴다
func set_alpha(a: float) -> void:
	var mat: StandardMaterial3D = $Ring.material_override
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.albedo_color.a = a
	$Glyph.modulate.a = a
	$Glyph.outline_modulate.a = a
