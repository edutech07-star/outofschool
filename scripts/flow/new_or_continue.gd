extends Control
## 5. 새 게임 / 이어하기

@onready var new_button: Button = $VBox/NewGameButton
@onready var continue_button: Button = $VBox/ContinueButton

const SAVE_PATH := "user://save.json"

func _ready() -> void:
	new_button.pressed.connect(_on_new)
	continue_button.pressed.connect(_on_continue)
	continue_button.disabled = not FileAccess.file_exists(SAVE_PATH)

func _on_new() -> void:
	_enter_school()

func _on_continue() -> void:
	# 세이브 로드 자리: 난이도/과목/진행도 복원.
	# 단, 난이도는 잠금 상태로 유지.
	_enter_school()

func _enter_school() -> void:
	# 학교 입장 시점에 난이도가 잠긴다 (GameState.advance_phase에서 처리).
	GameState.advance_phase(GameState.Phase.SCHOOL_ENTRY)
	get_tree().change_scene_to_file("res://scenes/school.tscn")
