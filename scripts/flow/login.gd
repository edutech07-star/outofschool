extends Control
## 1. 로그인 + 학년 선택
##
## ID 와 학년이 모두 선택되어야 [탈출 시작] 버튼이 활성화된다.
## 이후 SUBJECT_SELECT 로 진행.
## 절대 여기서 ClaudeAPI.request_question() 호출하지 않는다.

@onready var id_input: LineEdit = $VBox/IdInput
@onready var login_button: Button = $VBox/LoginButton
@onready var selected_label: Label = $VBox/SelectedLabel

@onready var _grade_buttons := {
	"중학교 1학년": $VBox/GradeGrid/GradeM1,
	"중학교 2학년": $VBox/GradeGrid/GradeM2,
	"중학교 3학년": $VBox/GradeGrid/GradeM3,
	"고등학교 1학년": $VBox/GradeGrid/GradeH1,
	"고등학교 2학년": $VBox/GradeGrid/GradeH2,
	"고등학교 3학년": $VBox/GradeGrid/GradeH3,
}

var _picked_grade: String = ""

func _ready() -> void:
	for grade_name in _grade_buttons.keys():
		var btn: Button = _grade_buttons[grade_name]
		btn.pressed.connect(_on_pick_grade.bind(grade_name))
	id_input.text_changed.connect(_on_id_changed)
	login_button.pressed.connect(_on_login)
	_refresh()

func _on_pick_grade(grade_name: String) -> void:
	_picked_grade = grade_name
	DreamSFX.play("chime", 1.4, -10.0)
	for k in _grade_buttons.keys():
		var b: Button = _grade_buttons[k]
		b.modulate = Color(1, 0.92, 0.7, 1) if k == grade_name else Color(1, 1, 1, 1)
	_refresh()

func _on_id_changed(_t: String) -> void:
	_refresh()

func _refresh() -> void:
	var id_text := id_input.text.strip_edges()
	var ok := id_text != "" and _picked_grade != ""
	login_button.disabled = not ok
	if _picked_grade == "":
		selected_label.text = "학년을 선택하세요"
	elif id_text == "":
		selected_label.text = "[%s] 선택됨 — ID 를 입력하세요" % _picked_grade
	else:
		selected_label.text = "%s · %s" % [_picked_grade, id_text]

func _on_login() -> void:
	var uid := id_input.text.strip_edges()
	if uid == "" or _picked_grade == "":
		return
	GameState.user_id = uid
	GameState.grade = _picked_grade
	GameState.advance_phase(GameState.Phase.SUBJECT_SELECT)
	DreamSFX.play("dream_in", 1.0, -6.0)
	get_tree().change_scene_to_file("res://scenes/subject_select.tscn")
