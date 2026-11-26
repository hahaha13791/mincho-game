class_name PianoConfig
extends Resource
## 피아노표 수치. 플레이 테스트로 여기서만 조정한다. 박 = 4분음표, 마디 = 4박.
## 날 따라해봐요: 한 라운드 = 보여 주기 마디(뒤 레일) → 따라 하기 마디(앞 레일에서 찍기) → 쉼. 라운드 번호는 0부터

@export var bpm: float = 100.0
@export var count_in: int = 4 ## 첫 보여 주기 마디 전 박자 수
@export var rounds: int = 8 ## 라운드 수(= 따라 하기 횟수)
@export var rest_beats: float = 2.0 ## 따라 하기가 끝나고 다음 보여 주기까지 쉬는 박
@export var mix_from: int = 2 ## 이 라운드부터 민초 표가 섞임
@export var anti_ratio: float = 0.6 ## 섞인 구간에서 반민초 표 비율
@export var vary_from: int = 1 ## 이 라운드부터 8분·엇박 패턴이 나옴
@export var fast_from: int = 4 ## 이 라운드부터 16분 패턴도 나옴
@export var watch_from: int = 4 ## 이 라운드부터 감시자가 나옴
@export var watch_every: int = 1 ## 감시자 간격(라운드). 1 = 라운드마다 한 명
@export var warn_beats: float = 2.0 ## 감시자 표보다 이만큼 먼저 소리와 함께 감시자가 고개를 내민다(박)
@export var window: float = 0.17 ## 박자 판정 허용 오차(초, ±). 표 간격이 좁으면 간격의 절반으로 줄어든다
@export var perfect_mistakes: int = 1 ## 실수가 이 이하면 완전범죄
@export var success_mistakes: int = 5 ## 실수가 이 이하면 미션성공, 넘으면 적발
## 한 마디 안에서 표가 오는 박(0 ~ 4 미만)
@export var patterns_basic: Array[PackedFloat32Array] = [
	PackedFloat32Array([0.0, 1.0, 2.0, 3.0]), # 정박
]
@export var patterns_vary: Array[PackedFloat32Array] = [
	PackedFloat32Array([0.0, 1.0, 2.0, 2.5, 3.0]), # 8분 하나
	PackedFloat32Array([0.0, 0.5, 1.0, 2.0, 3.0]),
	PackedFloat32Array([0.0, 1.5, 2.0, 3.0]), # 당김음
	PackedFloat32Array([0.5, 1.5, 2.5, 3.5]), # 전부 엇박
	PackedFloat32Array([0.0, 1.0, 1.5, 2.5, 3.0]),
]
@export var patterns_fast: Array[PackedFloat32Array] = [
	PackedFloat32Array([0.0, 1.0, 1.25, 1.5, 2.0, 3.0]), # 16분 셋
	PackedFloat32Array([0.0, 0.75, 1.5, 2.0, 3.0]), # 점8분
	PackedFloat32Array([0.0, 1.0, 2.0, 2.25, 3.0]),
]
