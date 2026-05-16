extends Node

# Fade negro entre escenas. Uso: SceneTransition.go_to("res://ruta.tscn")

const FADE_TIME := 0.4

var _overlay: ColorRect
var _busy:    bool = false

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 200
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color        = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay)

func go_to(path: String) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false

	# Fade a negro
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_overlay, "color", Color(0, 0, 0, 1), FADE_TIME)
	await tw.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	# Fade desde negro
	var tw2 := create_tween()
	tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(_overlay, "color", Color(0, 0, 0, 0), FADE_TIME)
	await tw2.finished
	_busy = false
