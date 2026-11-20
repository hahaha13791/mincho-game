# hub

- [ ] `main/minigame_list.tres`: id, 표시 이름, 씬 경로
  - 테스트(자동): 로드 에러 없음
- [ ] `main/hub.tscn`: `Control` 메뉴, 카드 7개, 끝낸 카드에 등급 표시
  - 테스트(수동): 카드 클릭으로 이동, 결과 후 복귀 시 등급 표시
- [ ] 7개 완료 시 "개표" 버튼 노출 (`all_finished`)
  - 테스트(자동): 더미 결과 7개 제출 시 버튼 노출
- [ ] 메인 씬 지정 (`run_project` 가능하게)
  - 테스트(자동): `run_project`가 에러 없이 실행
