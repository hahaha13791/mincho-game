extends Node
## 오토로드 `Flow`. 화면 전환 담당. 미니게임은 끝나면 go_hub()만 호출한다.

const TITLE_SCENE: String = "res://main/title.tscn"
const HUB_SCENE: String = "res://main/hub.tscn"
const FINAL_SCENE: String = "res://main/final_count.tscn"
const LEADERBOARD_SCENE: String = "res://main/leaderboard.tscn"
const MINIGAMES_DIR: String = "res://minigames/"

var leaderboard_from: String = "" # 리더보드를 연 화면. 돌아가기가 여기로 간다
var _back: Button # 미니게임 중에만 보이는 '작전본부실로' 버튼


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 50 # 튜토리얼·결과 화면 위, 자동 복귀 안내 아래
	add_child(layer)
	_back = Button.new()
	_back.text = "작전본부실로"
	_back.focus_mode = Control.FOCUS_NONE # Space·Enter는 게임 조작이라 이 버튼이 먹지 않게
	_back.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_back.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_back.offset_left = -40.0 # 오른쪽 위 HUD 글자 아래. 글자 길이만큼 왼쪽으로 자란다
	_back.offset_right = -40.0
	_back.offset_top = 110.0
	_back.offset_bottom = 110.0
	_back.pressed.connect(go_hub)
	_back.hide()
	layer.add_child(_back)


func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	_back.visible = scene != null and scene.scene_file_path.begins_with(MINIGAMES_DIR)


func go_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)


func go_hub() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)


func start(entry: MinigameEntry) -> void:
	if entry.scene.is_empty():
		return
	get_tree().change_scene_to_file(entry.scene)


func go_final() -> void:
	get_tree().change_scene_to_file(FINAL_SCENE)


func go_leaderboard() -> void:
	var scene: Node = get_tree().current_scene
	leaderboard_from = scene.scene_file_path if scene != null else ""
	get_tree().change_scene_to_file(LEADERBOARD_SCENE)
