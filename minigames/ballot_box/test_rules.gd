extends SceneTree
## 실행: godot --headless --path . -s res://minigames/ballot_box/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	_check(BallotBoxRules.judge(9, 12, 10, false, 5.0, 1.0) == Grade.Rank.CAUGHT, "성공 장수 미달은 적발")
	_check(BallotBoxRules.judge(12, 12, 10, true, 5.0, 1.0) == Grade.Rank.CAUGHT, "선을 넘으면 적발")
	_check(BallotBoxRules.judge(12, 12, 10, false, 1.0, 1.0) == Grade.Rank.PERFECT, "12장 + 여유 충분은 완전범죄")
	_check(BallotBoxRules.judge(13, 12, 10, false, 0.5, 1.0) == Grade.Rank.SUCCESS, "12장이어도 아슬아슬하면 미션성공")
	_check(BallotBoxRules.judge(10, 12, 10, false, 5.0, 1.0) == Grade.Rank.SUCCESS, "10장은 여유 있어도 미션성공")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
