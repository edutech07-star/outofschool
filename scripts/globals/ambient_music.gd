extends Node
## 절차 생성 몽환 앰비언트 BGM.
##
## AudioStreamGenerator 로 사인파 코드를 합성한다.
## 외부 음원 파일 없이 동작하므로 배포가 가볍다.
##
## 씬별로 분위기를 다르게 깔 수 있다:
##   play_mood("corridor")  - 학교 복도: 낮은 드론, 불안한 5도
##   play_mood("classroom") - 교실:     떠다니는 메이저7 코드

const MOODS := {
	"corridor": {
		"voices": [82.41, 110.0, 123.47, 164.81],   # E2, A2, B2, E3
		"detune": 0.3,
		"target_amp": 0.18,
		"tremolo_hz": 0.12,
	},
	"classroom": {
		"voices": [146.83, 220.0, 277.18, 329.63, 415.30], # D3, A3, C#4, E4, G#4
		"detune": 0.5,
		"target_amp": 0.16,
		"tremolo_hz": 0.18,
	},
	"silent": {
		"voices": [110.0],
		"detune": 0.0,
		"target_amp": 0.0,
		"tremolo_hz": 0.0,
	},
}

const MIX_RATE := 22050.0
const BUFFER_SECS := 0.1

var _generator: AudioStreamGenerator
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback = null

var _voices: Array = []
var _phase: Array = []
var _detune: float = 0.3
var _tremolo_hz: float = 0.15

var _amp: float = 0.0
var _target_amp: float = 0.0
var _time: float = 0.0

# 이상 현상 - AnomalySystem 의 music_cutoff 시그널에 연결 가능.
var _cutoff: float = 1.0
var _cutoff_target: float = 1.0

func _ready() -> void:
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = MIX_RATE
	_generator.buffer_length = BUFFER_SECS
	_player = AudioStreamPlayer.new()
	_player.stream = _generator
	_player.bus = &"Master"
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()
	_apply_mood(MOODS["corridor"])

func play_mood(mood_name: String) -> void:
	if not MOODS.has(mood_name):
		push_warning("알 수 없는 BGM 분위기: %s" % mood_name)
		return
	_apply_mood(MOODS[mood_name])

func cut_music_briefly(duration: float = 0.8) -> void:
	# AnomalySystem.music_cutoff 와 연결하기 위한 헬퍼.
	_cutoff_target = 0.0
	await get_tree().create_timer(duration).timeout
	_cutoff_target = 1.0

func _apply_mood(cfg: Dictionary) -> void:
	var new_voices: Array = cfg["voices"]
	_voices = new_voices.duplicate()
	_phase.resize(_voices.size())
	for i in _phase.size():
		if _phase[i] == null:
			_phase[i] = randf() * TAU
	_detune = float(cfg["detune"])
	_target_amp = float(cfg["target_amp"])
	_tremolo_hz = float(cfg["tremolo_hz"])

func _process(delta: float) -> void:
	if _playback == null:
		return
	_amp = lerp(_amp, _target_amp, delta * 0.6)
	_cutoff = lerp(_cutoff, _cutoff_target, delta * 4.0)
	_time += delta

	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var n := _voices.size()
	if n == 0:
		return
	var inv_rate := TAU / MIX_RATE

	for _i in frames:
		var sample := 0.0
		for v in n:
			var base_freq: float = _voices[v]
			# 매우 느린 디튠 와블 - 몽환적 느낌의 핵심.
			var wobble := sin(_time * (0.07 + v * 0.013)) * _detune
			var freq := base_freq + wobble
			_phase[v] = fposmod(_phase[v] + freq * inv_rate, TAU)
			# 사인 + 약한 3차 하모닉 - 따뜻한 패드 톤.
			var s := sin(_phase[v]) * 0.85 + sin(_phase[v] * 3.0) * 0.12
			sample += s / float(n)
		# 느린 트레몰로로 호흡감 추가.
		var tremolo := 0.65 + 0.35 * sin(_time * TAU * _tremolo_hz)
		sample *= _amp * tremolo * _cutoff
		# 소프트 클립으로 디스토션 방지.
		sample = clamp(sample, -1.0, 1.0)
		_playback.push_frame(Vector2(sample, sample))
