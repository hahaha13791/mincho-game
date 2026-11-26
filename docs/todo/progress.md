# progress (전체 진행 현황, 이어서 작업하는 곳)

마지막 갱신 기준 커밋: `19c4dbf`. 새 세션은 이 파일 → `.claude/CLAUDE.md` → 필요한 todo 파일 순서로 읽는다.

## 한 줄 상태

흐름(타이틀 → 작전본부실 → 미니게임 6개 → 개표 → 리더보드 → 타이틀)이 끝까지 이어진다. **디자인 단계 진행 중**: 인물(하얀 인형)과 미니게임 소품 대부분, 작전본부실(수사 보드·책상·주인공)을 만들었다. 확인은 주로 캡처(헤드리스/무비 녹화)로 했고 **사람이 직접 플레이한 확인은 아직 적다.** `docs/게임피드백.md`의 미니게임 피드백은 모두 반영했다(2026-11-26). 다음은 직접 플레이로 새 수치 확인.

## 구현 현황

| # | 이름 | id / 폴더 | 상태 | 수치 파일 | 규칙 테스트 |
|---|---|---|---|---|---|
| 1 | 임신한 투표함 | `ballot_box` | 구현. 참관인 = 감시자 인형(걸어옴), 반투명 앞판에 '투표함', 뚜껑 투입구. 10장 성공/12장 대성공, 쿵이 0.8초마다 하나씩(소리 `common/beep.gd`) | (스크립트 `@export`) | `test_rules.gd` |
| 2 | 피아노표 | `piano_ballot` | 구현. 컨베이어 두 줄(앞 = 찍는 레일, 뒤 = 반대로 흐르는 미리보기, 표가 고리처럼 돎), 마디별 리듬 패턴(정박·8분·엇박·16분, `piano_config`), 흰 표(반민초 = 빈 종이, 민초 = 민트 '卜' 도장), 카메라 약 30도 | `piano_config.tres` | `test_rules.gd` |
| 4 | 샌드위치표 | `sandwich_ballot` | 구현. 흰 종이가 한 장씩 쌓이는 연출, 민트 띠지 묶음(닫으면 위·아래 띠지가 이어짐), 버스트 때 종이가 미끄러져 떨어짐 | `sandwich_config.tres`(`sheet_interval` 포함) | `test_rules.gd` |
| 5 | 올빼미표 | `owl_ballot` | 구현. 맵 15x9, 엄폐물 16개(상자 더미·개표 테이블·ㄱ자 칸막이, `owl_level.gd`의 PIECES), 감시자 3명(시야 방향을 봄, 불이 켜진 동안 다음 자리로 걸어감), '투표함' 글씨 투표함 | `owl_config.tres` | `test_rules.gd`(배치·클리어 가능 경로 검사) |
| 6 | 사라지는 잉크 | `vanishing_ink` | 구현. 다리미가 위에서 수직으로 내려옴, 그을음 = 바닥판 윤곽 띠(떼면 하얗게), 종이마다 지워지는 시간(타는 시간은 그 배율), 종이가 왼쪽에서 들어와 오른쪽으로 나감 | `ironing_config.tres` | `test_rules.gd` |
| 9 | 미친 쥐 | `mad_rat` | 구현. 가운데 표지판(버튼은 표지판만 돌림, 주민은 갈림길에서 표지판 방향으로), 오른쪽 = 민트초코 아이스크림가게(반민초 "?!", 민초 "♥"). 판별 규칙(옷 색 기준, 모자 무시)은 미확정 | `mad_rat_config.tres` | `test_rules.gd` |

8번 다그닥-바와스는 삭제했다(미니게임 6개, `GameState.MINIGAME_COUNT = 6`).

공통(`common/`): `game_state.gd`, `grade.gd`, `vote_config.tres`(등급별 득표 `+7 / +3.5 / −3`, 점수 `3/2/0`), `result_screen.gd`, `tutorial.gd`, `final_rules.gd`, `leaderboard.gd`, `idle_return.gd`(90초 무입력 시 타이틀), `flow.gd`, `watcher.tscn`(감시자: 정장 V자 재킷·어두운 바지·넥타이·선글라스, `face()`/`set_walking()`), `figure_look.gd`(인형 파츠 입히기·애니메이션), `stamp_mark.tscn`(동그라미 '卜' 도장 자국, `ink`로 색), `style/palette.gd`·`theme.tres`(손글씨 `HandLabel`/`HandButton`).
화면(`main/`): `title`, `hub`(작전본부실), `final_count`, `leaderboard`, `minigame_list.tres`.
오토로드: `GameState`, `Flow`, `IdleReturn`. 시작 씬: `main/title.tscn`.

### 인물(하얀 인형) 만드는 법
- `assets/figure/build_figure.gd`(Godot): 부위를 SDF로 이어 붙여 OBJ를 `assets/figure/src/`에 낸다. `ONLY=coat,fedora`처럼 일부만 다시 만들 수 있다(전부는 약 5분)
- `assets/figure/src/rig_figure.py`(블렌더 5.3): 면 줄이기·뼈대·가중치·애니메이션(walk, idle, 작전 행동 8가지)을 붙여 `assets/figure/figure.glb`로 낸다. 실행: `blender -b --factory-startup -P assets/figure/src/rig_figure.py`
- 파츠: Body, Shirt, Hat, Jacket, Pants, Tie, Sunglasses, Armband, Headband, Fedora, Coat, Badge. 인물 서브씬은 `FigureLook.dress(인형, {파츠: 색})`으로 입는다
- OBJ는 git에서 제외(`src/.gitignore`). 블렌더 경로는 PC마다 다르다

### 작전본부실(`main/hub.gd`, `main/hub/`)
- 코르크 수사 보드(85% 크기): 메모 6장 고정 자유 배치(`hub_layout.gd`), 처음부터 전부 빨간 실로 가운데 '개표 당일' 카드와 연결, 완료 메모엔 등급 도장, 장식(득표율 신문 스크랩 등). 손글씨: 나눔손글씨 펜(OFL, `assets/fonts/`)
- 아래 3D 책상(`desk.gd`, 투명 SubViewport로 겹침)과 소품, 서류철 위 리더보드 버튼. 위에서 비추는 따뜻한 조명
- 주인공(`protagonist.gd`) 복장: 0~1개 민트 셔츠 / 2~3개 머리띠 / 4~5개 머리띠+완장 / 6개 중절모+깃 세운 초콜릿 코트(민트 배지)
- 들어올 때마다 직전과 다른 작전 행동 8가지 중 하나를 무작위 위치에서 한다(`desk.gd`의 ACTIONS, `HubDesk.last_action`)

## 다음에 할 일 (추천 순서)

1. **피드백 반영분 직접 플레이 확인**
   - 1번: 12장이 실제로 들어가는지(무작위로 떨어뜨리면 10장에서 선을 넘음). 어려우면 `BOX_W`/`BOX_H`를 키움. 종이 충돌 모양은 일단 유지(사용자 결정), 모델을 바꿀 때 충돌 모양까지 바꾸면 재조정
   - 2번: 16분 난이도, 미리보기 레일이 읽히는지, 감시자 수(마디마다 하나, 8마디부터)
   - 6번: 지워지는 시간 범위(1~3초)와 `burn_ratio`(1.7). 완전범죄 여유(0.6초)가 너무 쉬울 수 있음
   - 9번: 최고 속도(7, 간격 0.55초)
2. **남은 임시 모양**: 올빼미표 플레이어 말(초록 상자 → 주인공 인형 후보, 그때 `protagonist`를 `common/`으로), 1번 접힌 표, 타이틀·결과·개표·리더보드 화면 꾸미기
3. **직접 플레이**(사람): `F5` → 작전본부실을 여러 번 드나들며 행동이 바뀌는지, 메모 들림·클릭 확인. 테스트 버튼(`처음부터`, `전부 완료`)은 화면 오른쪽 아래
4. **수치 조정**: 난이도, 등급별 득표, 칭호 조건, 자동 복귀 시간
5. **효과음·배경음**(지금은 `common/beep.gd`의 코드 생성 소리뿐), 기획서 갱신(작전본부실, 8번 삭제, 득표 수치, 리더보드 이름 자동. 미니게임 규칙 표는 피드백 반영분까지 갱신함)

## 결정 대기 (사용자가 정해야 함)

- **9번 판별 단서**: 옷 색 기준·모자 무시로 갈지
- **리더보드 이름 입력**: 지금은 `민초단원 N호` 자동. 마우스로 글자 고르기 등으로 바꿀지
- **완장 쓰임새**: 감시자용 완장은 만들어만 둠(주인공 4~5단계에는 민트 완장으로 사용 중)
- **전시 중 기록 초기화 방법**: 전시 시작 전 `user://leaderboard.json` 삭제. 자동 복귀 90초가 적당한지

## 알려진 문제·확인 못 한 것

- 주인공 포즈는 각도로 만든 것이라 거칠다(턱 괴기 손이 조금 낮음, 전화 팔이 어색). 코트를 입고 팔을 크게 움직이면 몸이 하얗게 조금 비친다
- 핀 꽂기 행동의 올라선 높이(lift 0.5)는 바꾼 뒤 다시 보지 않았다
- 메모 마우스 들림·클릭, 리더보드 버튼은 직접 눌러 보지 않았다
- 피아노표 실제 감시자 박자 장면, 샌드위치표 15장 연출 속도, 올빼미표 넓어진 맵 난이도는 직접 확인 필요
- 올빼미표처럼 먼 카메라에서는 감시자 넥타이가 거의 안 보인다

## 실행 방법

- 규칙 테스트: `godot --headless --path . -s res://<폴더>/test_rules.gd`, 개표 `-s res://common/test_final_rules.gd`, 리더보드 `-s res://common/test_leaderboard.gd`. `TEST OK`면 통과
- 새 `class_name` 스크립트나 새 에셋(글꼴·glb)을 넣은 뒤에는 먼저 `godot --headless --path . --import`(첫 임포트 때 순서 에러가 한 번 날 수 있어 두 번 돌린다)
- 씬 확인: `godot --headless --path . res://<씬>.tscn --quit-after 40`, 출력에서 `ERROR`/`SCRIPT ERROR`를 본다
- 화면 캡처: `--write-movie <폴더>/f.png --fixed-fps 30 --quit-after N`(헤드리스 아님). 튜토리얼이 가리면 테스트 스크립트에서 튜토리얼 CanvasLayer를 지우고 `_start()`를 부른다

## 작업하며 알게 된 주의점

- **에디터가 켜져 있을 때 파일을 옮기거나 이름을 바꾸면** 이전 경로를 캐시해서 에러가 난다. `프로젝트 → 현재 프로젝트 다시 불러오기`로 해결(`stamp_mark`를 `common/`으로 옮겼다)
- 블렌더 OBJ 가져오기는 축 변환을 오브젝트 회전으로 넣는다. 꼭짓점 좌표를 쓰기 전에 `transform_apply`
- SDF 생성 범위(LO/HI) 밖은 잘려 구멍이 난다(뒤통수 구멍 사례). 새 파츠는 범위 안인지 확인하고 앞·뒤·옆에서 찍어 본다
- 빈 Tween(명령 없음)은 실행 에러. 넣을 것이 있을 때만 만든다
- tscn의 Transform3D 행렬 순서가 헷갈리면 회전은 스크립트에서 `rotation`으로 준다
- 오토로드(`GameState`)는 `-s` 테스트 스크립트의 `_initialize`보다 늦게 초기화될 수 있다. 상태 조작은 첫 `_process` 이후에
- `project.godot`의 사소한 변경은 무관하면 커밋에 묶지 않는다
- Windows에서 파이썬으로 한글 파일을 고칠 때 문자열 일치가 안 될 수 있다. 실패하면 Edit 도구로 고친다
- 입력은 PC + 마우스만. 정치색 배제: 실제 정당·인물·선거를 연상시키는 이름·색·상징 금지(새 색은 무채색이나 민초/초콜릿 계열)
