extends Control
## 3. 단원 선택
##
## Curriculum 에서 (학년, 과목) 의 단원 목록을 받아 버튼으로 표시.
## 선택 → DIFFICULTY_SELECT.

@onready var grade_badge: Label = $Header/GradeBadge
@onready var subject_badge: Label = $Header/SubjectBadge
@onready var topic_grid: GridContainer = $ScrollContainer/TopicGrid
@onready var back_button: Button = $BackButton

func _ready() -> void:
	if GameState.grade == "" or GameState.subject == "":
		get_tree().change_scene_to_file("res://scenes/subject_select.tscn")
		return

	grade_badge.text = "[%s]" % GameState.grade
	subject_badge.text = GameState.subject

	var topics: Array = Curriculum.topics_for(GameState.grade, GameState.subject)
	for topic_name in topics:
		var b := Button.new()
		b.text = str(topic_name)
		b.custom_minimum_size = Vector2(430, 60)
		b.pressed.connect(_on_pick_topic.bind(str(topic_name)))
		topic_grid.add_child(b)

	back_button.pressed.connect(_on_back)

func _on_pick_topic(topic_name: String) -> void:
	GameState.topic = topic_name
	GameState.advance_phase(GameState.Phase.DIFFICULTY_SELECT)
	DreamSFX.play("chime", 1.2, -8.0)
	get_tree().change_scene_to_file("res://scenes/difficulty_select.tscn")

func _on_back() -> void:
	GameState.advance_phase(GameState.Phase.SUBJECT_SELECT)
	get_tree().change_scene_to_file("res://scenes/subject_select.tscn")
