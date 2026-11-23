extends Node
## 오토로드 `IdleReturn`. 전시용: 입력이 없는 채로 idle_limit초가 지나면 타이틀로 돌아간다(타이틀이 득표와 등급을 초기화).
## 마지막 warn_time초 동안은 화면에 카운트다운을 보여주고, 마우스나 키 입력이 있으면 취소된다.

signal returned

var idle_limit: float = 90.0
var warn_time: float = 10.0

var _idle: float = 0.0
var _label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.position = Vector2(-300.0, 20.0)
	_label.custom_minimum_size = Vector2(600.0, 0.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 36)
	_label.hide()
	layer.add_child(_label)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		_idle = 0.0


func _process(delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null or scene.scene_file_path == Flow.TITLE_SCENE:
		_idle = 0.0 # 타이틀은 이미 처음 화면
	else:
		_idle += delta
	var left: float = idle_limit - _idle
	_label.visible = _idle > 0.0 and left <= warn_time
	if _label.visible:
		_label.text = "입력이 없어 %d초 뒤 처음 화면으로 돌아갑니다" % ceili(left)
	if _idle >= idle_limit:
		_idle = 0.0
		_label.hide()
		returned.emit()
		Flow.go_title()
