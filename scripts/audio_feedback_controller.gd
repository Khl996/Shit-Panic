class_name AudioFeedbackController
extends RefCounted

enum Cue {
	BUTTON_ACCEPTED,
	BUTTON_REJECTED,
	WARNING_ALARM,
	CRITICAL_ALARM,
	EVENT_RAISED,
	FAULT,
	WIN,
	LOSS,
	DRIP,
	SLIP,
	CLOCK_TICK,
}

const SAMPLE_RATE: int = 22050
const MASTER_VOLUME_DB: float = -12.0

var _players: Array[AudioStreamPlayer] = []
var _player_index: int = 0
var _streams: Dictionary = {}


func configure(parent: Node) -> void:
	for index: int in range(4):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "AudioFeedbackPlayer%d" % index
		player.volume_db = MASTER_VOLUME_DB
		parent.add_child(player)
		_players.append(player)
	_build_streams()


func play(cue: int) -> void:
	if _players.is_empty():
		return
	if not _streams.has(cue):
		return
	var player: AudioStreamPlayer = _players[_player_index]
	_player_index = (_player_index + 1) % _players.size()
	player.stream = _streams[cue]
	player.play()


func reset() -> void:
	for player: AudioStreamPlayer in _players:
		if is_instance_valid(player):
			player.stop()
	_player_index = 0


func _build_streams() -> void:
	_streams = {
		Cue.BUTTON_ACCEPTED: _make_layered_tone([720.0, 1440.0], [0.6, 0.4], 0.06, 0.25),
		Cue.BUTTON_REJECTED: _make_layered_tone([180.0, 90.0], [0.7, 0.5], 0.09, 0.28),
		Cue.WARNING_ALARM: _make_layered_two_tone(440.0, 660.0, 560.0, 840.0, 0.16, 0.22),
		Cue.CRITICAL_ALARM: _make_layered_two_tone(260.0, 130.0, 150.0, 75.0, 0.22, 0.32),
		Cue.EVENT_RAISED: _make_layered_two_tone(520.0, 780.0, 390.0, 585.0, 0.14, 0.24),
		Cue.FAULT: _make_layered_two_tone(120.0, 240.0, 90.0, 180.0, 0.18, 0.28),
		Cue.WIN: _make_layered_two_tone(620.0, 930.0, 920.0, 1380.0, 0.22, 0.24),
		Cue.LOSS: _make_layered_two_tone(210.0, 105.0, 90.0, 45.0, 0.42, 0.36),
		Cue.DRIP: _make_layered_tone([1100.0, 1650.0], [0.5, 0.3], 0.05, 0.18),
		Cue.SLIP: _make_layered_two_tone(620.0, 930.0, 220.0, 110.0, 0.32, 0.28),
		Cue.CLOCK_TICK: _make_layered_tone([1800.0, 900.0], [0.4, 0.6], 0.04, 0.16),
	}


func _make_two_tone(first_frequency: float, second_frequency: float, duration_seconds: float, amplitude: float) -> AudioStreamWAV:
	var half_duration: float = duration_seconds * 0.5
	return _make_tone_sequence([first_frequency, second_frequency], [half_duration, half_duration], amplitude)


func _make_tone(frequency: float, duration_seconds: float, amplitude: float) -> AudioStreamWAV:
	return _make_tone_sequence([frequency], [duration_seconds], amplitude)


func _make_layered_tone(frequencies: Array, weights: Array, duration_seconds: float, amplitude: float) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	var sample_count: int = maxi(int(float(SAMPLE_RATE) * duration_seconds), 1)
	for sample_index: int in range(sample_count):
		var fade_in: float = clampf(float(sample_index) / 80.0, 0.0, 1.0)
		var fade_out: float = clampf(float(sample_count - sample_index) / 120.0, 0.0, 1.0)
		var envelope: float = minf(fade_in, fade_out)
		var combined: float = 0.0
		for index: int in range(frequencies.size()):
			var frequency: float = float(frequencies[index])
			var weight: float = float(weights[index]) if index < weights.size() else 1.0
			combined += sin(TAU * frequency * float(sample_index) / float(SAMPLE_RATE)) * weight
		var sample: float = combined * amplitude * envelope
		var pcm_value: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		if pcm_value < 0:
			pcm_value = 65536 + pcm_value
		data.append(pcm_value & 0xff)
		data.append((pcm_value >> 8) & 0xff)
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _make_layered_two_tone(
	first_fundamental: float,
	first_harmonic: float,
	second_fundamental: float,
	second_harmonic: float,
	duration_seconds: float,
	amplitude: float
) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	var half_duration: float = duration_seconds * 0.5
	var first_sample_count: int = maxi(int(float(SAMPLE_RATE) * half_duration), 1)
	var second_sample_count: int = maxi(int(float(SAMPLE_RATE) * half_duration), 1)
	for segment_index: int in range(2):
		var fundamental: float = first_fundamental if segment_index == 0 else second_fundamental
		var harmonic: float = first_harmonic if segment_index == 0 else second_harmonic
		var sample_count: int = first_sample_count if segment_index == 0 else second_sample_count
		for sample_index: int in range(sample_count):
			var fade_in: float = clampf(float(sample_index) / 80.0, 0.0, 1.0)
			var fade_out: float = clampf(float(sample_count - sample_index) / 120.0, 0.0, 1.0)
			var envelope: float = minf(fade_in, fade_out)
			var primary: float = sin(TAU * fundamental * float(sample_index) / float(SAMPLE_RATE)) * 0.6
			var secondary: float = sin(TAU * harmonic * float(sample_index) / float(SAMPLE_RATE)) * 0.35
			var sample: float = (primary + secondary) * amplitude * envelope
			var pcm_value: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
			if pcm_value < 0:
				pcm_value = 65536 + pcm_value
			data.append(pcm_value & 0xff)
			data.append((pcm_value >> 8) & 0xff)
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _make_tone_sequence(frequencies: Array, durations: Array, amplitude: float) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	for index: int in range(frequencies.size()):
		var frequency: float = float(frequencies[index])
		var duration: float = float(durations[index])
		var sample_count: int = maxi(int(float(SAMPLE_RATE) * duration), 1)
		for sample_index: int in range(sample_count):
			var fade_in: float = clampf(float(sample_index) / 80.0, 0.0, 1.0)
			var fade_out: float = clampf(float(sample_count - sample_index) / 120.0, 0.0, 1.0)
			var envelope: float = minf(fade_in, fade_out)
			var sample: float = sin(TAU * frequency * float(sample_index) / float(SAMPLE_RATE)) * amplitude * envelope
			var pcm_value: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
			if pcm_value < 0:
				pcm_value = 65536 + pcm_value
			data.append(pcm_value & 0xff)
			data.append((pcm_value >> 8) & 0xff)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
