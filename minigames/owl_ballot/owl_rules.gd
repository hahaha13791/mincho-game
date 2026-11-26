class_name OwlRules
extends RefCounted


static func is_wall(map: Array[String], c: Vector2i) -> bool:
	return c.y < 0 or c.y >= map.size() or c.x < 0 or c.x >= map[c.y].length() or map[c.y][c.x] == "#"


## 경로 한 칸의 위치. 칸은 Vector2i(다음 자리 쪽을 봄) 또는 [Vector2i 위치, Vector2i 바라볼 방향](제자리 두리번)
static func path_pos(entry: Variant) -> Vector2i:
	return entry[0] if entry is Array else entry


## 불이 cycle번째로 켜졌을 때 감시자 위치와 방향
static func watcher_at(path: Array, cycle: int) -> Dictionary:
	var entry: Variant = path[cycle % path.size()]
	var pos: Vector2i = path_pos(entry)
	if entry is Array:
		return {"pos": pos, "dir": entry[1]}
	for i in range(1, path.size()): # 위치가 다른 다음 칸 쪽을 본다(제자리 두리번 칸은 건너뜀)
		var nxt: Vector2i = path_pos(path[(cycle + i) % path.size()])
		if nxt != pos:
			return {"pos": pos, "dir": Vector2i((nxt - pos).sign())}
	return {"pos": pos, "dir": Vector2i.ZERO}


## 감시자 칸에서 dir 방향으로 range칸. 방해물에서 끊긴다. 감시자 칸 자체도 포함
static func vision(map: Array[String], pos: Vector2i, dir: Vector2i, range: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = [pos]
	for i in range:
		var c: Vector2i = pos + dir * (i + 1)
		if is_wall(map, c):
			break
		out.append(c)
	return out


static func all_vision(map: Array[String], watchers: Array[Dictionary], cycle: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for w in watchers:
		var s: Dictionary = watcher_at(w["path"], cycle)
		out.append_array(vision(map, s["pos"], s["dir"], w["range"]))
	return out


## 시야 바로 옆 칸이면 들킬 뻔한 것
static func is_near(cell: Vector2i, seen: Array[Vector2i]) -> bool:
	for s in seen:
		if absi(s.x - cell.x) + absi(s.y - cell.y) == 1:
			return true
	return false


## done = 모든 투표함 처리, near_missed = 불이 켜질 때 시야 옆에 있었던 적이 있음
static func judge(done: bool, near_missed: bool) -> Grade.Rank:
	if not done:
		return Grade.Rank.CAUGHT
	return Grade.Rank.SUCCESS if near_missed else Grade.Rank.PERFECT
