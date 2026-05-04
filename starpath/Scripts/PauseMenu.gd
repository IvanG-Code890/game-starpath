class_name PauseMenu
extends CanvasLayer

const HERO_STATS_PATH := "res://Resources/Characters/Hero.tres"

# Colores del tema
const C_BG        := Color(0.04, 0.04, 0.10, 0.82)   # azul noche semitransparente
const C_PANEL     := Color(0.08, 0.08, 0.18, 0.96)   # panel oscuro
const C_BORDER    := Color(0.45, 0.70, 1.00, 1.00)   # azul acero
const C_TITLE     := Color(0.80, 0.92, 1.00, 1.00)   # blanco azulado
const C_TEXT      := Color(0.85, 0.90, 0.95, 1.00)   # texto claro
const C_MUTED     := Color(0.55, 0.65, 0.75, 1.00)   # texto secundario
const C_BTN_NORM  := Color(0.14, 0.20, 0.38, 1.00)   # botón normal
const C_BTN_HOV   := Color(0.20, 0.35, 0.60, 1.00)   # botón hover
const C_ACCENT    := Color(0.40, 0.80, 1.00, 1.00)   # acento

var _main_panel:  Control
var _items_panel: Control
var _open_frame:  int = -1   # frame en que se abrió; evita cierre inmediato

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

# ── Abrir / Cerrar / Toggle ────────────────────────────────────────────────────

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	_open_frame = Engine.get_process_frames()
	visible = true
	get_tree().paused = true
	_refresh_stats()
	_show_main()

func close() -> void:
	visible = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_X or event.keycode == KEY_ESCAPE:
			# Ignorar si el menú se acaba de abrir en este mismo frame
			# (evita que el mismo input que lo abre lo cierre de inmediato)
			if Engine.get_process_frames() == _open_frame:
				get_viewport().set_input_as_handled()
				return
			if _items_panel.visible:
				_show_main()
			else:
				close()
			get_viewport().set_input_as_handled()

# ── Construcción de la UI ──────────────────────────────────────────────────────

func _build_ui() -> void:
	# Fondo semitransparente
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = C_BG
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	_main_panel  = _build_main_panel()
	_items_panel = _build_items_panel()
	add_child(_main_panel)
	add_child(_items_panel)

# ── Panel principal ────────────────────────────────────────────────────────────

func _build_main_panel() -> Control:
	var root := _make_centered_root(520, 310)

	var panel := root.get_child(0) as PanelContainer
	_style_panel(panel, C_PANEL, C_BORDER)

	var margin := panel.get_child(0) as MarginContainer

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)

	# ── Columna izquierda: stats ──
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(200, 0)
	left.add_theme_constant_override("separation", 5)
	hbox.add_child(left)

	_lbl_colored(left, "★  LYRA", 15, C_ACCENT)
	_lbl_colored(left, "Maga", 12, C_MUTED)
	left.add_child(_separator_h(C_BORDER, 1))
	left.add_child(_spacer(4))

	# Stats con placeholders; se rellenan en _refresh_stats()
	for tag in ["_hp", "_mp", "_atk", "_def", "_vel"]:
		var lbl := Label.new()
		lbl.name = tag.substr(1).to_upper()   # "HP", "MP", etc.
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", C_TEXT)
		left.add_child(lbl)

	# ── Separador vertical ──
	hbox.add_child(_separator_v(C_BORDER))

	# ── Columna derecha: opciones ──
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	hbox.add_child(right)

	_lbl_colored(right, "MENÚ", 16, C_TITLE)
	right.add_child(_separator_h(C_BORDER, 1))
	right.add_child(_spacer(6))

	var btn_items := _make_button("⚗  Objetos", 170, 38)
	btn_items.pressed.connect(_show_items)
	right.add_child(btn_items)

	var btn_close := _make_button("✕  Cerrar  [Esc]", 170, 38)
	btn_close.pressed.connect(close)
	right.add_child(btn_close)

	return root

# ── Panel de objetos ───────────────────────────────────────────────────────────

func _build_items_panel() -> Control:
	var root := _make_centered_root(400, 300)
	root.visible = false

	var panel := root.get_child(0) as PanelContainer
	_style_panel(panel, C_PANEL, C_BORDER)

	var margin := panel.get_child(0) as MarginContainer

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_lbl_colored(vbox, "⚗  OBJETOS", 16, C_TITLE)
	vbox.add_child(_separator_h(C_BORDER, 1))
	vbox.add_child(_spacer(4))

	var list := VBoxContainer.new()
	list.name = "ItemList"
	list.add_theme_constant_override("separation", 5)
	vbox.add_child(list)

	vbox.add_child(_spacer(4))
	vbox.add_child(_separator_h(C_BORDER, 1))

	var btn_back := _make_button("◀  Volver", 150, 34)
	btn_back.pressed.connect(_show_main)
	vbox.add_child(btn_back)

	return root

# ── Navegación ────────────────────────────────────────────────────────────────

func _show_main() -> void:
	_main_panel.visible  = true
	_items_panel.visible = false

func _show_items() -> void:
	_main_panel.visible  = false
	_items_panel.visible = true
	_refresh_item_list()

# ── Refresco de datos ─────────────────────────────────────────────────────────

func _refresh_stats() -> void:
	var stats: CharacterStats = load(HERO_STATS_PATH)
	if stats == null:
		return
	var card := _main_panel.get_child(0).get_child(0).get_child(0).get_child(0) as VBoxContainer

	_set_lbl(card, "HP",  "HP   %d / %d" % [stats.max_hp,  stats.max_hp])
	_set_lbl(card, "MP",  "MP   %d / %d" % [stats.max_mp,  stats.max_mp])
	_set_lbl(card, "ATK", "ATK  %d"      % stats.attack)
	_set_lbl(card, "DEF", "DEF  %d"      % stats.defense)
	_set_lbl(card, "VEL", "VEL  %d"      % stats.speed)

func _set_lbl(parent: Node, node_name: String, text: String) -> void:
	var lbl := parent.get_node_or_null(node_name) as Label
	if lbl:
		lbl.text = text

func _refresh_item_list() -> void:
	var list := _items_panel.get_child(0).get_child(0).get_child(0).get_node("ItemList") as VBoxContainer
	for child in list.get_children():
		child.queue_free()

	var available: Array = Inventory.get_available()
	if available.is_empty():
		_lbl_colored(list, "No tienes objetos.", 13, C_MUTED)
	else:
		for item: ItemData in available:
			_lbl_colored(list, "• %s  ×%d" % [item.item_name, item.quantity], 13, C_TEXT)

# ── Helpers de construcción ───────────────────────────────────────────────────

func _make_centered_root(w: int, h: int) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(w, h)
	panel.offset_left   = -w / 2.0
	panel.offset_top    = -h / 2.0
	panel.offset_right  =  w / 2.0
	panel.offset_bottom =  h / 2.0
	root.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)

	return root

func _style_panel(panel: PanelContainer, bg: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color             = bg
	style.border_color         = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color         = Color(0, 0, 0, 0.5)
	style.shadow_size          = 8
	panel.add_theme_stylebox_override("panel", style)

func _make_button(text: String, w: int, h: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(w, h)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var s_norm := StyleBoxFlat.new()
	s_norm.bg_color = C_BTN_NORM
	s_norm.set_corner_radius_all(5)
	s_norm.set_border_width_all(1)
	s_norm.border_color = C_BORDER
	s_norm.content_margin_left = 10

	var s_hov := StyleBoxFlat.new()
	s_hov.bg_color = C_BTN_HOV
	s_hov.set_corner_radius_all(5)
	s_hov.set_border_width_all(1)
	s_hov.border_color = C_ACCENT
	s_hov.content_margin_left = 10

	var s_press := StyleBoxFlat.new()
	s_press.bg_color = C_BORDER
	s_press.set_corner_radius_all(5)
	s_press.content_margin_left = 10

	btn.add_theme_stylebox_override("normal",   s_norm)
	btn.add_theme_stylebox_override("hover",    s_hov)
	btn.add_theme_stylebox_override("pressed",  s_press)
	btn.add_theme_color_override("font_color",          C_TEXT)
	btn.add_theme_color_override("font_hover_color",    C_TITLE)
	btn.add_theme_color_override("font_pressed_color",  Color.WHITE)
	btn.add_theme_font_size_override("font_size", 13)

	return btn

func _lbl_colored(parent: Node, text: String, size: int, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)

func _separator_h(color: Color, thickness: int = 1) -> HSeparator:
	var sep := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_top    = thickness
	style.content_margin_bottom = thickness
	sep.add_theme_stylebox_override("separator", style)
	return sep

func _separator_v(color: Color) -> VSeparator:
	var sep := VSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left  = 1
	style.content_margin_right = 1
	sep.add_theme_stylebox_override("separator", style)
	return sep

func _spacer(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, px)
	return c
