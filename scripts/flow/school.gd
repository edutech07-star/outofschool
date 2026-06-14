extends Node2D
## 6. 학교 입장 → 7. 탐험 시작
##
## 픽셀아트 복도. 보라색 문 앞에서 [Space] 키로 교실(퍼즐) 진입.
## 탐험 중 SpaceDistortion / AnomalySystem 이 활성화되고
## 일정 조건(문 진입) 충족 시 8. 퍼즐/문제가 등장한다.

@onready var space_distortion: Node = $Systems/SpaceDistortion
@onready var anomaly_system: Node = $Systems/AnomalySystem
@onready var hint_system: Node = $Systems/HintSystem
@onready var door_area: Area2D = $Door/DoorArea
@onready var door_light: PointLight2D = $Door/DoorLight
@onready var enter_prompt: Label = $HUD/EnterPrompt
@onready var info_label: Label = $HUD/Info
@onready var fragment_counter: Label = $HUD/FragmentCounter
@onready var stage_label: Label = $HUD/StageLabel
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# 스테이지별 분위기 색상 - 층마다 색조가 변한다 (핑크 톤 배제).
const STAGE_TINTS := [
	Color(0.30, 0.26, 0.42, 1),  # Stage 1 - 보라
	Color(0.22, 0.32, 0.42, 1),  # Stage 2 - 청록 (지하)
	Color(0.36, 0.18, 0.15, 1),  # Stage 3 - 적암 (악몽, 깊은 적갈)
	Color(0.20, 0.36, 0.30, 1),  # Stage 4 - 녹암
	Color(0.40, 0.30, 0.18, 1),  # Stage 5 - 황혼
]
const DOOR_LIGHT_TINTS := [
	Color(0.65, 0.45, 1, 1),     # 1 - 보라 광원
	Color(0.4, 0.85, 1, 1),      # 2 - 청록 광원
	Color(1, 0.35, 0.15, 1),     # 3 - 핏빛 (붉은 주황)
	Color(0.5, 1, 0.7, 1),       # 4 - 독한 녹
	Color(1, 0.7, 0.35, 1),      # 5 - 황혼
]

var _solved_count: int = 0
var _player_in_doorway: bool = false
var _pulse_time: float = 0.0

func _ready() -> void:
	var cfg := DifficultyConfig.get_config(GameState.difficulty)
	space_distortion.apply_config(cfg)
	anomaly_system.apply_config(cfg)
	hint_system.apply_config(cfg)

	# 학교 입장 직후에는 탐험으로 전환되지만, 문제는 아직 등장하지 않음.
	GameState.advance_phase(GameState.Phase.EXPLORATION)

	door_area.body_entered.connect(_on_door_body_entered)
	door_area.body_exited.connect(_on_door_body_exited)
	enter_prompt.visible = false

	# 이상 현상 - AnomalySystem 시그널과 BGM 연동.
	if anomaly_system.has_signal("music_cutoff"):
		anomaly_system.music_cutoff.connect(_on_music_cutoff)
	if anomaly_system.has_signal("lighting_glitch"):
		anomaly_system.lighting_glitch.connect(_on_lighting_glitch)

	# 열쇠 조각 카운터 동기화.
	_update_fragment_counter(GameState.key_fragments, GameState.question_count)
	GameState.fragment_collected.connect(_update_fragment_counter)

	# 스테이지별 분위기 적용.
	_apply_stage_tint(GameState.stage_index)
	stage_label.text = "STAGE %d  ·  %s" % [GameState.stage_index, GameState.topic if GameState.topic != "" else GameState.subject]

	# 몽환 복도 BGM 시작.
	AmbientMusic.play_mood("corridor")

func _process(delta: float) -> void:
	# 문 광원이 살아 숨쉬듯 천천히 깜빡인다.
	_pulse_time += delta
	door_light.energy = 1.05 + sin(_pulse_time * 1.4) * 0.25
	# 플레이어가 가까이 가면 프롬프트가 살짝 흔들린다 - 몽환적 글리치.
	if _player_in_doorway:
		enter_prompt.modulate.a = 0.75 + 0.25 * sin(_pulse_time * 6.0)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_doorway:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_enter_classroom()

func _on_door_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_doorway = true
	enter_prompt.visible = true
	door_light.energy = 1.8

func _on_door_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_doorway = false
	enter_prompt.visible = false

func _enter_classroom() -> void:
	if _solved_count >= GameState.question_count:
		info_label.text = "오늘의 문제를 모두 풀었다... 학교가 너를 놓아준다."
		return
	GameState.advance_phase(GameState.Phase.PUZZLE)
	get_tree().change_scene_to_file("res://scenes/puzzle.tscn")

func _on_music_cutoff() -> void:
	AmbientMusic.cut_music_briefly(1.2)

func _on_lighting_glitch() -> void:
	# 짧은 암전 - 몽환 효과. 복귀 색은 현재 스테이지 톤으로.
	var stage_color := _get_stage_tint(GameState.stage_index)
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.05, 0.04, 0.08, 1), 0.05)
	tween.tween_property(canvas_modulate, "color", stage_color, 0.4)

func _apply_stage_tint(idx: int) -> void:
	canvas_modulate.color = _get_stage_tint(idx)
	door_light.color = _get_door_tint(idx)

func _get_stage_tint(idx: int) -> Color:
	var i := clamp(idx - 1, 0, STAGE_TINTS.size() - 1)
	return STAGE_TINTS[i]

func _get_door_tint(idx: int) -> Color:
	var i := clamp(idx - 1, 0, DOOR_LIGHT_TINTS.size() - 1)
	return DOOR_LIGHT_TINTS[i]

func on_puzzle_solved() -> void:
	_solved_count += 1
	GameState.advance_phase(GameState.Phase.EXPLORATION)
