extends Control
## 5. 문제 개수 선택
##
## 흐름: ... → 난이도 → 문제 개수 → 새/이어하기 → 학교.

@onready var spin: SpinBox = $VBox/CountSpin
@onready var next_button: Button = $VBox/NextButton

func _ready() -> void:
	spin.min_value = 1
	spin.max_value = 50
	spin.value = GameState.question_count
	next_button.pressed.connect(_on_next)

func _on_next() -> void:
	GameState.question_count = int(spin.value)
	GameState.advance_phase(GameState.Phase.NEW_OR_CONTINUE)
	get_tree().change_scene_to_file("res://scenes/new_or_continue.tscn")
