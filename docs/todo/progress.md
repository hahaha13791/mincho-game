# progress (전체 진행 현황, 이어서 작업하는 곳)

마지막 갱신 기준 커밋: `63a2f30`. 새 세션은 이 파일 → `.claude/CLAUDE.md` → 필요한 todo 파일 순서로 읽는다.

## 한 줄 상태

기획서의 흐름(타이틀 → 허브 → 미니게임 7개 → 개표 → 리더보드 → 타이틀)이 끝까지 이어진다. 모든 미니게임은 **임시 모양(단색 상자)** 이고, 자동 시뮬레이션과 규칙 테스트만 했다. **실제 창에서 직접 플레이한 확인은 거의 없다.** 다음 단계는 사람이 직접 플레이해 보면서 이상한 점·재미없는 점을 모으는 것이다.

## 구현 현황

| # | 이름 | id / 폴더 | 상태 | 수치 파일 | 규칙 테스트 |
|---|---|---|---|---|---|
| 1 | 임신한 투표함 | `ballot_box` | 구현. 수치는 `ballot_box.gd`의 `@export` | (스크립트) | `minigames/ballot_box/test_rules.gd` |
| 2 | 피아노표 | `piano_ballot` | 구현. 박자음은 코드로 만든 임시 삐 소리 | `piano_config.tres` | `minigames/piano_ballot/test_rules.gd` |
| 4 | 샌드위치표 | `sandwich_ballot` | 구현. 위·아래 민초 묶음 확정, 가운데 반민초 표만 센다 | `sandwich_config.tres` | `minigames/sandwich_ballot/test_rules.gd` |
| 5 | 올빼미표 | `owl_ballot` | 구현. 맵은 `owl_level.gd`에 고정, 클리어 가능 경로 검사 포함 | `owl_config.tres` | `minigames/owl_ballot/test_rules.gd` |
| 6 | 사라지는 잉크 | `vanishing_ink` | 구현. 다리미가 기표를 덮고 테두리만 변색 | `ironing_config.tres` | `minigames/vanishing_ink/test_rules.gd` |
| 8 | 다그닥-바와스 | `tally_board` | **임시안, 재미없음 → 재설계 필요** (`tally-board.md`) | `tally_config.tres` | `minigames/tally_board/test_rules.gd` |
| 9 | 미친 쥐 | `mad_rat` | 구현. 판별 규칙(옷 색 기준, 모자 무시)은 내 제안이라 미확정 | `mad_rat_config.tres` | `minigames/mad_rat/test_rules.gd` |

공통(`common/`): `game_state.gd`(득표·등급), `grade.gd`, `vote_config.tres`(등급별 득표 `+7 / +3.5 / −3`, 점수 `3/2/0`), `result_screen.gd`, `tutorial.gd`(공통 튜토리얼 틀), `final_rules.gd`(승패·칭호), `leaderboard.gd`(저장·순위), `idle_return.gd`(오토로드, 90초 무입력 시 타이틀 복귀), `watcher.tscn`(2번·5번 공용 감시자 임시 모양), `flow.gd`(화면 전환).
화면(`main/`): `title`, `hub`(3×3, 가운데 = 개표 당일, 8번째 칸은 "준비 중"), `final_count`, `leaderboard`, `minigame_list.tres`.
오토로드: `GameState`, `Flow`, `IdleReturn`. 시작 씬: `main/title.tscn`.

미니게임 구조는 모두 같다: `Tutorial.open(self, 설명, _start)` → 플레이 → `GameState.submit_result(id, rank)` → `ResultScreen.open(...)`. 수치는 설정 리소스, 판정은 `*_rules.gd`(순수 로직), 겉모습은 `_build_visuals()`나 서브씬에 모은다.

## 다음에 할 일 (추천 순서)

1. **직접 플레이해 보기** (사람): `F5` 실행 → 7개를 해 보며 이상한 점·재미없는 점 메모. 개표 화면만 빨리 보려면 허브 아래의 `7개 모두 완료 (테스트용)` 버튼. 미니게임 하나만 보려면 씬을 열고 `F6`
2. **수치와 규칙 조정**: 미니게임별 난이도, 등급별 득표 변화, 칭호 조건, 자동 복귀 시간. 3개 등급이 모두 나올 수 있는지 확인
3. **정해야 할 것** (아래 "결정 대기")
4. **디자인 단계**: 화풍·팔레트 확정, 인물 모델링(`villager.tscn`, `watcher.tscn` 안의 모델만 교체), 에셋(Kenney/Quaternius/KayKit), 효과음·배경음, 그림/움직임 튜토리얼, 허브 연출, 칭호 카드
5. **기획서 갱신**: `docs/기획서.md`에는 3×3 격자, 8번 임시안, 득표 수치 변경, 리더보드 방식(이름 자동)이 아직 없다. 전시 제출 전에 반영

## 결정 대기 (사용자가 정해야 함)

- **8번 재설계**: 1안 시선 피하기(추천) / 2안 한 표씩 옮기기 / 3안 8번 접기 → `tally-board.md`
- **8번째 미니게임 칸**: 새 게임을 만들지, 비워 둘지. 넣으면 `GameState.MINIGAME_COUNT`(7)와 허브의 개표 조건을 같이 바꾼다. 기획서에서 뺀 3번(쌍가락지표), 7번(티슈 투표지)을 되살리는 것도 후보
- **9번 판별 단서**: 옷 색 기준·모자 무시로 갈지
- **리더보드 이름 입력**: 지금은 `민초단원 N호` 자동(입력이 마우스뿐이라). 마우스로 글자 고르기 등으로 바꿀지
- **전시 중 기록 초기화 방법**: 전시 시작 전 `user://leaderboard.json` 삭제(Godot 메뉴 `프로젝트 → 사용자 데이터 폴더 열기`). 자동 복귀 90초가 적당한지도 플레이 테스트로

## 확인 못 한 것

- 모든 화면의 실제 배치·글자 크기·연출 속도(헤드리스로만 실행)
- 실제 마우스 조작감: 1번 표 드래그, 2번 박자 지연, 5번 클릭 이동, 9번 주민 속도
- 튜토리얼 문구가 몇 초 안에 읽히는지
- 2번에서 감시자 박에 찍어 적발되는 장면, 1번에서 선을 넘겨 실패하는 장면은 시뮬레이션하지 않음

## 실행 방법

- Godot 4.7 실행 파일 경로는 PC마다 다르다(`.claude` 메모리에도 경로를 적지 않는다). 규칙 테스트: `godot --headless --path . -s res://<폴더>/test_rules.gd`, 개표는 `-s res://common/test_final_rules.gd`, 리더보드는 `-s res://common/test_leaderboard.gd`. 출력에 `TEST OK`가 나오면 통과
- 새 `class_name` 스크립트를 만든 뒤 헤드리스로 테스트하려면 먼저 `godot --headless --path . --import`를 한 번 돌려야 클래스를 찾는다
- 씬 확인: `godot --headless --path . res://<씬>.tscn --quit-after 40`, 출력에서 `ERROR`/`SCRIPT ERROR`를 본다

## 작업하며 알게 된 주의점

- **에디터가 켜져 있을 때 파일을 옮기거나 이름을 바꾸면** 이전 경로를 캐시해서 에러가 난다. `프로젝트 → 현재 프로젝트 다시 불러오기`로 해결(실제로 한 번 겪음). 파일을 옮길 때는 미리 알린다
- 시뮬레이션 스크립트에서 `change_scene`을 부르면 테스트 노드 자신이 지워진다. 전환 직전 시그널 핸들러에서 결과를 찍거나 전환을 피한다
- `project.godot`은 에디터가 줄 순서를 바꾸는 등 사소한 변경이 자주 생긴다. 이번 작업과 무관하면 커밋에 묶지 않는다
- Windows에서 파이썬 한 줄 스크립트에 `\n`이 섞인 한글 문자열을 넣으면 의도와 다르게 들어갈 수 있다. 파일 편집은 Edit/Write 도구나 파일로 저장한 스크립트를 쓴다
- 입력은 PC + 마우스만이다. 키보드가 필요한 기능(이름 입력 등)은 마우스 대체 방식을 설계해야 한다
- 정치색 배제: 실제 정당·인물·선거를 연상시키는 이름·색·상징 금지, 게임 안에서 전자투표·블록체인 언급 금지
