extends Node
## 오토로드 `Flow`. 화면 전환 담당. 미니게임은 끝나면 go_hub()만 호출한다.

const HUB_SCENE: String = "res://main/hub.tscn"


func go_hub() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)


func start(entry: MinigameEntry) -> void:
	if entry.scene.is_empty():
		return
	get_tree().change_scene_to_file(entry.scene)
