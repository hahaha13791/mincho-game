class_name VanishingInkRules
extends RefCounted


## clean = 깨끗이 지운 장 수, faint = 옅게 남은 장 수, min_margin = 깨끗이 지운 장 중 가장 빠듯했던 여유(김 남 → 탐 사이 비율)
## 지운 장(옅게 포함)이 need 미만이면 적발. 전부 깨끗하고 여유 있게 지웠으면 완전범죄
static func judge(clean: int, faint: int, rounds: int, need: int, min_margin: float, safe_margin: float) -> Grade.Rank:
	if clean + faint < need:
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if clean == rounds and min_margin >= safe_margin else Grade.Rank.SUCCESS


## 김 나기 전에 뗐을 때 기표 진하기(1 = 그대로). progress = 뗀 시점 / 김 나는 시점. faint_from 미만이면 그대로
static func faint_alpha(progress: float, faint_from: float) -> float:
	if progress < faint_from:
		return 1.0
	return lerpf(0.5, 0.12, clampf((progress - faint_from) / (1.0 - faint_from), 0.0, 1.0))
