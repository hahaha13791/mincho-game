class_name IroningConfig
extends Resource
## 사라지는 잉크 수치. 플레이 테스트로 여기서만 조정한다.

@export var rounds: int = 3
@export var need_success: int = 2 ## 이 라운드 수 이상 지우면 미션성공 이상
@export var steam_min: float = 1.0 ## 종이마다 김이 나는(기표가 지워지는) 시점을 이 범위에서 뽑는다
@export var steam_max: float = 3.0
@export var burn_ratio: float = 1.7 ## 타는 시점 = 김 나는 시점 × 이 값. 천천히 지워지는 종이는 누레지는 것도 느리다
@export var safe_margin: float = 0.6 ## 타기 이 시간 전에 떼야 '여유'. 전부 여유면 완전범죄
