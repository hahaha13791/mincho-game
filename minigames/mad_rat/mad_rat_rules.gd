class_name MadRatRules
extends RefCounted

enum Dir { LEFT, RIGHT } # LEFT = 투표소, RIGHT = 민트초코 아이스크림가게
## 주민 한 명에게 붙는 헷갈리는 변칙. 웨이브마다 하나씩 열린다
## HAT = 반대 색 모자(무시), COAT = 코트로 셔츠를 가림(완장 색이 정체), GLASSES = 선글라스 변장(셔츠 색이 반대)
enum Twist { NONE, HAT, COAT, GLASSES }


## 정체(is_mincho) 기준이다. 민초는 투표소로, 반민초는 아이스크림가게로 보낸다
static func is_correct(is_mincho: bool, dir: Dir) -> bool:
	return (dir == Dir.LEFT) == is_mincho


## 웨이브 wave(0부터)에서 나올 수 있는 변칙. 웨이브 0은 없음, 이후 하나씩 늘어난다
static func unlocked_twists(wave: int) -> Array[Twist]:
	var all: Array[Twist] = [Twist.HAT, Twist.COAT, Twist.GLASSES]
	return all.slice(0, clampi(wave, 0, all.size()))


## wrong = 잘못 보냈거나 놓친 주민 수
static func judge(wrong: int, perfect_wrong: int, success_wrong: int) -> Grade.Rank:
	if wrong <= perfect_wrong:
		return Grade.Rank.PERFECT
	return Grade.Rank.SUCCESS if wrong <= success_wrong else Grade.Rank.CAUGHT
