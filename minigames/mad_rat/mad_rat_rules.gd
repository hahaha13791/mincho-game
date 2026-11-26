class_name MadRatRules
extends RefCounted

enum Dir { LEFT, RIGHT } # LEFT = 투표소, RIGHT = 민트초코 아이스크림가게


## 옷 색이 기준이다(모자는 무시). 민초는 투표소로, 반민초는 아이스크림가게로 보낸다
static func is_correct(is_mincho: bool, dir: Dir) -> bool:
	return (dir == Dir.LEFT) == is_mincho


## wrong = 잘못 보냈거나 놓친 주민 수
static func judge(wrong: int, perfect_wrong: int, success_wrong: int) -> Grade.Rank:
	if wrong <= perfect_wrong:
		return Grade.Rank.PERFECT
	return Grade.Rank.SUCCESS if wrong <= success_wrong else Grade.Rank.CAUGHT
