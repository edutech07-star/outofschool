extends Node
## Claude API 클라이언트.
##
## 난이도별 프롬프트 템플릿에 학년/과목/단원/회피목록/시드를 치환해 문제를 생성한다.
## API 키는 OS 환경변수 ANTHROPIC_API_KEY 또는 user://api_key.txt 에서 읽는다.
##
## 중요: 로그인 직후가 아니라 탐험(EXPLORATION) 단계 이후에만 호출되어야 한다.
##
## 중복 방지(강화판):
##   - system 프롬프트로 다양성을 최우선 의무로 명시
##   - GameState.recent_questions  (문제 본문)
##   - GameState.recent_answers    (정답 텍스트)
##   - GameState.recent_choice_sets (모든 보기 묶음)
##   - 매 호출마다 출제 각도 / 소재 풀 / 정답 위치를 무작위로 강제
##   - nonce 로 캐시 회피

signal question_ready(question: Dictionary)
signal question_failed(error: String)

const API_URL := "https://api.anthropic.com/v1/messages"
const API_VERSION := "2023-06-01"
const MODEL := "claude-opus-4-7"
const MAX_TOKENS := 1024

const PROMPT_PATHS := {
	DifficultyConfig.Difficulty.EASY: "res://config/prompts/easy.txt",
	DifficultyConfig.Difficulty.NORMAL: "res://config/prompts/normal.txt",
	DifficultyConfig.Difficulty.HARD: "res://config/prompts/hard.txt",
}

const SYSTEM_PROMPT := """너는 한국 중·고교 학년별 교과서 범위 내에서 객관식 문제를 생성하는 출제자다.
너의 최우선 의무는 매 호출마다 의미·소재·접근법·정답·보기 표현이 확연히 다른 새로운 문제를 만드는 것이다.
사용자가 회피 목록을 주면 그 안의 어떤 항목과도 본질적으로 동일하거나 유사하면 안 된다.
같은 단원이라도 다음을 매번 다르게 골라라:
- 출제 각도 (수치 계산 / 개념 정의 / 사례 적용 / 비교 / 추론 / 함정 찾기 / 자료 해석 ...)
- 소재 (다루는 인물/숫자/사례/지역/대상/조건 등)
- 정답 보기의 위치 (answer_index)
- 보기 표현 (이전 보기와 동일한 단어/숫자/명사구를 재사용 금지)
- 문제 시작 어구
출력은 반드시 사용자가 지정한 JSON 한 덩어리만. 코드블록, 머리말, 해설 외부 텍스트 금지."""

const ANGLES := [
	"수치 계산 중심",
	"개념 정의 확인",
	"실생활·뉴스·일상 사례 적용",
	"두 개념의 차이점 식별",
	"두 개념의 공통점 식별",
	"원인-결과 추론",
	"오류 / 함정 찾기 (보기 중 잘못된 것)",
	"그래프 또는 표 해석",
	"용어와 정의 매칭",
	"단계적 풀이 과정의 빈칸 채우기",
	"보기 중 가장 적절하지 않은 것 고르기",
	"역사적·시대적 맥락 추론",
	"실험 결과 해석",
	"단위/조건 변환",
	"한 줄 짧은 지문 + 단답형 보기",
	"긴 지문(2~3줄) + 적절한 결론 고르기",
]

const MATERIAL_HINTS := [
	"숫자·수치 위주",
	"인물·사건 위주",
	"지역·지도 위주",
	"실험·관찰 자료",
	"실생활 가전·교통 사례",
	"날씨·계절·기후 사례",
	"사회 제도·법 사례",
	"문학 작품 구절",
	"신문 기사풍 짧은 글",
	"학생 대화 한 토막",
	"공학·기술 응용",
	"환경·생태 주제",
]

const ANSWER_POSITION_HINTS := [
	"이번 문제의 정답 보기 위치(answer_index)는 0이 되게.",
	"이번 문제의 정답 보기 위치(answer_index)는 1이 되게.",
	"이번 문제의 정답 보기 위치(answer_index)는 2가 되게.",
	"이번 문제의 정답 보기 위치(answer_index)는 3이 되게.",
]

var _http: HTTPRequest
var _api_key: String = ""

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_api_key = _load_api_key()

func _load_api_key() -> String:
	var env_key := OS.get_environment("ANTHROPIC_API_KEY")
	if env_key != "":
		return env_key
	var path := "user://api_key.txt"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f:
			return f.get_as_text().strip_edges()
	push_warning("ANTHROPIC_API_KEY 환경변수 또는 user://api_key.txt 가 필요합니다.")
	return ""

func request_question(_subject_unused: String = "") -> void:
	if not GameState.can_spawn_question():
		question_failed.emit("탐험 단계 이전에는 문제를 생성하지 않는다.")
		return
	if _api_key == "":
		question_failed.emit("API 키 없음")
		return

	var template := _load_prompt_template(GameState.difficulty)
	var prompt := _build_prompt(template)

	var body := {
		"model": MODEL,
		"max_tokens": MAX_TOKENS,
		"temperature": 1.0,
		"system": SYSTEM_PROMPT,
		"messages": [
			{"role": "user", "content": prompt},
		],
	}
	var headers := [
		"x-api-key: " + _api_key,
		"anthropic-version: " + API_VERSION,
		"content-type: application/json",
	]
	var err := _http.request(API_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		question_failed.emit("HTTPRequest 실패: %d" % err)

func _load_prompt_template(difficulty: int) -> String:
	var path: String = PROMPT_PATHS.get(difficulty, PROMPT_PATHS[DifficultyConfig.Difficulty.NORMAL])
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()

func _build_prompt(template: String) -> String:
	var grade := GameState.grade if GameState.grade != "" else "중학교 1학년"
	var subject := GameState.subject if GameState.subject != "" else "수학"
	var topic := GameState.topic if GameState.topic != "" else ""

	# 회피 목록 - 최근 출제 문제 + 정답 + 모든 보기 묶음.
	var avoid := ""
	if GameState.recent_questions.size() > 0 or GameState.recent_answers.size() > 0 or GameState.recent_choice_sets.size() > 0:
		avoid = "\n[중복 절대 금지]\n"
		if GameState.recent_questions.size() > 0:
			avoid += "다음 문제 본문들과 의미·구조·소재가 같거나 비슷한 문제는 금지:\n"
			for q in GameState.recent_questions:
				avoid += "- " + str(q) + "\n"
		if GameState.recent_answers.size() > 0:
			avoid += "다음 정답들과 본질적으로 동일한 정답이 나오는 문제 금지:\n"
			for a in GameState.recent_answers:
				avoid += "- " + str(a) + "\n"
		if GameState.recent_choice_sets.size() > 0:
			avoid += "다음 보기 묶음들 중 어떤 것과도 보기 단어·표현이 겹치면 안 됨:\n"
			for cs in GameState.recent_choice_sets:
				avoid += "- " + str(cs) + "\n"
		avoid += "\n위 목록과 완전히 다른 새로운 문제 1개만 출제한다.\n"

	# 랜덤 변형 강제.
	var angle: String = ANGLES[randi() % ANGLES.size()]
	var material: String = MATERIAL_HINTS[randi() % MATERIAL_HINTS.size()]
	var ans_pos: String = ANSWER_POSITION_HINTS[randi() % ANSWER_POSITION_HINTS.size()]
	var nonce := "%d-%d" % [Time.get_unix_time_from_system(), randi() % 1000000]

	var variation := "\n[변형 시드: %s]\n[출제 각도] %s\n[소재 성격] %s\n[정답 위치] %s\n[필수] 직전 문제와 표현·소재·정답·보기 어느 것도 절대 겹치지 말 것. 동일 단원 안에서도 다른 세부 주제·다른 숫자·다른 사례를 골라라.\n" % [nonce, angle, material, ans_pos]

	var out := template
	out = out.replace("{{GRADE}}", grade)
	out = out.replace("{{SUBJECT}}", subject)
	out = out.replace("{{TOPIC}}", topic)
	out = out.replace("{{AVOID_LIST}}", avoid)
	out = out.replace("{{VARIATION}}", variation)
	if not template.contains("{{AVOID_LIST}}"):
		out += avoid
	if not template.contains("{{VARIATION}}"):
		out += variation
	return out

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		question_failed.emit("HTTP %d: %s" % [response_code, body.get_string_from_utf8()])
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		question_failed.emit("응답 파싱 실패")
		return
	var content_list = parsed.get("content", [])
	if content_list.is_empty():
		question_failed.emit("응답 content 비어있음")
		return
	var text: String = content_list[0].get("text", "")
	text = text.strip_edges()
	if text.begins_with("```"):
		var first_nl := text.find("\n")
		if first_nl >= 0:
			text = text.substr(first_nl + 1)
		if text.ends_with("```"):
			text = text.substr(0, text.length() - 3)
	var question = JSON.parse_string(text.strip_edges())
	if typeof(question) != TYPE_DICTIONARY:
		question_failed.emit("문제 JSON 파싱 실패: " + text)
		return
	# 중복 회피를 위한 최근 기록.
	GameState.add_recent_question(str(question.get("question", "")))
	var choices: Array = question.get("choices", [])
	var ans_idx: int = int(question.get("answer_index", 0))
	if ans_idx >= 0 and ans_idx < choices.size():
		GameState.add_recent_answer(str(choices[ans_idx]))
	if choices.size() > 0:
		GameState.add_recent_choice_set(" / ".join(choices.map(func(c): return str(c))))
	question_ready.emit(question)
