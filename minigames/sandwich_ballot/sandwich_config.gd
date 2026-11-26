class_name SandwichConfig
extends Resource
## 샌드위치표 수치. 플레이 테스트로 여기서만 조정한다.

@export var rounds: int = 3 ## 만드는 다발 수
@export var need_success: int = 2 ## 이 수 이상 성공해야 미션성공 이상
@export var add_min: int = 5 ## 쌓기 한 번에 반민초 표가 늘어나는 장수 범위 (화면에 공개)
@export var add_max: int = 15
@export var bust_limit: int = 100 ## 반민초 표가 이 장수를 넘으면 버스트
@export var gain_target: int = 50 ## 다발 하나가 성공하려면 필요한 반민초 표 장수
@export var perfect_sheets: int = 85 ## 모든 다발이 성공하고 전부 이 장수 이상이면 완전범죄
@export var sheet_interval: float = 0.05 ## 쌓기 연출에서 종이가 한 장씩 떨어지는 간격(초)
