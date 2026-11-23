class_name SandwichRules
extends RefCounted

enum Outcome { OK, BUST, LOW_GAIN }


## sheets = 가운데에 쌓은 반민초 표 장수. 위·아래 민초 묶음은 항상 확정이고 장수에 넣지 않는다
static func evaluate(sheets: int, bust_limit: int, gain_target: int) -> Outcome:
	if sheets > bust_limit:
		return Outcome.BUST
	return Outcome.OK if sheets >= gain_target else Outcome.LOW_GAIN


## successes = 성공한 다발 수, min_sheets = 성공한 다발 중 가장 얇았던 장수
static func judge(successes: int, rounds: int, need: int, min_sheets: int, perfect_sheets: int) -> Grade.Rank:
	if successes < need:
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if successes == rounds and min_sheets >= perfect_sheets else Grade.Rank.SUCCESS
