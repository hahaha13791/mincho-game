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
		var seen: Array[Vector2i] = OwlRules.all_vision(OwlLevel.MAP, OwlLevel.WATCHERS, cycle)
		var frontier: Dictionary = states.duplicate()
		var reach: Dictionary = states.duplicate()
		for s in steps:
			var nxt: Dictionary = {}
			for k in frontier:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var c: Vector2i = k[0] + d
					if OwlRules.is_wall(OwlLevel.MAP, c):
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


func _init() -> void:
	var map: Array[String] = OwlLevel.MAP
	_check(OwlRules.is_wall(map, Vector2i(1, 1)), "방해물은 벽")
	_check(OwlRules.is_wall(map, Vector2i(-1, 0)), "맵 밖은 벽")
	_check(not OwlRules.is_wall(map, Vector2i(0, 0)), "바닥은 벽 아님")
	var w: Dictionary = OwlRules.watcher_at(OwlLevel.WATCHERS[0]["path"], 0)
	_check(w["pos"] == Vector2i(5, 0) and w["dir"] == Vector2i(0, 1), "감시자 첫 위치와 방향")
	_check(OwlRules.watcher_at(OwlLevel.WATCHERS[0]["path"], 6)["pos"] == Vector2i(5, 0), "경로는 순환")
	var v: Array[Vector2i] = OwlRules.vision(map, Vector2i(5, 0), Vector2i(0, 1), 2)
	_check(v == [Vector2i(5, 0), Vector2i(5, 1), Vector2i(5, 2)], "시야는 감시자 칸 + range칸")
	var blocked: Array[Vector2i] = OwlRules.vision(map, Vector2i(4, 0), Vector2i(0, 1), 3)
	_check(blocked == [Vector2i(4, 0)], "방해물에서 시야가 끊김")
	_check(not OwlRules.is_near(Vector2i(7, 0), v), "시야에서 두 칸 떨어지면 들킬 뻔한 것 아님")
	_check(OwlRules.is_near(Vector2i(6, 1), v), "시야 바로 옆은 들킬 뻔함")
	_check(OwlRules.judge(false, false) == Grade.Rank.CAUGHT, "미완료는 적발")
	_check(OwlRules.judge(true, false) == Grade.Rank.PERFECT, "무사 완료는 완전범죄")
	_check(OwlRules.judge(true, true) == Grade.Rank.SUCCESS, "들킬 뻔했으면 미션성공")
	_check(_solvable(OwlConfig.new()), "기본 설정으로 클리어 가능한 경로가 있다")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
