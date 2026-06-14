extends Node
## 절차 생성 몽환 효과음.
##
## AudioStreamWAV 로 16비트 PCM 을 미리 굽고, 8채널 폴리포닉 플레이어 풀에서 재생.
## 외부 음원 파일 없이 동작하므로 배포가 가볍다.
##
## 사용:
##   DreamSFX.play("pickup")
##   DreamSFX.play("chime", 1.5)  # 1.5배 피치

const MIX_RATE := 22050
const POLY_COUNT := 8

var _sounds: Dictionary = {}
var _players: Array = []
var _next_player: int = 0

func _ready() -> void:
	for i in POLY_COUNT:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)

	_sounds["pickup"] = _bake_arpeggio([523.25, 659.25, 783.99, 1046.50], 0.16, 0.9, 4.0)
	_sounds["chime"] = _bake_chime(880.0, 1.4, 3.0)
	_sounds["bell"] = _bake_chime(523.25, 2.5, 1.8)
	_sounds["wrong"] = _bake_drone(82.41, 0.9)
	_sounds["whoosh"] = _bake_whoosh(0.7)
	_sounds["glitch"] = _bake_glitch(0.18)
	_sounds["dream_in"] = _bake_sweep(220.0, 880.0, 1.2)
	_sounds["dream_out"] = _bake_sweep(880.0, 110.0, 1.0)
	_sounds["heartbeat"] = _bake_heartbeat(0.6)

func play(sound_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream = _sounds.get(sound_name)
	if stream == null:
		push_warning("알 수 없는 SFX: %s" % sound_name)
		return
	var p: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()

# === SFX 베이커 ===

func _bake_chime(freq: float, duration: float, decay: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var env := exp(-t * decay)
		var s := sin(t * freq * TAU) * 0.55
		s += sin(t * freq * 2.01 * TAU) * 0.25
		s += sin(t * freq * 3.03 * TAU) * 0.12
		s += sin(t * freq * 4.07 * TAU) * 0.06
		s *= env * 0.65
		bytes.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767.0))
	return _wav(bytes)

func _bake_arpeggio(freqs: Array, note_dur: float, total: float, decay: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * total)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var idx := int(t / note_dur)
		if idx >= freqs.size():
			idx = freqs.size() - 1
		var note_t := t - float(idx) * note_dur
		var env := exp(-note_t * decay)
		var freq: float = freqs[idx]
		var s := sin(note_t * freq * TAU) * 0.55
		s += sin(note_t * freq * 2.0 * TAU) * 0.22
		s += sin(note_t * freq * 3.0 * TAU) * 0.1
		s *= env * 0.55
		bytes.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767.0))
	return _wav(bytes)

func _bake_drone(freq: float, duration: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var phase := 0.0
	var inv_rate := TAU / float(MIX_RATE)
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var env := min(t * 5.0, 1.0) * exp(-t * 2.2)
		var wobble := sin(t * 9.0) * 4.0
		phase = fposmod(phase + (freq + wobble) * inv_rate, TAU)
		var s := sin(phase) * 0.5 + sin(phase * 1.5) * 0.18
		s *= env * 0.55
		bytes.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767.0))
	return _wav(bytes)

func _bake_whoosh(duration: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var lp := 0.0
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var u := t / duration
		var env := sin(PI * u)
		var noise := randf() * 2.0 - 1.0
		# 로우패스 컷오프가 가운데에서 가장 열림.
		var alpha := 0.04 + 0.5 * env
		lp = lerp(lp, noise, alpha)
		var s := lp * env * 0.5
		bytes.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767.0))
	return _wav(bytes)

func _bake_glitch(duration: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var env := 1.0 - t / duration
		# 비트크러시 + 노이즈 - 글리치 느낌.
		var s := (randf() * 2.0 - 1.0) * 0.6
		if int(t * 4000.0) % 3 == 0:
			s = -s
		s *= env * 0.45
		bytes.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767.0))
	return _wav(bytes)

func _bake_sweep(start_freq: float, end_freq: float, duration: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var phase := 0.0
	var inv_rate := TAU / float(MIX_RATE)
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var u := t / duration
		var env := sin(PI * u) * 0.7
		var freq := lerp(start_freq, end_freq, u)
		phase = fposmod(phase + freq * inv_rate, TAU)
		var s := sin(phase) * 0.5 + sin(phase * 1.5) * 0.2
		s *= env
		bytes.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767.0))
	return _wav(bytes)

func _bake_heartbeat(duration: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / float(MIX_RATE)
		var beat1 := exp(-pow((t - 0.05) * 18.0, 2.0))
		var beat2 := exp(-pow((t - 0.18) * 22.0, 2.0)) * 0.75
		var env := beat1 + beat2
		var s := sin(t * 55.0 * TAU) * env * 0.7
		bytes.encode_s16(i * 2, int(clamp(s, -1.0, 1.0) * 32767.0))
	return _wav(bytes)

func _wav(bytes: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = bytes
	return w
