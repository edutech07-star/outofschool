extends Control
## 스테이지 클리어 전환.
##
## 열쇠 조각을 모두 모은 직후 표시되는 짧은 연출.
## 끝나면 GameState.advance_stage() 후 다음 학교(같은 씬, 다른 무드) 로 이동.

@onready var stage_label: Label = $StageLabel
@onready var sub_label: Label = $SubLabel
@onready var key_icon: Polygon2D = $KeyIcon
@onready var glow_burst: TextureRect = $GlowBurst

var _advanced: bool = false

func _ready() -> void:
	stage_label.text = "STAGE %d CLEAR" % GameState.stage_index
	AmbientMusic.play_mood("classroom")
	DreamSFX.play("bell", 1.0, -2.0)

	# 등장 시퀀스.
	var t := create_tween().set_parallel(true)
	t.tween_property(key_icon, "modulate:a", 1.0, 0.6)
	t.tween_property(key_icon, "scale", Vector2(4.5, 4.5), 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(stage_label, "modulate:a", 1.0, 0.8).set_delay(0.5)
	t.tween_property(sub_label, "modulate:a", 1.0, 0.8).set_delay(0.9)
	t.tween_property(glow_burst, "modulate:a", 0.6, 1.2).set_delay(0.3)
	t.tween_property(glow_burst, "modulate:a", 0.0, 0.9).set_delay(1.5)

	await get_tree().create_timer(0.8).timeout
	if _advanced or not is_inside_tree(): return
	DreamSFX.play("chime", 1.0, -4.0)
	await get_tree().create_timer(1.6).timeout
	if _advanced or not is_inside_tree(): return
	DreamSFX.play("dream_in", 0.85, -4.0)
	await get_tree().create_timer(1.6).timeout
	if _advanced or not is_inside_tree(): return
	_to_next_stage()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_to_next_stage()

func _to_next_stage() -> void:
	if _advanced:
		return
	_advanced = true
	GameState.advance_stage()
	GameState.advance_phase(GameState.Phase.SCHOOL_ENTRY)
	get_tree().change_scene_to_file("res://scenes/school.tscn")
