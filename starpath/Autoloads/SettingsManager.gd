extends Node

const CONFIG_PATH := "user://settings.cfg"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280,  720),
	Vector2i(1920, 1080),
]
const RESOLUTION_LABELS: Array[String] = [
	"1280 × 720   (HD)",
	"1920 × 1080  (Full HD)",
]

var _resolution_idx: int   = 0
var _fullscreen:     bool  = false
var _music_volume:   float = 1.0
var _sfx_volume:     float = 1.0

func _ready() -> void:
	_load_config()
	_apply_all()

# ── API pública ────────────────────────────────────────────────────────────────

func set_resolution(idx: int) -> void:
	_resolution_idx = clampi(idx, 0, RESOLUTIONS.size() - 1)
	if not _fullscreen:
		_apply_window_size()
	_save_config()

func set_fullscreen(enabled: bool) -> void:
	_fullscreen = enabled
	_apply_window_mode()
	_save_config()

func get_resolution_idx() -> int:
	return _resolution_idx

func is_fullscreen() -> bool:
	return _fullscreen

func set_music_volume(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_apply_music_volume()
	_save_config()

func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_apply_sfx_volume()
	_save_config()

func get_music_volume() -> float:
	return _music_volume

func get_sfx_volume() -> float:
	return _sfx_volume

# ── Aplicación ────────────────────────────────────────────────────────────────

func _apply_all() -> void:
	_apply_window_mode()
	_apply_music_volume()
	_apply_sfx_volume()

func _apply_window_mode() -> void:
	if _fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_window_size()

func _apply_window_size() -> void:
	var size := RESOLUTIONS[_resolution_idx]
	DisplayServer.window_set_size(size)
	var screen := DisplayServer.screen_get_size()
	DisplayServer.window_set_position((screen - size) / 2)

# Aplica volumen al bus de AudioServer.
# Si el bus aún no existe (p.ej. al arrancar antes de que el menú lo cree),
# no hace nada; el menú llamará de nuevo a SettingsManager.get_*_volume()
# después de crear los buses.
func _apply_music_volume() -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus == -1:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(_music_volume) if _music_volume > 0.0 else -80.0)

func _apply_sfx_volume() -> void:
	var bus := AudioServer.get_bus_index("SFX")
	if bus == -1:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(_sfx_volume) if _sfx_volume > 0.0 else -80.0)

# ── Persistencia ──────────────────────────────────────────────────────────────

func _save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "resolution_idx", _resolution_idx)
	cfg.set_value("video", "fullscreen",     _fullscreen)
	cfg.set_value("audio", "music_volume",   _music_volume)
	cfg.set_value("audio", "sfx_volume",     _sfx_volume)
	cfg.save(CONFIG_PATH)

func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	_resolution_idx = cfg.get_value("video", "resolution_idx", 0)
	_fullscreen     = cfg.get_value("video", "fullscreen",     false)
	_music_volume   = cfg.get_value("audio", "music_volume",   1.0)
	_sfx_volume     = cfg.get_value("audio", "sfx_volume",     1.0)
