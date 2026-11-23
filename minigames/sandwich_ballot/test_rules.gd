extends SceneTree
## 실행: godot --headless --path . -s res://minigames/sandwich_ballot/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	var ok: Array[bool] = [true, false, false, false, true]
	var bad_top: Array[bool] = [true, false, false]
	var thin: Array[bool] = [true, false, true]
	var fat: Array[bool] = []
	fat.resize(21)
	fat.fill(false)
	fat[0] = true
	fat[-1] = true
	_check(SandwichRules.gain(ok, 5) == 15, "가운데 반민초 3묶음 = 15장")
	_check(SandwichRules.gain(bad_top, 5) == 0, "맨 위가 반민초면 이득 0")
	_check(SandwichRules.evaluate(ok, 5, 100, 10) == SandwichRules.Outcome.OK, "정상 닫기")
	_check(SandwichRules.evaluate(bad_top, 5, 100, 10) == SandwichRules.Outcome.BAD_ENDS, "맨 위 반민초")
	_check(SandwichRules.evaluate(thin, 5, 100, 10) == SandwichRules.Outcome.LOW_GAIN, "이득 부족")
	_check(SandwichRules.evaluate(fat, 5, 100, 10) == SandwichRules.Outcome.BUST, "100장 초과는 버스트")
	_check(SandwichRules.judge(1, 3, 2, 90, 80) == Grade.Rank.CAUGHT, "성공 수 미달은 적발")
	_check(SandwichRules.judge(3, 3, 2, 85, 80) == Grade.Rank.PERFECT, "전부 성공+두툼하면 완전범죄")
	_check(SandwichRules.judge(3, 3, 2, 60, 80) == Grade.Rank.SUCCESS, "얇은 다발이 있으면 미션성공")
	_check(SandwichRules.judge(2, 3, 2, 95, 80) == Grade.Rank.SUCCESS, "하나 실패하면 미션성공")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
