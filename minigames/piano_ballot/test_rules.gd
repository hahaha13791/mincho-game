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
	for run in 50: # 무작위 패턴이라 여러 번 만들어 본다
		var b: Array[Dictionary] = PianoRules.build(cfg, rng)
		var gaps: PackedFloat32Array = PianoRules.half_gaps(b)
		var sorted_ok: bool = true
		var early_ok: bool = true
		var watch_per_measure: Array[int] = []
		watch_per_measure.resize(cfg.measures)
		var watch_gap_ok: bool = true
		for i in b.size():
			var t: float = b[i]["time"]
			sorted_ok = sorted_ok and (i == 0 or t > b[i - 1]["time"])
			_check(not PianoRules.is_call(floori(t / 4.0)), "보여 주기 마디에는 찍을 표가 없음")
			if t < cfg.vary_from * 4.0:
				early_ok = early_ok and b[i]["anti"] and not b[i]["watcher"] and is_equal_approx(t, roundf(t))
			if b[i]["watcher"]:
				watch_per_measure[floori(t / 4.0)] += 1
				watch_gap_ok = watch_gap_ok and gaps[i] * 2.0 >= PianoRules.WATCH_MIN_GAP
		_check(sorted_ok, "표는 시간순, 같은 시각 없음")
		_check(b[-1]["time"] < cfg.measures * 4.0, "마지막 표는 마지막 마디 안")
		_check(early_ok, "초반은 정박의 반민초 표, 감시자 없음")
		_check(watch_gap_ok, "감시자 표는 옆 표와 충분히 떨어짐")
		for m in cfg.measures:
			var want: int = 1 if m >= cfg.watch_from and (m - cfg.watch_from) % cfg.watch_every == 0 else 0
			_check(watch_per_measure[m] == want, "감시자는 %d마디부터 %d마디마다 하나 (%d마디)" % [cfg.watch_from, cfg.watch_every, m])
	var sample: Array[Dictionary] = [{"time": 0.0}, {"time": 1.0}, {"time": 1.25}, {"time": 3.0}]
	var g: PackedFloat32Array = PianoRules.half_gaps(sample)
	_check(is_equal_approx(g[0], 0.5) and is_equal_approx(g[1], 0.125) and is_equal_approx(g[2], 0.125) and is_equal_approx(g[3], 0.875), "판정 간격은 가까운 옆 표 간격의 절반")
	_check(not PianoRules.should_stamp({"anti": true, "watcher": true}), "감시자 박자는 찍으면 안 됨")
	_check(not PianoRules.should_stamp({"anti": false, "watcher": false}), "민초 표는 찍으면 안 됨")
	_check(PianoRules.should_stamp({"anti": true, "watcher": false}), "반민초 표는 찍어야 함")
	_check(PianoRules.judge(true, 0, 1, 5) == Grade.Rank.CAUGHT, "감시자에 찍으면 적발")
	_check(PianoRules.judge(false, 1, 1, 5) == Grade.Rank.PERFECT, "실수 1회는 완전범죄")
	_check(PianoRules.judge(false, 5, 1, 5) == Grade.Rank.SUCCESS, "경계값은 미션성공")
	_check(PianoRules.judge(false, 6, 1, 5) == Grade.Rank.CAUGHT, "초과는 적발")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
