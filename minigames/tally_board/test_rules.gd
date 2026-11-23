extends SceneTree
## 실행: godot --headless --path . -s res://minigames/tally_board/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	var cfg: TallyConfig = TallyConfig.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var b: Dictionary = TallyRules.make_board(cfg, rng)
	var m: Array[int] = b["m"]
	var a: Array[int] = b["a"]
	var s: Array[int] = []
	for i in m.size():
		s.append(m[i] + a[i])
	var tm: int = m.reduce(func(x: int, y: int) -> int: return x + y, 0)
	var ta: int = a.reduce(func(x: int, y: int) -> int: return x + y, 0)
	var v: int = tm + ta
	_check(TallyRules.check(s, v, m, a, tm, ta) == TallyRules.Failure.NONE, "처음 칠판은 검산 통과")

	var m2: Array[int] = m.duplicate()
	m2[0] += 1
	_check(TallyRules.check(s, v, m2, a, tm, ta) == TallyRules.Failure.ROW, "한 칸만 올리면 반별 합 불일치")
	var a2: Array[int] = a.duplicate()
	a2[0] -= 1
	_check(TallyRules.check(s, v, m2, a2, tm, ta) == TallyRules.Failure.TOTAL, "반만 맞추면 맨 아랫줄 불일치")
	_check(TallyRules.check(s, v, m2, a2, tm + 1, ta - 1) == TallyRules.Failure.NONE, "4칸을 맞춰 고치면 통과")
	_check(TallyRules.check(s, v, m2, a2, tm + 1, ta) == TallyRules.Failure.TOTAL, "맨 아랫줄 한 칸만 고치면 불일치")
	_check(TallyRules.check(s, v + 1, m, a, tm, ta) == TallyRules.Failure.VOTERS, "투표자 수가 다르면 불일치")

	var bm: Array[int] = [20, 30, 40, 25]
	var ba: Array[int] = [40, 50, 60, 80]
	_check(TallyRules.cap(20, 0.2) == 4 and TallyRules.cap(2, 0.2) == 1, "허용 폭은 최소 1")
	_check(TallyRules.best_gain(bm, ba, 0.2, 6) == 14, "6칸이면 두 반(8+6)이 최대")
	_check(TallyRules.best_gain(bm, ba, 0.2, 3) == 0, "3칸이면 한 반도 못 고침")
	_check(TallyRules.judge(TallyRules.Failure.ROW, 14, 14, 0.9, 0.5) == Grade.Rank.CAUGHT, "검산 실패는 적발")
	_check(TallyRules.judge(TallyRules.Failure.NONE, 13, 14, 0.9, 0.5) == Grade.Rank.PERFECT, "최대의 90% 이상은 완전범죄")
	_check(TallyRules.judge(TallyRules.Failure.NONE, 7, 14, 0.9, 0.5) == Grade.Rank.SUCCESS, "50% 이상은 미션성공")
	_check(TallyRules.judge(TallyRules.Failure.NONE, 6, 14, 0.9, 0.5) == Grade.Rank.CAUGHT, "미달은 적발")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
