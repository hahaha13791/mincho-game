class_name MadRatConfig
extends Resource
## 미친 쥐 수치. 플레이 테스트로 여기서만 조정한다.

@export var villager_count: int = 20
@export var mincho_ratio: float = 0.5 ## 민초 옷 주민 비율
@export var speed_start: float = 3.0 ## 걷는 속도 (진행에 따라 end까지 빨라짐)
@export var speed_end: float = 7.0
@export var gap_start: float = 1.5 ## 다음 주민이 나오는 간격(초)
@export var gap_end: float = 0.55
@export var decoy_start: float = 0.0 ## 헷갈리는 모자를 쓴 주민 비율
@export var decoy_end: float = 0.5
@export var perfect_wrong: int = 0 ## 틀린 수가 이 이하면 완전범죄
@export var success_wrong: int = 3 ## 틀린 수가 이 이하면 미션성공, 넘으면 적발
