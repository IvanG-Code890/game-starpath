extends CanvasLayer

const BG_TEX := "res://Assets/Backgrounds/battle_field.png"

func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size

	# Sprite de fondo que ocupa toda la pantalla
	var bg := Sprite2D.new()
	bg.texture  = load(BG_TEX) as Texture2D
	bg.centered = false
	bg.position = Vector2.ZERO
	# Escala para cubrir exactamente el viewport (la imagen es 1280×720)
	if bg.texture:
		var tex_size := bg.texture.get_size()
		bg.scale = Vector2(vp.x / tex_size.x, vp.y / tex_size.y)
	bg.z_index = -10
	add_child(bg)
