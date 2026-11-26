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
	_check(MadRatRules.unlocked_twists(0).is_empty(), "웨이브 1은 변칙 없음")
	_check(MadRatRules.unlocked_twists(1) == [MadRatRules.Twist.HAT], "웨이브 2는 모자만")
	_check(MadRatRules.unlocked_twists(3).size() == 3, "웨이브 4는 변칙 전부")
	_check(MadRatRules.unlocked_twists(9).size() == 3, "웨이브가 더 많아도 변칙은 셋")

	var cfg: MadRatConfig = load("res://minigames/mad_rat/mad_rat_config.tres")
	var n: int = cfg.wave_counts.size()
	_check(cfg.wave_speed.size() == n and cfg.wave_gap.size() == n, "웨이브 배열 길이가 같음")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
