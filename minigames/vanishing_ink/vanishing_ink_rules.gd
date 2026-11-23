class_name VanishingInkRules
extends RefCounted


## successes = 기표를 지운 라운드 수, min_margin = 성공한 라운드 중 가장 빠듯했던 "뗀 시점 → 타는 시점" 간격(초)
static func judge(successes: int, rounds: int, need: int, min_margin: float, safe_margin: float) -> Grade.Rank:
	if successes < need:
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if successes == rounds and min_margin >= safe_margin else Grade.Rank.SUCCESS
