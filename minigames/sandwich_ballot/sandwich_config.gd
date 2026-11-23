class_name SandwichConfig
extends Resource
## 샌드위치표 수치. 플레이 테스트로 여기서만 조정한다.

@export var rounds: int = 3 ## 만드는 다발 수
@export var need_success: int = 2 ## 이 수 이상 성공해야 미션성공 이상
@export var sheets_per_bundle: int = 5
@export var bust_limit: int = 100 ## 이 장수를 넘기면 버스트
@export var mincho_ratio: float = 0.3 ## 새 묶음이 민초일 확률
@export var gain_target: int = 30 ## 다발 하나가 성공하려면 민초로 바뀌는 반민초 표가 이만큼 필요
@export var perfect_sheets: int = 80 ## 모든 다발이 성공하고 전부 이 장수 이상이면 완전범죄
