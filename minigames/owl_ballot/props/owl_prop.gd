extends Node3D
## 엄폐물 겉모습 공용 스크립트. 색은 씬에 쓰지 않고, 메시 노드 이름 앞부분으로 팔레트 색을 고른다.
## Cardboard = 상자, Wood = 가구, Frame = 가구 다리·받침, Cloth = 테이블보, Paper = 종이

const PALETTE: Palette = preload("res://common/style/palette.tres")


func _ready() -> void:
	for m in find_children("*", "MeshInstance3D", true, false):
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = _color(m.name)
		(m as MeshInstance3D).material_override = mat


func _color(node_name: String) -> Color:
	if node_name.begins_with("Cardboard"):
		return PALETTE.cardboard
	if node_name.begins_with("Frame"):
		return PALETTE.furniture.darkened(0.35)
	if node_name.begins_with("Cloth"):
		return PALETTE.furniture.lightened(0.25)
	if node_name.begins_with("Paper"):
		return PALETTE.paper
	return PALETTE.furniture
