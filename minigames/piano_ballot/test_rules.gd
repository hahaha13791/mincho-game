extends SceneTree
## 실행: godot --headless --path . -s res://minigames/piano_ballot/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	var cfg: PianoConfig = PianoConfig.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1
	var b: Array[Dictionary] = PianoRules.build(cfg, rng)
	_check(b.size() == cfg.beats, "박자 수만큼 생성")
	var early_ok: bool = true
	for i in cfg.mix_from:
		early_ok = early_ok and b[i]["anti"] and not b[i]["watcher"]
	_check(early_ok, "초반은 전부 반민초 표, 감시자 없음")
	_check(b[cfg.watch_from]["watcher"] and b[cfg.watch_from + cfg.watch_gap]["watcher"], "감시자는 일정 간격")
	_check(not b[cfg.watch_from + 1]["watcher"], "감시자 간격 사이는 없음")
	_check(not PianoRules.should_stamp({"anti": true, "watcher": true}), "감시자 박자는 찍으면 안 됨")
	_check(not PianoRules.should_stamp({"anti": false, "watcher": false}), "민초 표는 찍으면 안 됨")
	_check(PianoRules.should_stamp({"anti": true, "watcher": false}), "반민초 표는 찍어야 함")
	_check(PianoRules.judge(true, 0, 1, 5) == Grade.Rank.CAUGHT, "감시자에 찍으면 적발")
	_check(PianoRules.judge(false, 1, 1, 5) == Grade.Rank.PERFECT, "실수 1회는 완전범죄")
	_check(PianoRules.judge(false, 5, 1, 5) == Grade.Rank.SUCCESS, "경계값은 미션성공")
	_check(PianoRules.judge(false, 6, 1, 5) == Grade.Rank.CAUGHT, "초과는 적발")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
