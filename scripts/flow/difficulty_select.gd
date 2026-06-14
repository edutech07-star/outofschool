extends Control
## 2. 난이도 선택
##
## 중요 규칙:
##   난이도 선택은 게임 시작 전에만 가능하다.
##   게임 진행 중에는 변경할 수 없다 (GameState.is_difficulty_locked).

@onready var easy_button: Button = $VBox/EasyButton
@onready var normal_button: Button = $VBox/NormalButton
@onready var hard_button: Button = $VBox/HardButton
@onready var detail_label: Label = $VBox/DetailLabel

func _ready() -> void:
	if GameState.is_difficulty_locked():
		# 안전장치: 게임 진행 중 이 씬에 진입할 수 없음.
		push_warning("난이도 잠금 상태 - 변경 불가")
		_go_next()
		return
	easy_button.pressed.connect(_pick.bind(DifficultyConfig.Difficulty.EASY))
	normal_button.pressed.connect(_pick.bind(DifficultyConfig.Difficulty.NORMAL))
	hard_button.pressed.connect(_pick.bind(DifficultyConfig.Difficulty.HARD))
	easy_button.mouse_entered.connect(_show_detail.bind(DifficultyConfig.Difficulty.EASY))
	normal_button.mouse_entered.connect(_show_detail.bind(DifficultyConfig.Difficulty.NORMAL))
	hard_button.mouse_entered.connect(_show_detail.bind(DifficultyConfig.Difficulty.HARD))
	_show_detail(DifficultyConfig.Difficulty.NORMAL)

func _show_detail(difficulty: int) -> void:
	var cfg := DifficultyConfig.get_config(difficulty)
	detail_label.text = "[%s]\n%s\n추천: %s\n문제: %s" % [
		cfg["label"], cfg["description"], cfg["recommended"], cfg["question_style"],
	]

func _pick(difficulty: int) -> void:
	if not GameState.set_difficulty(difficulty):
		return
	_go_next()

func _go_next() -> void:
	GameState.advance_phase(GameState.Phase.QUESTION_COUNT_SELECT)
	get_tree().change_scene_to_file("res://scenes/question_count_select.tscn")
