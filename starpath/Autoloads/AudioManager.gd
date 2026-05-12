extends Node

const BGM_DIR := "res://Assets/Audio/BGM/"

var _bgm: AudioStreamPlayer
var _current_bgm: String = ""

var bgm_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready() -> void:
	_bgm      = AudioStreamPlayer.new()
	_bgm.bus  = "Master"
	add_child(_bgm)

func set_bgm_volume(value: float) -> void:
	bgm_volume    = clampf(value, 0.0, 1.0)
	_bgm.volume_db = linear_to_db(bgm_volume) if bgm_volume > 0.0 else -80.0

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)

func play_bgm(track: String, loop: bool = true) -> void:
	var path := BGM_DIR + track + ".ogg"
	if _current_bgm == path and _bgm.playing:
		return
	_current_bgm = path
	var stream = load(path)
	if stream == null:
		push_error("AudioManager: no se encontró " + path)
		return
	stream = stream.duplicate()
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	_bgm.stream = stream
	_bgm.play()

func stop_bgm() -> void:
	_bgm.stop()
	_current_bgm = ""
