class_name IroningConfig
extends Resource
## 사라지는 잉크 수치. 플레이 테스트로 여기서만 조정한다.

@export var rounds: int = 3
@export var need_success: int = 2 ## 이 라운드 수 이상 지우면 미션성공 이상
@export var steam_time: float = 1.5 ## 김이 나는 시점(모든 종이 동일). 이후에 떼야 지워진 것
@export var burn_min: float = 2.5 ## 종이마다 타는 시점을 이 범위에서 뽑는다
@export var burn_max: float = 4.5
@export var safe_margin: float = 0.6 ## 타기 이 시간 전에 떼야 '여유'. 전부 여유면 완전범죄
