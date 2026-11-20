class_name PackingGrid
extends RefCounted
## 투표함 안쪽 격자. 칸 점유만 관리한다 (노드 없음).

var width: int
var height: int
var _cells: Dictionary = {} # Vector2i -> piece id


func _init(w: int, h: int) -> void:
	width = w
	height = h


func can_place(shape: Array, origin: Vector2i) -> bool:
	for c: Vector2i in shape:
		var p: Vector2i = origin + c
		if p.x < 0 or p.y < 0 or p.x >= width or p.y >= height or _cells.has(p):
			return false
	return true


func place(shape: Array, origin: Vector2i, piece_id: int) -> void:
	assert(can_place(shape, origin))
	for c: Vector2i in shape:
		_cells[origin + c] = piece_id


func remove(piece_id: int) -> void:
	for p: Vector2i in _cells.keys():
		if _cells[p] == piece_id:
			_cells.erase(p)


func filled() -> int:
	return _cells.size()


## 시계 방향 90도 회전 후 최소 좌표를 0으로 맞춘다 (입력은 최소 좌표가 0이어야 한다)
static func rotated(shape: Array) -> Array:
	var out: Array = []
	var min_x: int = 0
	for c: Vector2i in shape:
		var r: Vector2i = Vector2i(-c.y, c.x)
		out.append(r)
		min_x = mini(min_x, r.x)
	for i in out.size():
		out[i] += Vector2i(-min_x, 0)
	return out
