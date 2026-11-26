extends SceneTree
## 실행: godot --headless --path . -s res://minigames/mad_rat/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	_check(MadRatRules.is_correct(true, MadRatRules.Dir.LEFT), "민초는 투표소")
	_check(not MadRatRules.is_correct(true, MadRatRules.Dir.RIGHT), "민초를 가게로 보내면 오답")
	_check(MadRatRules.is_correct(false, MadRatRules.Dir.RIGHT), "반민초는 가게")
	_check(not MadRatRules.is_correct(false, MadRatRules.Dir.LEFT), "반민초를 투표소로 보내면 오답")
	_check(MadRatRules.judge(0, 0, 3) == Grade.Rank.PERFECT, "무실수는 완전범죄")
	_check(MadRatRules.judge(3, 0, 3) == Grade.Rank.SUCCESS, "경계값은 미션성공")
	_check(MadRatRules.judge(4, 0, 3) == Grade.Rank.CAUGHT, "초과는 적발")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
