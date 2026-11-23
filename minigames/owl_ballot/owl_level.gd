class_name OwlLevel
extends RefCounted
## 고정 맵. '#' 방해물, '.' 바닥. 좌표는 Vector2i(열, 행)

const MAP: Array[String] = [
	".........",
	".#..#..#.",
	".........",
	".#..#....",
	".........",
	".#..#..#.",
	".........",
]
const START: Vector2i = Vector2i(0, 0)
const BOXES: Array[Vector2i] = [Vector2i(3, 2), Vector2i(6, 3), Vector2i(3, 5)]
## 감시자: path = 불이 켜질 때마다 한 칸씩 다음 위치(순환), range = 시야 칸 수. 바라보는 방향 = 다음 위치 쪽
const WATCHERS: Array[Dictionary] = [
	{"path": [Vector2i(5, 0), Vector2i(5, 2), Vector2i(5, 4), Vector2i(5, 6), Vector2i(5, 4), Vector2i(5, 2)], "range": 2},
	{"path": [Vector2i(0, 4), Vector2i(3, 4), Vector2i(6, 4), Vector2i(8, 4), Vector2i(6, 4), Vector2i(3, 4)], "range": 3},
]
