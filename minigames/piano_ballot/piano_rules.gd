class_name PianoRules
extends RefCounted


## 박자별 표 구성. 각 원소 = { "anti": 반민초 표인가, "watcher": 감시자가 있는 박자인가 }
static func build(cfg: PianoConfig, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in cfg.beats:
		var anti: bool = i < cfg.mix_from or rng.randf() < cfg.anti_ratio
		var watcher: bool = i >= cfg.watch_from and (i - cfg.watch_from) % cfg.watch_gap == 0
		out.append({"anti": anti, "watcher": watcher})
	return out


## 찍어야 하는 박자인가: 반민초 표이고 감시자가 없을 때만
static func should_stamp(beat: Dictionary) -> bool:
	return beat["anti"] and not beat["watcher"]


## caught = 감시자 박자에 찍음, mistakes = 놓친 반민초 표 + 찍은 민초 표
static func judge(caught: bool, mistakes: int, perfect_mistakes: int, success_mistakes: int) -> Grade.Rank:
	if caught or mistakes > success_mistakes:
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if mistakes <= perfect_mistakes else Grade.Rank.SUCCESS
