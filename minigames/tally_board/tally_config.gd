class_name TallyConfig
extends Resource
## 다그닥-바와스 수치. 플레이 테스트로 여기서만 조정한다.

@export var classes: int = 4 ## 반 수
@export var m_min: int = 20 ## 반별 민초 득표 범위
@export var m_max: int = 40
@export var a_min: int = 40 ## 반별 반민초 득표 범위
@export var a_max: int = 80
@export var cap_ratio: float = 0.2 ## 한 칸에서 바꿀 수 있는 폭(원래 값 비율). 넘으면 필체가 달라 들킴
@export var cell_budget: int = 6 ## 고칠 수 있는 칸 수
@export var time_limit: float = 60.0
@export var perfect_ratio: float = 0.9 ## 이론상 최대 이득의 이 비율 이상이면 완전범죄
@export var success_ratio: float = 0.5 ## 이 비율 이상이면 미션성공, 미만이면 적발
