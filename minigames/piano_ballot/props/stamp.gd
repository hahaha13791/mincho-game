extends Node3D
## 기표 도장(기표용구) 겉모습. 원점에서 0.5 아래가 도장면 바닥. 색은 노드 이름으로 팔레트에서 고른다.
## Ink = 인주 묻은 도장면, Metal = 금속 테, 나머지 = 몸통

const PALETTE: Palette = preload("res://common/style/palette.tres")


func _ready() -> void:
	for m in find_children("*", "MeshInstance3D", true, false):
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		if m.name.begins_with("Ink"):
			mat.albedo_color = PALETTE.danger
		elif m.name.begins_with("Metal"):
			mat.albedo_color = PALETTE.iron.lightened(0.3)
		else:
			mat.albedo_color = PALETTE.stamp
		(m as MeshInstance3D).material_override = mat
