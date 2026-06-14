extends Node
## 난이도별 게임 파라미터 정의.
## EASY / NORMAL / HARD 의 영향:
##   - 문제 난이도
##   - 공간 왜곡 강도
##   - 힌트 제공량
##   - 이상 현상 빈도

enum Difficulty { EASY, NORMAL, HARD }

const CONFIG := {
	Difficulty.EASY: {
		"label": "EASY",
		"description": "스토리와 탐험 중심 난이도",
		"recommended": "처음 플레이하는 유저",
		"question_difficulty": "easy",
		"question_style": "쉬운 개념, 짧은 문제, 보기 중심",
		"space_distortion": 0.2,
		"hint_frequency": 1.0,
		"hint_detail": "정답 해설 자세히 제공",
		"anomaly_frequency": 0.1,
		"puzzle_complexity": "simple",
		"corridor_loop_enabled": false,
		"map_mutation_enabled": false,
		"lighting_glitch_rate": 0.05,
		"broadcast_noise_rate": 0.05,
		"phantom_rate": 0.0,
		"door_relocation_enabled": false,
		"music_cutoff_enabled": false,
		"save_point_density": 1.0,
	},
	Difficulty.NORMAL: {
		"label": "NORMAL",
		"description": "기본 권장 난이도",
		"recommended": "기본 플레이 경험",
		"question_difficulty": "normal",
		"question_style": "일반 교과 수준, 응용 포함",
		"space_distortion": 0.5,
		"hint_frequency": 0.5,
		"hint_detail": "힌트 제한적 제공",
		"anomaly_frequency": 0.4,
		"puzzle_complexity": "compound",
		"corridor_loop_enabled": true,
		"map_mutation_enabled": false,
		"lighting_glitch_rate": 0.2,
		"broadcast_noise_rate": 0.2,
		"phantom_rate": 0.1,
		"door_relocation_enabled": false,
		"music_cutoff_enabled": true,
		"save_point_density": 0.8,
	},
	Difficulty.HARD: {
		"label": "HARD",
		"description": "심리적 긴장감과 탐험 난이도를 강화한 모드",
		"recommended": "숙련 플레이어",
		"question_difficulty": "hard",
		"question_style": "고난도 응용, 복합 사고 요구, 긴 지문 가능",
		"space_distortion": 0.9,
		"hint_frequency": 0.15,
		"hint_detail": "힌트 최소화",
		"anomaly_frequency": 0.8,
		"puzzle_complexity": "complex",
		"corridor_loop_enabled": true,
		"map_mutation_enabled": true,
		"lighting_glitch_rate": 0.6,
		"broadcast_noise_rate": 0.6,
		"phantom_rate": 0.5,
		"door_relocation_enabled": true,
		"music_cutoff_enabled": true,
		"save_point_density": 0.4,
	},
}

func get_config(difficulty: int) -> Dictionary:
	return CONFIG.get(difficulty, CONFIG[Difficulty.NORMAL])

func get_label(difficulty: int) -> String:
	return get_config(difficulty)["label"]

func parse_label(label: String) -> int:
	match label.to_upper():
		"EASY": return Difficulty.EASY
		"HARD": return Difficulty.HARD
		_: return Difficulty.NORMAL
