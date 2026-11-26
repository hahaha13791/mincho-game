class_name OwlLevel
extends RefCounted
## 고정 맵. 좌표는 Vector2i(열, 행). 엄폐물(PIECES)이 놓인 칸은 이동과 시야를 모두 막는다.

const SIZE: Vector2i = Vector2i(15, 9)
## 엄폐물 모양: 기준 칸(0,0)에서의 칸 목록. rot은 90도 단위 회전 횟수 (x, y) -> (-y, x)
const SHAPES: Dictionary = {
	&"crates": [Vector2i(0, 0)], # 1x1 투표함 운반 상자 더미
	&"table": [Vector2i(0, 0), Vector2i(1, 0)], # 2x1 개표 테이블
	&"partition": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], # ㄱ자 칸막이 코너. (0,0)이 꺾인 곳
}
## 열 7과 행 4는 감시자 순찰 통로로 비워 두고, 나머지 네 구역에 엄폐물과 투표함을 하나씩 나눠 둔다
const PIECES: Array[Dictionary] = [
	# 왼쪽 위
	{"kind": &"crates", "at": Vector2i(2, 1), "rot": 0},
	{"kind": &"crates", "at": Vector2i(6, 0), "rot": 0},
	{"kind": &"table", "at": Vector2i(4, 2), "rot": 0}, # (4,2),(5,2)
	{"kind": &"partition", "at": Vector2i(1, 3), "rot": 3}, # (1,3),(1,2),(2,3)
	# 오른쪽 위
	{"kind": &"partition", "at": Vector2i(9, 1), "rot": 0}, # (9,1),(10,1),(9,2)
	{"kind": &"table", "at": Vector2i(12, 0), "rot": 0}, # (12,0),(13,0)
	{"kind": &"crates", "at": Vector2i(13, 2), "rot": 0},
	{"kind": &"table", "at": Vector2i(11, 3), "rot": 0}, # (11,3),(12,3)
	# 왼쪽 아래
	{"kind": &"table", "at": Vector2i(1, 6), "rot": 1}, # (1,6),(1,7)
	{"kind": &"crates", "at": Vector2i(3, 5), "rot": 0},
	{"kind": &"partition", "at": Vector2i(5, 7), "rot": 2}, # (5,7),(4,7),(5,6)
	# 오른쪽 아래
	{"kind": &"table", "at": Vector2i(9, 6), "rot": 1}, # (9,6),(9,7)
	{"kind": &"crates", "at": Vector2i(11, 5), "rot": 0},
	{"kind": &"crates", "at": Vector2i(14, 5), "rot": 0},
	{"kind": &"partition", "at": Vector2i(12, 7), "rot": 3}, # (12,7),(12,6),(13,7)
	{"kind": &"table", "at": Vector2i(10, 8), "rot": 0}, # (10,8),(11,8)
]
const START: Vector2i = Vector2i(0, 0)
const BOXES: Array[Vector2i] = [Vector2i(5, 1), Vector2i(10, 2), Vector2i(2, 7), Vector2i(11, 6)]
## 감시자: path = 불이 켜질 때마다 다음 칸(순환), range = 시야 칸 수.
## 칸이 Vector2i면 다음 자리 쪽을 보고, [위치, 방향]이면 그 자리에서 그 방향을 둘러본다(두리번)
const E: Vector2i = Vector2i(1, 0)
const W: Vector2i = Vector2i(-1, 0)
const N: Vector2i = Vector2i(0, -1)
const S: Vector2i = Vector2i(0, 1)
const WATCHERS: Array[Dictionary] = [
	# 세로 통로: 가운데 교차점에서 내려갈 땐 오른쪽, 올라올 땐 왼쪽을 둘러본다
	{"path": [Vector2i(7, 0), Vector2i(7, 2), Vector2i(7, 4), [Vector2i(7, 4), E], Vector2i(7, 6), Vector2i(7, 8), Vector2i(7, 6), Vector2i(7, 4), [Vector2i(7, 4), W], Vector2i(7, 2)], "range": 3},
	# 가로 통로: 가운데쯤에서 갈 땐 위, 올 땐 아래를 둘러본다
	{"path": [Vector2i(0, 4), Vector2i(3, 4), Vector2i(6, 4), [Vector2i(6, 4), N], Vector2i(9, 4), Vector2i(12, 4), Vector2i(9, 4), Vector2i(6, 4), [Vector2i(6, 4), S], Vector2i(3, 4)], "range": 3},
	# 아래 통로: 투표함 쪽 위를 한 번 둘러본다
	{"path": [Vector2i(0, 8), Vector2i(3, 8), [Vector2i(3, 8), N], Vector2i(6, 8), Vector2i(3, 8)], "range": 3},
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
