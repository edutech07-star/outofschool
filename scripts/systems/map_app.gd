extends Control
## 상단 맵 앱 (미니맵 HUD).
##
## 학교 화면 최상단에 상시 표시되는 맵.
## 난이도에 따라:
##   - EASY: 정확한 맵, 플레이어 위치 표시, 목표 표시
##   - NORMAL: 맵 일부 흐림, 가끔 노이즈
##   - HARD: 맵 자주 왜곡, 위치 표시 부정확, 가끔 잘못된 정보 표시

@onready var map_rect: ColorRect = $Panel/MapRect
@onready var player_dot: ColorRect = $Panel/MapRect/PlayerDot
@onready var status_label: Label = $Panel/StatusLabel
@onready var glitch_overlay: ColorRect = $Panel/MapRect/GlitchOverlay

var _distortion: float = 0.0
var _anomaly: float = 0.0
var _map_size: Vector2 = Vector2(400, 80)
var _world_size: Vector2 = Vector2(2000, 1200)

func _ready() -> void:
	var cfg := DifficultyConfig.get_config(GameState.difficulty)
	_distortion = cfg["space_distortion"]
	_anomaly = cfg["anomaly_frequency"]
	status_label.text = "[MAP] %s | %s" % [cfg["label"], GameState.subject]
	glitch_overlay.color = Color(1, 0, 0, 0)
	set_process(true)

func _process(_delta: float) -> void:
	var player := _find_player()
	if player == null:
		return
	var p := player.global_position
	# HARD 난이도일수록 위치 표시에 노이즈 추가.
	var noise := Vector2(
		randf_range(-1.0, 1.0) * _distortion * 20.0,
		randf_range(-1.0, 1.0) * _distortion * 20.0,
	)
	var ratio := (p + noise) / _world_size
	player_dot.position = Vector2(
		clamp(ratio.x, 0.0, 1.0) * _map_size.x,
		clamp(ratio.y, 0.0, 1.0) * _map_size.y,
	)
	# 이상 현상: 일정 확률로 글리치 오버레이 깜빡임.
	if randf() < _anomaly * 0.01:
		glitch_overlay.color = Color(1, 0, 0, randf_range(0.1, 0.4))
		await get_tree().create_timer(0.1).timeout
		glitch_overlay.color = Color(1, 0, 0, 0)

func _find_player() -> Node2D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0]
