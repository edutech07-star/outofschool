# Escape Room School

학교 배경 방탈출 게임 프로젝트 골격 (Godot 4 / GDScript).

## 게임 흐름

1. 과목 선택
2. 난이도 선택  ← 게임 시작 후 변경 불가
3. 문제 개수 선택
4. 로그인
5. 새 게임 / 이어하기
6. 학교 입장 (난이도 잠금)
7. 탐험 시작
8. 퍼즐 및 문제 등장

> 로그인 직후에는 문제를 생성하지 않는다.
> 반드시 탐험 이후 자연스럽게 등장한다.
> `GameState.can_spawn_question()` 가 가드 역할.

## 난이도

| 난이도 | 문제 | 힌트 | 공간 왜곡 | 이상 현상 |
|--------|------|------|----------|----------|
| EASY   | 쉬운 개념, 짧은 문제, 보기 중심 | 자주 + 자세한 해설 | 약함 | 낮음 |
| NORMAL | 일반 교과 수준, 응용 포함 | 제한적 | 중간, 복도 루프 | 중간 |
| HARD   | 고난도 응용, 복합 사고 | 최소화 | 강함, 맵 변형, 문 위치 변경 | 높음, 환영/노이즈/음악 중단 |

모든 파라미터는 `scripts/globals/difficulty_config.gd` 에 정의되어 있다.

## API 키

Claude API를 사용해 문제를 생성한다.

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."
```

또는 Godot user 디렉터리에 `api_key.txt` 파일을 두면 자동 로드.

## 프로젝트 구조

```
escape-room-school/
├── project.godot
├── scenes/
│   ├── subject_select.tscn       # 1. 과목
│   ├── difficulty_select.tscn    # 2. 난이도
│   ├── question_count_select.tscn# 3. 개수
│   ├── login.tscn                # 4. 로그인
│   ├── new_or_continue.tscn      # 5. 새 게임/이어하기
│   ├── school.tscn               # 6~7. 학교/탐험
│   ├── puzzle.tscn               # 8. 퍼즐
│   └── map_app.tscn              # 상단 맵 HUD
├── scripts/
│   ├── globals/                  # 오토로드
│   │   ├── game_state.gd
│   │   ├── difficulty_config.gd
│   │   └── claude_api.gd
│   ├── flow/                     # 씬별 스크립트
│   └── systems/                  # 왜곡/힌트/이상현상/맵
└── config/prompts/               # 난이도별 AI 프롬프트
    ├── easy.txt
    ├── normal.txt
    └── hard.txt
```

## 실행

1. Godot 4 에디터로 폴더 열기
2. 메인 씬은 `scenes/subject_select.tscn`
3. API 키 설정 후 F5

## 확장 포인트

- `scripts/systems/space_distortion.gd` - 복도 루프, 맵 변형, 문 위치 변경 트리거
- `scripts/systems/anomaly_system.gd` - 조명/방송/환영/음악 중단 시그널
- `scripts/systems/hint_system.gd` - 난이도별 힌트 빈도
- `scripts/systems/map_app.gd` - 상단 맵 HUD, 난이도에 따른 왜곡/노이즈
- `config/prompts/*.txt` - AI 문제 생성 프롬프트 (`{{SUBJECT}}` 치환)
