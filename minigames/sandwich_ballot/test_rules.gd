extends SceneTree
## 실행: godot --headless --path . -s res://minigames/sandwich_ballot/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	_check(SandwichRules.evaluate(60, 100, 50) == SandwichRules.Outcome.OK, "목표 이상은 성공")
	_check(SandwichRules.evaluate(100, 100, 50) == SandwichRules.Outcome.OK, "딱 100장은 버스트 아님")
	_check(SandwichRules.evaluate(101, 100, 50) == SandwichRules.Outcome.BUST, "100장 초과는 버스트")
	_check(SandwichRules.evaluate(40, 100, 50) == SandwichRules.Outcome.LOW_GAIN, "목표 미달")
	_check(SandwichRules.judge(1, 3, 2, 90, 85) == Grade.Rank.CAUGHT, "성공 수 미달은 적발")
	_check(SandwichRules.judge(3, 3, 2, 90, 85) == Grade.Rank.PERFECT, "전부 성공+두툼하면 완전범죄")
	_check(SandwichRules.judge(3, 3, 2, 60, 85) == Grade.Rank.SUCCESS, "얇은 다발이 있으면 미션성공")
	_check(SandwichRules.judge(2, 3, 2, 95, 85) == Grade.Rank.SUCCESS, "하나 실패하면 미션성공")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
