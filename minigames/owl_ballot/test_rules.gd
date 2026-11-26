extends SceneTree
## 실행: godot --headless --path . -s res://minigames/owl_ballot/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


# 걸음 수 제한(S) 안에서 투표함을 다 처리하고, 불이 켜질 때마다 시야 밖에 있을 수 있는 경로가 있는가
func _solvable(cfg: OwlConfig) -> bool:
	var steps: int = int(cfg.dark_time / cfg.step_time)
	var states: Dictionary = {[OwlLevel.START, 0]: true} # [칸, 처리한 투표함 비트마스크]
	for cycle in range(1, cfg.cycles + 1):
		var seen: Array[Vector2i] = OwlRules.all_vision(OwlLevel.map(), OwlLevel.WATCHERS, cycle)
		var frontier: Dictionary = states.duplicate()
		var reach: Dictionary = states.duplicate()
		for s in steps:
			var nxt: Dictionary = {}
			for k in frontier:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var c: Vector2i = k[0] + d
					if OwlRules.is_wall(OwlLevel.map(), c):
						continue
					var mask: int = k[1]
					var bi: int = OwlLevel.BOXES.find(c)
					if bi >= 0:
						mask |= 1 << bi
					var key: Array = [c, mask]
					if not reach.has(key):
						reach[key] = true
						nxt[key] = true
			frontier = nxt
		var survive: Dictionary = {}
		for k in reach:
			if k[1] == (1 << OwlLevel.BOXES.size()) - 1:
				return true
			if not seen.has(k[0]):
				survive[k] = true
		states = survive
	return false


# 엄폐물이 맵 안에 있고, 서로 겹치지 않고, 시작점·투표함·감시자 자리를 덮지 않는다
func _check_pieces(map: Array[String]) -> void:
	var used: Dictionary = {}
	for p in OwlLevel.PIECES:
		for c in OwlLevel.cells(p):
			_check(c.x >= 0 and c.y >= 0 and c.x < OwlLevel.SIZE.x and c.y < OwlLevel.SIZE.y, "엄폐물이 맵 밖 %s" % c)
			_check(not used.has(c), "엄폐물 겹침 %s" % c)
			used[c] = true
	var keep: Array[Vector2i] = [OwlLevel.START]
	keep.append_array(OwlLevel.BOXES)
	for wd in OwlLevel.WATCHERS:
		for c in wd["path"]:
			keep.append(c)
	for c in keep:
		_check(not OwlRules.is_wall(map, c), "엄폐물이 막으면 안 되는 칸 %s" % c)


func _init() -> void:
	var map: Array[String] = OwlLevel.map()
	_check(map.size() == OwlLevel.SIZE.y and map[0].length() == OwlLevel.SIZE.x, "맵 크기")
	var l_cells: Array[Vector2i] = OwlLevel.cells({"kind": &"partition", "at": Vector2i(10, 1), "rot": 1})
	_check(l_cells == [Vector2i(10, 1), Vector2i(10, 2), Vector2i(9, 1)], "ㄱ자 회전")
	_check(OwlRules.is_wall(map, Vector2i(2, 1)), "엄폐물 칸은 벽")
	_check(OwlRules.is_wall(map, Vector2i(-1, 0)), "맵 밖은 벽")
	_check(not OwlRules.is_wall(map, Vector2i(0, 0)), "바닥은 벽 아님")
	_check_pieces(map)
	var path0: Array = OwlLevel.WATCHERS[0]["path"]
	var w: Dictionary = OwlRules.watcher_at(path0, 0)
	_check(w["pos"] == path0[0] and w["dir"] == Vector2i((path0[1] - path0[0]).sign()), "감시자 첫 위치와 방향")
	_check(OwlRules.watcher_at(path0, path0.size())["pos"] == path0[0], "경로는 순환")
	var v: Array[Vector2i] = OwlRules.vision(map, Vector2i(8, 5), Vector2i(0, 1), 2)
	_check(v == [Vector2i(8, 5), Vector2i(8, 6), Vector2i(8, 7)], "시야는 감시자 칸 + range칸")
	var blocked: Array[Vector2i] = OwlRules.vision(map, Vector2i(2, 0), Vector2i(0, 1), 3)
	_check(blocked == [Vector2i(2, 0)], "엄폐물에서 시야가 끊김")
	_check(not OwlRules.is_near(Vector2i(10, 5), v), "시야에서 두 칸 떨어지면 들킬 뻔한 것 아님")
	_check(OwlRules.is_near(Vector2i(9, 5), v), "시야 바로 옆은 들킬 뻔함")
	_check(OwlRules.judge(false, false) == Grade.Rank.CAUGHT, "미완료는 적발")
	_check(OwlRules.judge(true, false) == Grade.Rank.PERFECT, "무사 완료는 완전범죄")
	_check(OwlRules.judge(true, true) == Grade.Rank.SUCCESS, "들킬 뻔했으면 미션성공")
	_check(_solvable(OwlConfig.new()), "기본 설정으로 클리어 가능한 경로가 있다")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
