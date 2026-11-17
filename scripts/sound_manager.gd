extends Node
## Sonidos simples generados por codigo (sin archivos). PC + Android.
class_name SoundManager

var players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)

func _tone(freq: float, duration: float, volume_db: float = -8.0, slide_to: float = 0.0) -> void:
	var sample_rate := 22050
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / sample_rate
		var f := freq
		if slide_to > 0.0:
			f = lerpf(freq, slide_to, float(i) / frames)
		var s := sin(TAU * f * t) * 0.6 * (1.0 - float(i) / frames)
		var v := int(clampf(s, -1.0, 1.0) * 32767)
		data.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	var p: AudioStreamPlayer = _free_player()
	if p:
		p.stream = stream
		p.volume_db = volume_db
		p.play()

func _free_player() -> AudioStreamPlayer:
	for p in players:
		if not p.playing:
			return p
	return players[0]

func click() -> void:
	_tone(700.0, 0.07)

func cash() -> void:
	_tone(880.0, 0.12, -8.0, 1320.0)

func success() -> void:
	_tone(523.0, 0.15, -8.0, 784.0)

func fail() -> void:
	_tone(220.0, 0.25, -8.0, 110.0)

func buy() -> void:
	_tone(660.0, 0.1, -8.0, 990.0)
