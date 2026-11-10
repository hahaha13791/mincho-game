---
name: commit
description: 현재 변경을 한국어 커밋 메시지로 바로 커밋하고 결과를 보고한다. 하나의 작업 단위(기능 추가, 버그 수정, 문서 갱신 등)가 끝나 검증까지 마쳤을 때 자동으로 사용한다. /commit으로도 호출 가능.
---

# 커밋

## 순서

1. `git status`, `git diff HEAD`, `git log -5 --oneline`을 병렬로 실행한다.
2. 변경이 서로 무관한 목적을 섞고 있으면 커밋하지 말고 사용자에게 어떻게 나눌지 묻는다.
3. 파일을 이름으로 지정해 `git add`한다. `git add -A`, `git add .` 금지.
4. 아래 스타일로 메시지를 써서 바로 커밋한다. 승인 대기 없음.
5. `git status`로 확인하고 커밋 해시, 제목, 포함 파일을 보고한다.

push, amend, `--no-verify`, 브랜치 변경은 사용자가 명시적으로 요청할 때만 한다.

## Godot 규칙

- `.godot/`는 스테이징하지 않는다 (`.gitignore`에 있는지 확인).
- `.uid` 파일은 대응하는 `.gd`와 함께 커밋한다.
- `project.godot`, `.claude/`, `docs/` 변경이 이번 작업과 무관해 보이면 묶지 말고 알린다.

## 메시지 스타일

```
<접두어>(<범위>): <제목>

<본문, 필요할 때만>

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
```

**접두어**: `feat`(기능 추가) / `fix`(버그 수정) / `refactor`(동작 변화 없는 정리) / `asset`(모델·사운드·폰트) / `docs`(기획서, CLAUDE.md) / `chore`(설정, project.godot, .gitignore, 폴더)

**범위(선택)**: 폴더 이름 그대로 (`common`, `main`, `minigames/피아노표`). 여러 폴더에 걸치면 생략.

**제목**: 한 줄, 40자 안팎, 명사형 종결("~추가", "~수정"), 마침표 없음. 무엇을 했는지 구체적으로.

**본문**: 제목만으로 이유가 안 보일 때만. 무엇이 아니라 왜를 쓴다. 항목이 여러 개면 `-`.

**금지**: 이모지, "WIP", "수정함"·"업데이트" 같은 단독 제목. 코드 식별자(`GameState`, `.tscn`)는 번역하지 않는다.

## 예시

- `feat(common): 득표 상태와 등급 관리용 GameState 오토로드 추가`
- `chore: 폴더 구조 생성 (common, minigames, assets, main)`
- `fix(minigames/피아노표): 감시자 박자에 찍어도 감점되지 않던 문제 수정`
- `docs: 기획서에 샌드위치표 묶음 규칙 반영`
