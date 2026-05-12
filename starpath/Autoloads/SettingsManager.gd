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

var _resolution_idx: int  = 0
var _fullscreen:     bool = false

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

# ── Aplicación ────────────────────────────────────────────────────────────────

func _apply_all() -> void:
	_apply_window_mode()

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
	DisplayServer.window_set_position((screen - size) / Vector2i(2, 2))

# ── Persistencia ──────────────────────────────────────────────────────────────

func _save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "resolution_idx", _resolution_idx)
	cfg.set_value("video", "fullscreen",     _fullscreen)
	cfg.save(CONFIG_PATH)

func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	_resolution_idx = cfg.get_value("video", "resolution_idx", 0)
	_fullscreen     = cfg.get_value("video", "fullscreen",     false)
