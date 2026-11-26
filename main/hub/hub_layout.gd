class_name HubLayout
extends RefCounted
## 작전본부실 수사 보드의 고정 배치. 좌표는 화면(1920x1080) 기준 중심점, 각도는 도.
## 메모·장식을 옮기거나 더하려면 여기만 고친다.

const BOARD: Rect2 = Rect2(30, 24, 1860, 760) # 나무 액자 바깥
const CORK_MARGIN: float = 22.0
const MEMO_SIZE: Vector2 = Vector2(300, 210)

## 미니게임 메모. id는 minigame_list의 id
const MEMOS: Dictionary = {
	&"ballot_box": {"pos": Vector2(330, 260), "tilt": -4.0},
	&"piano_ballot": {"pos": Vector2(720, 150), "tilt": 3.0},
	&"sandwich_ballot": {"pos": Vector2(1250, 165), "tilt": -2.5},
	&"owl_ballot": {"pos": Vector2(1580, 380), "tilt": 5.0},
	&"vanishing_ink": {"pos": Vector2(400, 590), "tilt": 3.5},
	&"mad_rat": {"pos": Vector2(1340, 610), "tilt": -5.0},
}
const CENTER: Dictionary = {"pos": Vector2(930, 410), "size": Vector2(380, 290), "tilt": -1.5}

## 장식(누를 수 없음). kind: news = 득표율 신문 스크랩, photo, note, map
const DECOR: Array[Dictionary] = [
	{"kind": "title", "pos": Vector2(190, 80), "size": Vector2(300, 80), "tilt": -3.0, "text": "작전본부실"},
	{"kind": "news", "pos": Vector2(1665, 135), "size": Vector2(330, 170), "tilt": 2.0},
	{"kind": "photo", "pos": Vector2(120, 470), "size": Vector2(150, 175), "tilt": -7.0, "text": "마을 투표소"},
	{"kind": "note", "pos": Vector2(740, 650), "size": Vector2(210, 140), "tilt": -6.0, "text": "작전명:\n민초의 역습?"},
	{"kind": "map", "pos": Vector2(1010, 680), "size": Vector2(260, 140), "tilt": 4.0, "text": "마을 지도"},
	{"kind": "note", "pos": Vector2(1740, 640), "size": Vector2(190, 150), "tilt": 7.0, "text": "D-day\n개표 당일!!"},
]
## 장식끼리 잇는 실 (DECOR 인덱스 또는 미니게임 id)
const EXTRA_STRINGS: Array = [[1, &"owl_ballot"], [2, &"ballot_box"], [4, &"mad_rat"], [3, &"vanishing_ink"]]
