extends Node
## 힌트 제공량 제어.
## EASY: 1.0 (자주) / NORMAL: 0.5 (제한적) / HARD: 0.15 (최소화)

var hint_frequency: float = 0.5
var detail: String = ""

func apply_config(cfg: Dictionary) -> void:
	hint_frequency = cfg["hint_frequency"]
	detail = cfg["hint_detail"]

func should_offer_hint() -> bool:
	return randf() < hint_frequency

func is_detailed_explanation() -> bool:
	# EASY에서만 자세한 해설 자동 제공.
	return hint_frequency >= 1.0
