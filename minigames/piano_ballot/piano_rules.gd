class_name PianoRules
extends RefCounted

## 감시자 표는 앞뒤 표와 이 박 이상 떨어진 표 중에서 고른다. 감시자가 들어와 있는 동안 다른 표가 지나가지 않게 해,
## 감시자 앞에서 못 찍은 표가 실수로 잡히는 일이 없게 한다(piano_ballot.gd의 감시자 등장 시간보다 길어야 함)
const WATCH_MIN_GAP: float = 1.0
const MEASURE: float = 4.0 # 보여 주기·따라 하기 마디 길이(박). 보여 주기 → 따라 하기 시차도 이 값


## 표 목록(시간순). 각 원소 = { "time": 첫 보여 주기 시작 기준 몇 박째에 찍는 자리에 오나(소수 가능), "anti": 반민초 표인가, "watcher": 감시자가 오는 표인가 }
## 라운드 k: 보여 주기 [k × 주기, +4) → 따라 하기 [+4, +8) → 쉼 rest_beats. 표는 따라 하기 구간에만 있다
static func build(cfg: PianoConfig, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rounds: Array[Array] = [] # 라운드마다 표 번호
	for k in cfg.rounds:
		var pool: Array[PackedFloat32Array] = cfg.patterns_basic
		if k >= cfg.fast_from:
			pool = cfg.patterns_vary + cfg.patterns_fast
		elif k >= cfg.vary_from:
			pool = cfg.patterns_vary
		var ids: Array[int] = []
		for o in pool[rng.randi() % pool.size()]:
			ids.append(out.size())
			out.append({"time": response_start(cfg, k) + o, "anti": true, "watcher": false})
		rounds.append(ids)
	var gaps: PackedFloat32Array = half_gaps(out)
	for k in cfg.rounds:
		var ids: Array = rounds[k]
		if k >= cfg.watch_from and (k - cfg.watch_from) % cfg.watch_every == 0:
			var picks: Array = ids.filter(func(i: int) -> bool: return gaps[i] * 2.0 >= WATCH_MIN_GAP)
			if not picks.is_empty():
				out[picks[rng.randi() % picks.size()]]["watcher"] = true
		if k >= cfg.mix_from: # 민초 표는 감시자 표가 아닌 표 중에서 정해진 장수만
			var rest: Array = ids.filter(func(i: int) -> bool: return not out[i]["watcher"])
			for n in mini(cfg.mincho_per_round, rest.size()):
				out[rest.pop_at(rng.randi() % rest.size())]["anti"] = false
	return out


## 라운드 k의 따라 하기 마디가 시작하는 박
static func response_start(cfg: PianoConfig, k: int) -> float:
	return k * (2.0 * MEASURE + cfg.rest_beats) + MEASURE


## 표마다 가장 가까운 옆 표와의 간격의 절반(박). 판정 허용 오차가 옆 표와 겹치지 않게 하는 데 쓴다
static func half_gaps(ballots: Array[Dictionary]) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	for i in ballots.size():
		var g: float = INF
		if i > 0:
			g = minf(g, ballots[i]["time"] - ballots[i - 1]["time"])
		if i + 1 < ballots.size():
			g = minf(g, ballots[i + 1]["time"] - ballots[i]["time"])
		out.append(g / 2.0)
	return out


## 찍어야 하는 표인가: 반민초 표이고 감시자가 없을 때만
static func should_stamp(beat: Dictionary) -> bool:
	return beat["anti"] and not beat["watcher"]


## caught = 감시자 박자에 찍음, mistakes = 놓친 반민초 표 + 찍은 민초 표
static func judge(caught: bool, mistakes: int, perfect_mistakes: int, success_mistakes: int) -> Grade.Rank:
	if caught or mistakes > success_mistakes:
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if mistakes <= perfect_mistakes else Grade.Rank.SUCCESS
