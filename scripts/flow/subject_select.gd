extends Control
## 2. 과목 선택
##
## 로그인에서 선택한 학년을 GradeBadge 에 표시.
## 5개 과목 버튼 중 하나 → TOPIC_SELECT 로 진행.

@onready var grade_badge: Label = $VBox/GradeBadge
@onready var grid: GridContainer = $VBox/Grid

func _ready() -> void:
	# 학년이 비어있으면 (디버그 시작 등) 로그인으로 돌려보낸다.
	if GameState.grade == "":
		get_tree().change_scene_to_file("res://scenes/login.tscn")
		return

	grade_badge.text = "[%s]" % GameState.grade

	for btn in grid.get_children():
		if btn is Button:
			var subj: String = btn.text
			btn.pressed.connect(_on_pick_subject.bind(subj))

func _on_pick_subject(subject: String) -> void:
	GameState.subject = subject
	GameState.advance_phase(GameState.Phase.TOPIC_SELECT)
	DreamSFX.play("chime", 1.3, -8.0)
	get_tree().change_scene_to_file("res://scenes/topic_select.tscn")
