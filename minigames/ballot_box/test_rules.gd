extends SceneTree
## 실행: godot --headless --path . -s res://minigames/ballot_box/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	_check(BallotBoxRules.judge(5, 6, false, 5.0, 1.0) == Grade.Rank.CAUGHT, "장수 미달은 적발")
	_check(BallotBoxRules.judge(6, 6, true, 5.0, 1.0) == Grade.Rank.CAUGHT, "선을 넘으면 적발")
	_check(BallotBoxRules.judge(6, 6, false, 1.0, 1.0) == Grade.Rank.PERFECT, "여유 충분은 완전범죄")
	_check(BallotBoxRules.judge(8, 6, false, 0.5, 1.0) == Grade.Rank.SUCCESS, "아슬아슬은 미션성공")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
