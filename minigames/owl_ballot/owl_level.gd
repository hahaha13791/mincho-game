class_name OwlLevel
extends RefCounted
## 고정 맵. 좌표는 Vector2i(열, 행). 엄폐물(PIECES)이 놓인 칸은 이동과 시야를 모두 막는다.

const SIZE: Vector2i = Vector2i(13, 9)
## 엄폐물 모양: 기준 칸(0,0)에서의 칸 목록. rot은 90도 단위 회전 횟수 (x, y) -> (-y, x)
const SHAPES: Dictionary = {
	&"crates": [Vector2i(0, 0)], # 1x1 투표함 운반 상자 더미
	&"table": [Vector2i(0, 0), Vector2i(1, 0)], # 2x1 개표 테이블
	&"partition": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], # ㄱ자 칸막이 코너. (0,0)이 꺾인 곳
}
const PIECES: Array[Dictionary] = [
	{"kind": &"crates", "at": Vector2i(3, 1), "rot": 0},
	{"kind": &"crates", "at": Vector2i(12, 3), "rot": 0},
	{"kind": &"crates", "at": Vector2i(2, 6), "rot": 0},
	{"kind": &"crates", "at": Vector2i(10, 7), "rot": 0},
	{"kind": &"table", "at": Vector2i(1, 3), "rot": 0},
	{"kind": &"table", "at": Vector2i(5, 3), "rot": 0},
	{"kind": &"table", "at": Vector2i(9, 5), "rot": 1}, # (9,5),(9,6)
	{"kind": &"partition", "at": Vector2i(4, 5), "rot": 0}, # (4,5),(5,5),(4,6)
	{"kind": &"partition", "at": Vector2i(10, 1), "rot": 1}, # (10,1),(10,2),(9,1)
]
const START: Vector2i = Vector2i(0, 0)
const BOXES: Array[Vector2i] = [Vector2i(6, 2), Vector2i(11, 5), Vector2i(1, 7), Vector2i(5, 6)]
## 감시자: path = 불이 켜질 때마다 다음 위치(순환), range = 시야 칸 수. 바라보는 방향 = 다음 위치 쪽
const WATCHERS: Array[Dictionary] = [
	{"path": [Vector2i(7, 0), Vector2i(7, 2), Vector2i(7, 4), Vector2i(7, 6), Vector2i(7, 8), Vector2i(7, 6), Vector2i(7, 4), Vector2i(7, 2)], "range": 3},
	{"path": [Vector2i(0, 4), Vector2i(3, 4), Vector2i(6, 4), Vector2i(9, 4), Vector2i(12, 4), Vector2i(9, 4), Vector2i(6, 4), Vector2i(3, 4)], "range": 3},
]

static var _map: Array[String] = []


static func cells(piece: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for o in SHAPES[piece["kind"]]:
		var c: Vector2i = o
		for i in int(piece["rot"]) % 4:
			c = Vector2i(-c.y, c.x)
		out.append(piece["at"] + c)
	return out


## OwlRules가 쓰는 문자열 맵('#' 막힘, '.' 바닥)
static func map() -> Array[String]:
	if _map.is_empty():
		var rows: Array[PackedStringArray] = []
		for r in SIZE.y:
			var row: PackedStringArray = PackedStringArray()
			row.resize(SIZE.x)
			row.fill(".")
			rows.append(row)
		for p in PIECES:
			for c in cells(p):
				rows[c.y][c.x] = "#"
		for row in rows:
			_map.append("".join(row))
	return _map
