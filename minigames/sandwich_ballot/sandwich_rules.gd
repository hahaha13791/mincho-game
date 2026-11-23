class_name SandwichRules
extends RefCounted

enum Outcome { OK, BUST, BAD_ENDS, LOW_GAIN }


## bundles: 아래→위 순서, true = 민초 묶음. 맨 위·맨 아래가 민초일 때만 가운데 반민초 표가 민초로 바뀐다
static func gain(bundles: Array[bool], per: int) -> int:
	if bundles.is_empty() or not (bundles[0] and bundles[-1]):
		return 0
	return bundles.count(false) * per


static func evaluate(bundles: Array[bool], per: int, bust_limit: int, gain_target: int) -> Outcome:
	if bundles.size() * per > bust_limit:
		return Outcome.BUST
	if bundles.is_empty() or not (bundles[0] and bundles[-1]):
		return Outcome.BAD_ENDS
	return Outcome.OK if gain(bundles, per) >= gain_target else Outcome.LOW_GAIN


## successes = 성공한 다발 수, min_sheets = 성공한 다발 중 가장 얇았던 장수
static func judge(successes: int, rounds: int, need: int, min_sheets: int, perfect_sheets: int) -> Grade.Rank:
	if successes < need:
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if successes == rounds and min_sheets >= perfect_sheets else Grade.Rank.SUCCESS
