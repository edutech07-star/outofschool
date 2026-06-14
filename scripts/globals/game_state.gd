extends Node
## 전역 게임 상태.
##
## 중요 규칙:
##   난이도 선택은 게임 시작 전에만 가능하다.
##   게임 진행 중에는 난이도를 변경할 수 없다.
##
## 진행 흐름:
##   1. 로그인(학년 선택)  2. 과목  3. 단원  4. 난이도  5. 문제 개수
##   6. 새 게임/이어하기  7. 학교 입장  8. 탐험  9. 퍼즐
##
## 열쇠 조각:
##   문제를 맞힐 때마다 collect_fragment() 호출.
##   전체 question_count 만큼 모으면 all_fragments_collected 시그널 →
##   stage_clear 화면 → 다음 스테이지(다음 층) 로 진행.
##
## 중복 회피:
##   recent_questions / recent_answers 에 최근 N개 기록.
##   ClaudeAPI 가 프롬프트에 회피 리스트로 포함한다.

signal difficulty_locked(difficulty: int)
signal phase_changed(phase: int)
signal fragment_collected(count: int, total: int)
signal all_fragments_collected
signal stage_advanced(new_stage: int)

enum Phase {
	LOGIN,                 # 0
	SUBJECT_SELECT,        # 1
	TOPIC_SELECT,          # 2
	DIFFICULTY_SELECT,     # 3
	QUESTION_COUNT_SELECT, # 4
	NEW_OR_CONTINUE,       # 5
	SCHOOL_ENTRY,          # 6
	EXPLORATION,           # 7
	PUZZLE,                # 8
}

const RECENT_LIMIT := 30

var grade: String = ""
var subject: String = ""
var topic: String = ""
var difficulty: int = DifficultyConfig.Difficulty.NORMAL
var question_count: int = 10
var user_id: String = ""
var key_fragments: int = 0
var stage_index: int = 1
var recent_questions: Array = []
var recent_answers: Array = []
var recent_choice_sets: Array = []

var _phase: int = Phase.LOGIN
var _difficulty_locked: bool = false

func current_phase() -> int:
	return _phase

func is_difficulty_locked() -> bool:
	return _difficulty_locked

func set_difficulty(new_difficulty: int) -> bool:
	if _difficulty_locked:
		push_warning("난이도 변경 불가: 게임이 이미 시작됨")
		return false
	difficulty = new_difficulty
	return true

func advance_phase(next_phase: int) -> void:
	_phase = next_phase
	if next_phase == Phase.SCHOOL_ENTRY and not _difficulty_locked:
		_difficulty_locked = true
		difficulty_locked.emit(difficulty)
	phase_changed.emit(next_phase)

func can_spawn_question() -> bool:
	return _phase >= Phase.EXPLORATION

func collect_fragment() -> void:
	key_fragments += 1
	fragment_collected.emit(key_fragments, question_count)
	if key_fragments >= question_count:
		all_fragments_collected.emit()

func has_all_fragments() -> bool:
	return key_fragments >= question_count

func fragment_progress() -> String:
	return "%d / %d" % [key_fragments, question_count]

func advance_stage() -> void:
	stage_index += 1
	key_fragments = 0
	# 새 스테이지에서는 이전 회피 목록도 비워 다른 문제 풀을 가능하게 한다.
	recent_questions.clear()
	recent_answers.clear()
	recent_choice_sets.clear()
	stage_advanced.emit(stage_index)

func add_recent_question(text: String) -> void:
	if text == "":
		return
	recent_questions.append(text)
	while recent_questions.size() > RECENT_LIMIT:
		recent_questions.pop_front()

func add_recent_answer(text: String) -> void:
	if text == "":
		return
	recent_answers.append(text)
	while recent_answers.size() > RECENT_LIMIT:
		recent_answers.pop_front()

func add_recent_choice_set(joined: String) -> void:
	if joined == "":
		return
	recent_choice_sets.append(joined)
	while recent_choice_sets.size() > RECENT_LIMIT:
		recent_choice_sets.pop_front()

func reset() -> void:
	grade = ""
	subject = ""
	topic = ""
	difficulty = DifficultyConfig.Difficulty.NORMAL
	question_count = 10
	user_id = ""
	key_fragments = 0
	stage_index = 1
	recent_questions.clear()
	recent_answers.clear()
	recent_choice_sets.clear()
	_phase = Phase.LOGIN
	_difficulty_locked = false
