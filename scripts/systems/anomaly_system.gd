extends Node
## 이상 현상: 조명 깜빡임, 방송 노이즈, 환영, 음악 중단.

signal lighting_glitch
signal broadcast_noise
signal phantom_appeared
signal music_cutoff

var anomaly_frequency: float = 0.0
var lighting_glitch_rate: float = 0.0
var broadcast_noise_rate: float = 0.0
var phantom_rate: float = 0.0
var music_cutoff_enabled: bool = false

var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 5.0
	_timer.autostart = true
	_timer.timeout.connect(_tick)
	add_child(_timer)

func apply_config(cfg: Dictionary) -> void:
	anomaly_frequency = cfg["anomaly_frequency"]
	lighting_glitch_rate = cfg["lighting_glitch_rate"]
	broadcast_noise_rate = cfg["broadcast_noise_rate"]
	phantom_rate = cfg["phantom_rate"]
	music_cutoff_enabled = cfg["music_cutoff_enabled"]

func _tick() -> void:
	if randf() >= anomaly_frequency:
		return
	if randf() < lighting_glitch_rate:
		lighting_glitch.emit()
	if randf() < broadcast_noise_rate:
		broadcast_noise.emit()
	if randf() < phantom_rate:
		phantom_appeared.emit()
	if music_cutoff_enabled and randf() < 0.2:
		music_cutoff.emit()
