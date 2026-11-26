class_name PeekWatcher
extends Node3D
## 화면 가장자리에서 비스듬히 들이미는 감시자 상반신(허리 위만). 카메라의 자식으로 붙인다.
## 로직은 set_rise()와 next_entry()만 쓴다. 허리 축을 매번 실제 화면 가장자리에 두므로 창 비율이 바뀌어도(stretch aspect = expand) 허리 아래는 늘 화면 밖이다.

const WATCHER: PackedScene = preload("res://common/watcher.tscn")
const PEEK: float = 0.25 ## 예고 때 쓰는 rise 값(머리 끝만 보임)
const DEPTH: float = 3.0 # 카메라 앞 거리
const TUCK: float = 0.135 # 다 들어와도 허리를 가장자리 밖에 두는 거리(크기 비율). 몸이 기울어 엉덩이 모서리가 비치지 않게
const HIDE_MARGIN: float = 0.075 # 숨었을 때 머리 끝을 가장자리 밖으로 더 빼는 거리(크기 비율)
## 등장 방향: edge = 화면 가장자리 위 축 자리(가로·세로 반폭 기준 비율), angle = 축 회전(라디안). 몸 방향 = (-sin, cos)
const ENTRIES: Array[Dictionary] = [
	{"edge": Vector2(0.62, -1.0), "angle": 0.3}, # 오른쪽 아래에서 왼쪽 위로
	{"edge": Vector2(-0.6, 1.0), "angle": PI + 0.45}, # 왼쪽 위에서 오른쪽 아래로(거꾸로 매달려 내려다봄)
	{"edge": Vector2(1.0, 0.25), "angle": PI / 2.0 + 0.35}, # 오른쪽 옆에서 왼쪽 아래로
	{"edge": Vector2(-1.0, -0.1), "angle": -PI / 2.0 - 0.3}, # 왼쪽 옆에서 오른쪽 아래로
]

@export var screen_frac: float = 0.67 ## 허리 → 머리 끝이 화면 세로의 이 비율

var _watcher: Watcher
var _heights: Vector2 # 크기 1에서 (허리, 머리 끝) 높이
var _entry: int = 0


func _ready() -> void:
	_watcher = WATCHER.instantiate()
	add_child(_watcher)
	_watcher.set_present(true) # 서브씬은 숨은 채 시작한다. 등장은 화면 밖에 두었다가 들이미는 것으로 한다
	_heights = _watcher.body_heights()
	set_rise(0.0)


## 다음 등장 방향으로 바꾼다(차례로 돈다)
func next_entry() -> void:
	_entry = (_entry + 1) % ENTRIES.size()


## rise: 0 = 숨음, PEEK = 머리 끝만, 1 = 허리 위가 다 들어옴
func set_rise(rise: float) -> void:
	var cam: Camera3D = get_parent()
	var half_h: float = cam.size / 2.0 if cam.projection == Camera3D.PROJECTION_ORTHOGONAL else DEPTH * tan(deg_to_rad(cam.fov) / 2.0)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var half_w: float = half_h * vp.x / vp.y # 카메라 keep_aspect 기본값(세로 고정) 기준
	var s: float = screen_frac * 2.0 * half_h / (_heights.y - _heights.x)
	_watcher.scale = Vector3.ONE * s
	_watcher.position.y = -_heights.x * s # 허리가 이 노드의 원점
	var e: Dictionary = ENTRIES[_entry]
	var angle: float = e["angle"]
	var edge: Vector2 = e["edge"]
	var body_dir: Vector3 = Vector3(-sin(angle), cos(angle), 0.0) # 허리 → 머리
	var hidden: float = -((_heights.y - _heights.x) * s + HIDE_MARGIN * s)
	position = Vector3(edge.x * half_w, edge.y * half_h, -DEPTH) + body_dir * lerpf(hidden, -TUCK * s, rise)
	rotation.z = angle
