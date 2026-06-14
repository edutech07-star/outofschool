extends Control
## 8. 퍼즐/문제 등장 - 몽환 교실.
##
## 가드: GameState.can_spawn_question() 가 false면 즉시 종료.
## 정답을 맞히면 GameState.collect_fragment() 로 열쇠 조각을 모은다.
## 모두 모으면 stage_clear 화면으로 전환 → 다음 스테이지.

@onready var question_label: Label = $VBox/QuestionLabel
@onready var choices_box: VBoxContainer = $VBox/ChoicesBox
@onready var hint_button: Button = $VBox/HintButton
@onready var hint_label: Label = $VBox/HintLabel
@onready var status_label: Label = $VBox/StatusLabel
@onready var fragment_counter: Label = $HUD/FragmentCounter
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var board_light: PointLight2D = $BoardLight
@onready var chalk_sub_text: Label = $ChalkSubText
@onready var desks_node: Node2D = $DesksNode

var _current: Dictionary = {}
var _time: float = 0.0
var _resolved: bool = false

func _ready() -> void:
	if not GameState.can_spawn_question():
		push_error("탐험 이전 단계 - 문제 생성 금지")
		get_tree().change_scene_to_file("res://scenes/school.tscn")
		return

	AmbientMusic.play_mood("classroom")
	DreamSFX.play("dream_in", 1.0, -4.0)

	_update_fragment_counter(GameState.key_fragments, GameState.question_count)
	GameState.fragment_collected.connect(_update_fragment_counter)

	status_label.text = "문제 생성 중..."
	hint_button.pressed.connect(_on_hint)
	ClaudeAPI.question_ready.connect(_on_question_ready)
	ClaudeAPI.question_failed.connect(_on_question_failed)
	ClaudeAPI.request_question()

func _process(delta: float) -> void:
	_time += delta
	if desks_node:
		desks_node.position.y = sin(_time * 0.8) * 3.0
		desks_node.position.x = cos(_time * 0.6) * 2.0
	if board_light:
		board_light.energy = 0.85 + sin(_time * 0.9) * 0.18
	if chalk_sub_text:
		chalk_sub_text.modulate.a = 0.35 + 0.3 * sin(_time * 0.5)

func _on_question_ready(q: Dictionary) -> void:
	_current = q
	_resolved = false
	status_label.text = ""
	status_label.modulate = Color(0.85, 0.95, 1, 1)
	question_label.text = q.get("question", "")
	DreamSFX.play("chime", 1.2, -6.0)

	for child in choices_box.get_children():
		child.queue_free()
	var choices: Array = q.get("choices", [])
	for i in choices.size():
		var b := Button.new()
		b.text = "  %d.  %s" % [i + 1, choices[i]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_pick.bind(i))
		choices_box.add_child(b)

	var cfg := DifficultyConfig.get_config(GameState.difficulty)
	hint_button.visible = randf() < cfg["hint_frequency"]
	hint_label.text = ""

func _on_question_failed(err: String) -> void:
	question_label.text = ""
	for child in choices_box.get_children():
		child.queue_free()
	hint_button.visible = false
	hint_label.text = ""
	status_label.modulate = Color(1, 0.78, 0.45, 1)
	status_label.text = "문제 생성 실패\n" + err
	DreamSFX.play("glitch")

func _on_pick(index: int) -> void:
	if _resolved:
		return
	_resolved = true
	var correct: int = _current.get("answer_index", 0)
	var cfg := DifficultyConfig.get_config(GameState.difficulty)

	if index == correct:
		status_label.text = "✦ 정답 — 열쇠 조각을 얻었다..."
		status_label.modulate = Color(0.75, 1, 0.85, 1)
		DreamSFX.play("pickup")
		GameState.collect_fragment()
		var school := get_tree().root.get_node_or_null("School")
		if school and school.has_method("on_puzzle_solved"):
			school.on_puzzle_solved()
	else:
		status_label.text = "오답... 교실이 일그러진다."
		status_label.modulate = Color(1, 0.78, 0.45, 1)
		DreamSFX.play("wrong")
		_glitch_classroom()

	if cfg["question_difficulty"] == "easy":
		status_label.text += "\n" + str(_current.get("explanation", ""))

	await get_tree().create_timer(2.2).timeout

	if GameState.has_all_fragments():
		_advance_to_stage_clear()
		return

	DreamSFX.play("dream_out", 1.0, -4.0)
	get_tree().change_scene_to_file("res://scenes/school.tscn")

func _on_hint() -> void:
	hint_label.text = str(_current.get("hint", ""))
	DreamSFX.play("chime", 1.6, -10.0)

func _update_fragment_counter(count: int, total: int) -> void:
	fragment_counter.text = "✦ 열쇠 조각 %d / %d" % [count, total]
	var t := create_tween()
	t.tween_property(fragment_counter, "modulate", Color(1, 1, 0.8, 1), 0.1)
	t.tween_property(fragment_counter, "modulate", Color(1, 0.85, 0.55, 0.95), 0.4)

func _glitch_classroom() -> void:
	var t := create_tween()
	t.tween_property(canvas_modulate, "color", Color(0.12, 0.1, 0.18, 1), 0.08)
	t.tween_property(canvas_modulate, "color", Color(0.35, 0.32, 0.45, 1), 0.12)
	t.tween_property(canvas_modulate, "color", Color(0.52, 0.44, 0.72, 1), 0.5)
	AmbientMusic.cut_music_briefly(0.7)

func _advance_to_stage_clear() -> void:
	DreamSFX.play("bell", 1.0, -2.0)
	DreamSFX.play("bell", 1.5, -6.0)
	get_tree().change_scene_to_file("res://scenes/stage_clear.tscn")
