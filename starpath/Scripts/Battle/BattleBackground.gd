extends CanvasLayer

const GRASS_TEX := "res://Assets/Tilesets/[A]Grass_pipo.png"

func _ready() -> void:
	await get_tree().process_frame
	var vp      := get_viewport().get_visible_rect().size
	var horizon := vp.y * 0.50

	# ── 1. Cielo degradado (3 franjas) ───────────────────────────────────────
	var sky_colors := [
		Color(0.36, 0.58, 0.82),   # azul oscuro arriba
		Color(0.52, 0.72, 0.90),   # azul medio
		Color(0.72, 0.86, 0.96),   # azul claro cerca del horizonte
	]
	for i in 3:
		var band := ColorRect.new()
		band.color    = sky_colors[i]
		band.position = Vector2(0, vp.y * i / 6.0)
		band.size     = Vector2(vp.x, vp.y / 6.0 + 2)
		add_child(band)

	# ── 2. Montañas lejanas ──────────────────────────────────────────────────
	var mountain_data := [
		[0.05,  horizon - 110, 220, 115, Color(0.38, 0.52, 0.42)],
		[0.25,  horizon - 90,  180, 95,  Color(0.42, 0.56, 0.45)],
		[0.50,  horizon - 120, 260, 125, Color(0.36, 0.50, 0.40)],
		[0.70,  horizon - 85,  190, 90,  Color(0.40, 0.54, 0.43)],
		[0.88,  horizon - 100, 200, 105, Color(0.38, 0.52, 0.42)],
	]
	for d in mountain_data:
		_add_mountain(vp.x * d[0], d[1], d[2], d[3], d[4])

	# ── 3. Línea de horizonte / suelo ────────────────────────────────────────
	var ground := ColorRect.new()
	ground.color    = Color(0.22, 0.46, 0.15, 1.0)
	ground.position = Vector2(0, horizon)
	ground.size     = Vector2(vp.x, vp.y - horizon)
	add_child(ground)

	# Franja oscura en el horizonte
	var edge := ColorRect.new()
	edge.color    = Color(0.14, 0.30, 0.09, 1.0)
	edge.position = Vector2(0, horizon - 4)
	edge.size     = Vector2(vp.x, 14)
	add_child(edge)

	# ── 4. Franja de hierba tileada ──────────────────────────────────────────
	if ResourceLoader.exists(GRASS_TEX):
		var gtex := load(GRASS_TEX) as Texture2D
		var tw   := 48
		var x    := 0.0
		while x < vp.x:
			var s              := Sprite2D.new()
			s.texture           = gtex
			s.region_enabled    = true
			s.region_rect       = Rect2(0, 0, tw, tw)
			s.centered          = false
			s.position          = Vector2(x, horizon - 10)
			s.z_index           = 2
			add_child(s)
			x += tw

	# ── 5. Árboles al fondo ──────────────────────────────────────────────────
	var tree_xs := [
		vp.x * 0.05, vp.x * 0.14,
		vp.x * 0.55, vp.x * 0.65,
		vp.x * 0.78, vp.x * 0.90,
	]
	for tx: float in tree_xs:
		_add_tree(tx, horizon - 6)

	# ── 6. Flores / detalles en el suelo ────────────────────────────────────
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for _i in 18:
		var fx  := rng.randf_range(0, vp.x)
		var fy  := rng.randf_range(horizon + 20, vp.y - 20)
		var dot := ColorRect.new()
		dot.color    = Color(0.90, 0.85, 0.20, 0.8) if rng.randf() > 0.5 \
					  else Color(1.0, 0.40, 0.40, 0.8)
		dot.size     = Vector2(6, 6)
		dot.position = Vector2(fx, fy)
		dot.z_index  = 3
		add_child(dot)

# ── Montaña triangular (hecha con un polígono) ────────────────────────────
func _add_mountain(cx: float, top_y: float, w: float, h: float, color: Color) -> void:
	var poly      := Polygon2D.new()
	poly.color     = color
	poly.polygon   = PackedVector2Array([
		Vector2(cx - w * 0.5, top_y + h),
		Vector2(cx,           top_y),
		Vector2(cx + w * 0.5, top_y + h),
	])
	poly.z_index = 1
	add_child(poly)

# ── Árbol pixel art (tronco + copa) ──────────────────────────────────────
func _add_tree(x: float, ground_y: float) -> void:
	# Tronco
	var trunk      := ColorRect.new()
	trunk.color     = Color(0.38, 0.24, 0.10, 1.0)
	trunk.size      = Vector2(12, 28)
	trunk.position  = Vector2(x - 6, ground_y - 28)
	trunk.z_index   = 2
	add_child(trunk)

	# Copa exterior (sombra)
	var shadow      := ColorRect.new()
	shadow.color     = Color(0.15, 0.38, 0.10, 1.0)
	shadow.size      = Vector2(56, 52)
	shadow.position  = Vector2(x - 28, ground_y - 72)
	shadow.z_index   = 2
	add_child(shadow)

	# Copa interior (color vivo)
	var crown       := ColorRect.new()
	crown.color      = Color(0.22, 0.56, 0.14, 1.0)
	crown.size       = Vector2(44, 42)
	crown.position   = Vector2(x - 22, ground_y - 66)
	crown.z_index    = 2
	add_child(crown)

	# Brillo superior
	var shine       := ColorRect.new()
	shine.color      = Color(0.34, 0.72, 0.20, 0.7)
	shine.size       = Vector2(22, 18)
	shine.position   = Vector2(x - 11, ground_y - 62)
	shine.z_index    = 2
	add_child(shine)
