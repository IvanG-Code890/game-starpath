class_name PauseMenu
extends CanvasLayer

const HERO_PATHS: Array[String] = [
	"res://Resources/Characters/Hero.tres",
]
var _equip_hero_index: int = 0

const FONT_PATH := "res://Assets/Fonts/CinzelDecorative-Bold.ttf"
var _font: Font

# Paleta fantasía oscura / dorada
const C_BG        := Color(0.02, 0.01, 0.04, 0.90)   # negro noche
const C_PANEL     := Color(0.07, 0.06, 0.11, 0.98)   # panel oscuro cálido
const C_BORDER    := Color(0.72, 0.57, 0.20, 1.00)   # oro antiguo
const C_BORDER2   := Color(0.45, 0.35, 0.10, 1.00)   # oro oscuro
const C_TITLE     := Color(0.96, 0.84, 0.40, 1.00)   # oro brillante
const C_TEXT      := Color(0.92, 0.88, 0.80, 1.00)   # blanco cálido
const C_MUTED     := Color(0.60, 0.56, 0.48, 1.00)   # gris cálido
const C_BTN_NORM  := Color(0.09, 0.08, 0.13, 0.96)   # botón oscuro
const C_BTN_HOV   := Color(0.18, 0.14, 0.06, 0.98)   # hover dorado oscuro
const C_ACCENT    := Color(0.96, 0.84, 0.40, 1.00)   # oro acento
const C_HP        := Color(0.88, 0.28, 0.28, 1.00)   # rojo vida
const C_MP        := Color(0.35, 0.60, 1.00, 1.00)   # azul maná

const MAIN_MENU_SCENE := "res://Scenes/UI/menu_inicio.tscn"

var _main_panel:    Control
var _items_panel:   Control
var _equip_panel:   Control
var _slot_panel:    Control
var _options_panel: Control
var _confirm_panel: Control
var _open_frame:   int    = -1
var _slot_mode:    String = "save"
var _feedback_lbl:      Label
var _slot_feedback_lbl: Label

# Confirm panel — acción pendiente
var _pending_action:     Callable
var _confirm_title_lbl:  Label
var _btn_save_act:       Button
var _btn_nosave_act:     Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_font = load(FONT_PATH)
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
			if _confirm_panel.visible:
				_confirm_panel.visible = false
			elif _items_panel.visible or _equip_panel.visible or _slot_panel.visible or _options_panel.visible:
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
	_equip_panel = _build_equip_panel()
	_slot_panel    = _build_slot_panel()
	_options_panel = _build_options_panel()
	_confirm_panel = _build_confirm_panel()
	add_child(_main_panel)
	add_child(_items_panel)
	add_child(_equip_panel)
	add_child(_slot_panel)
	add_child(_options_panel)
	add_child(_confirm_panel)

# ── Panel principal ────────────────────────────────────────────────────────────

func _build_main_panel() -> Control:
	var root := _make_centered_root(560, 560)

	var panel := root.get_child(0) as PanelContainer
	_style_panel(panel, C_PANEL, C_BORDER)

	var margin := panel.get_child(0) as MarginContainer

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 22)
	margin.add_child(hbox)

	# ── Columna izquierda: stats del personaje ────────────────────────────
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(185, 0)
	left.add_theme_constant_override("separation", 6)
	hbox.add_child(left)

	# Nombre con fuente RPG
	var name_lbl := Label.new()
	name_lbl.text = "✦  LYRA"
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", C_ACCENT)
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	name_lbl.add_theme_constant_override("shadow_offset_x", 2)
	name_lbl.add_theme_constant_override("shadow_offset_y", 2)
	if _font:
		name_lbl.add_theme_font_override("font", _font)
	left.add_child(name_lbl)

	_lbl_colored(left, "Maga", 12, C_MUTED)
	left.add_child(_separator_h(C_BORDER2, 1))
	left.add_child(_spacer(2))

	# Stats con colores diferenciados (NV = nivel con color dorado)
	for pair in [["NV", C_TITLE], ["HP", C_HP], ["MP", C_MP], ["ATK", C_TEXT], ["DEF", C_TEXT], ["VEL", C_TEXT]]:
		var row := HBoxContainer.new()
		var tag_lbl := Label.new()
		tag_lbl.custom_minimum_size = Vector2(36, 0)
		tag_lbl.add_theme_font_size_override("font_size", 12)
		tag_lbl.add_theme_color_override("font_color", pair[1] as Color)
		tag_lbl.text = pair[0] as String
		if _font:
			tag_lbl.add_theme_font_override("font", _font)
		row.add_child(tag_lbl)
		var val_lbl := Label.new()
		val_lbl.name = pair[0] as String
		val_lbl.add_theme_font_size_override("font_size", 13)
		val_lbl.add_theme_color_override("font_color", C_TEXT)
		row.add_child(val_lbl)
		left.add_child(row)

	left.add_child(_spacer(6))
	left.add_child(_separator_h(C_BORDER2, 1))
	left.add_child(_spacer(2))

	var gold_lbl := Label.new()
	gold_lbl.name = "GoldLbl"
	gold_lbl.add_theme_font_size_override("font_size", 13)
	gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	if _font:
		gold_lbl.add_theme_font_override("font", _font)
	left.add_child(gold_lbl)

	left.add_child(_spacer(4))

	# ── Barra de EXP ─────────────────────────────────────────────────────
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = C_BORDER
	xp_fill.set_corner_radius_all(3)
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.08, 0.06, 0.12, 1.0)
	xp_bg.set_corner_radius_all(3)

	var xp_bar := ProgressBar.new()
	xp_bar.name = "XPBar"
	xp_bar.custom_minimum_size = Vector2(0, 8)
	xp_bar.show_percentage = false
	xp_bar.add_theme_stylebox_override("fill",       xp_fill)
	xp_bar.add_theme_stylebox_override("background", xp_bg)
	left.add_child(xp_bar)

	var xp_lbl := Label.new()
	xp_lbl.name = "XPLbl"
	xp_lbl.add_theme_font_size_override("font_size", 11)
	xp_lbl.add_theme_color_override("font_color", C_MUTED)
	left.add_child(xp_lbl)

	# ── Separador vertical ────────────────────────────────────────────────
	hbox.add_child(_separator_v(C_BORDER2))

	# ── Columna derecha: botones ──────────────────────────────────────────
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	hbox.add_child(right)

	# Título con fuente RPG
	var menu_title := Label.new()
	menu_title.text = "— MENÚ —"
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_font_size_override("font_size", 17)
	menu_title.add_theme_color_override("font_color", C_TITLE)
	menu_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	menu_title.add_theme_constant_override("shadow_offset_x", 2)
	menu_title.add_theme_constant_override("shadow_offset_y", 2)
	if _font:
		menu_title.add_theme_font_override("font", _font)
	right.add_child(menu_title)
	right.add_child(_separator_h(C_BORDER, 1))
	right.add_child(_spacer(4))

	var btn_equip := _make_button("⚔   Equipamiento", 200, 40)
	btn_equip.pressed.connect(_show_equip)
	right.add_child(btn_equip)

	var btn_items := _make_button("⚗   Objetos", 200, 40)
	btn_items.pressed.connect(_show_items)
	right.add_child(btn_items)

	var btn_opts := _make_button("⚙   Opciones", 200, 40)
	btn_opts.pressed.connect(_show_options)
	right.add_child(btn_opts)

	right.add_child(_separator_h(C_BORDER2, 1))

	var btn_save := _make_button("💾   Guardar partida", 200, 40)
	btn_save.pressed.connect(func(): _show_slots("save"))
	right.add_child(btn_save)

	var btn_load := _make_button("📂   Cargar partida", 200, 40)
	btn_load.pressed.connect(func(): _show_slots("load"))
	right.add_child(btn_load)

	var btn_main_menu := _make_button("⌂   Menú principal", 200, 40)
	btn_main_menu.pressed.connect(_on_main_menu_pressed)
	btn_main_menu.add_theme_color_override("font_color",       Color(0.60, 0.90, 1.00))
	btn_main_menu.add_theme_color_override("font_hover_color", Color(0.85, 1.00, 1.00))
	right.add_child(btn_main_menu)

	right.add_child(_separator_h(C_BORDER2, 1))

	var btn_quit := _make_button("⏻   Salir del juego", 200, 40)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_quit.add_theme_color_override("font_color",       Color(1.0, 0.40, 0.40))
	btn_quit.add_theme_color_override("font_hover_color", Color(1.0, 0.65, 0.65))
	right.add_child(btn_quit)

	var btn_close := _make_button("✕   Cerrar  [Esc]", 200, 40)
	btn_close.pressed.connect(close)
	right.add_child(btn_close)

	_feedback_lbl = Label.new()
	_feedback_lbl.add_theme_font_size_override("font_size", 12)
	_feedback_lbl.add_theme_color_override("font_color", C_ACCENT)
	_feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_lbl.modulate.a = 0.0
	right.add_child(_feedback_lbl)

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
	_main_panel.visible    = true
	_items_panel.visible   = false
	_equip_panel.visible   = false
	_slot_panel.visible    = false
	_options_panel.visible = false

func _show_items() -> void:
	_main_panel.visible  = false
	_items_panel.visible = true
	_equip_panel.visible = false
	_slot_panel.visible  = false
	_refresh_item_list()

func _show_equip() -> void:
	_main_panel.visible  = false
	_items_panel.visible = false
	_equip_panel.visible = true
	_slot_panel.visible  = false
	_refresh_equip()

func _show_slots(mode: String) -> void:
	_slot_mode = mode
	_main_panel.visible    = false
	_items_panel.visible   = false
	_equip_panel.visible   = false
	_slot_panel.visible    = true
	_options_panel.visible = false
	_refresh_slot_list()

func _show_options() -> void:
	_main_panel.visible    = false
	_items_panel.visible   = false
	_equip_panel.visible   = false
	_slot_panel.visible    = false
	_options_panel.visible = true
	_refresh_options()

# ── Refresco de datos ─────────────────────────────────────────────────────────

func _refresh_stats() -> void:
	var stats: CharacterStats = load(HERO_PATHS[0])
	if stats == null:
		return

	var atk_bonus := Inventory.get_attack_bonus() + Inventory.get_level_atk_bonus()
	var def_bonus := Inventory.get_defense_bonus() + Inventory.get_level_def_bonus()

	_set_stat_lbl("NV",  "Nivel  %d" % Inventory.current_level)
	_set_stat_lbl("HP",  "%d / %d"   % [Inventory.current_hp, Inventory.get_max_hp()])
	_set_stat_lbl("MP",  "%d / %d"   % [Inventory.current_mp, Inventory.get_max_mp()])
	_set_stat_lbl("ATK", "%d%s"      % [stats.attack,  "  (+%d)" % atk_bonus if atk_bonus > 0 else ""])
	_set_stat_lbl("DEF", "%d%s"      % [stats.defense, "  (+%d)" % def_bonus if def_bonus > 0 else ""])
	_set_stat_lbl("VEL", "%d"        % stats.speed)

	var gold_lbl := _main_panel.find_child("GoldLbl", true, false) as Label
	if gold_lbl:
		gold_lbl.text = "✦  Oro:  %d" % Inventory.gold

	var xp_bar := _main_panel.find_child("XPBar", true, false) as ProgressBar
	if xp_bar:
		xp_bar.max_value = Inventory.xp_to_next()
		xp_bar.value     = Inventory.current_xp

	var xp_lbl := _main_panel.find_child("XPLbl", true, false) as Label
	if xp_lbl:
		xp_lbl.text = "EXP  %d / %d" % [Inventory.current_xp, Inventory.xp_to_next()]

func _set_stat_lbl(stat_name: String, value: String) -> void:
	var lbl := _main_panel.find_child(stat_name, true, false) as Label
	if lbl:
		lbl.text = value

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
	style.set_corner_radius_all(6)
	style.shadow_color         = Color(0, 0, 0, 0.75)
	style.shadow_size          = 20
	style.shadow_offset        = Vector2(0, 6)
	panel.add_theme_stylebox_override("panel", style)

func _make_button(text: String, w: int, h: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(w, h)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Normal: borde izquierdo dorado como acento RPG
	var s_norm := StyleBoxFlat.new()
	s_norm.bg_color             = C_BTN_NORM
	s_norm.set_corner_radius_all(4)
	s_norm.border_width_left    = 3
	s_norm.border_width_top     = 1
	s_norm.border_width_right   = 1
	s_norm.border_width_bottom  = 1
	s_norm.border_color         = C_BORDER2
	s_norm.content_margin_left  = 14
	s_norm.shadow_color         = Color(0, 0, 0, 0.4)
	s_norm.shadow_size          = 4

	# Hover: borde izquierdo más grueso y brillante
	var s_hov := StyleBoxFlat.new()
	s_hov.bg_color              = C_BTN_HOV
	s_hov.set_corner_radius_all(4)
	s_hov.border_width_left     = 4
	s_hov.border_width_top      = 1
	s_hov.border_width_right    = 1
	s_hov.border_width_bottom   = 1
	s_hov.border_color          = C_BORDER
	s_hov.content_margin_left   = 14
	s_hov.shadow_color          = Color(0.72, 0.57, 0.20, 0.3)
	s_hov.shadow_size           = 6

	var s_press := StyleBoxFlat.new()
	s_press.bg_color            = C_BORDER2
	s_press.set_corner_radius_all(4)
	s_press.border_width_left   = 4
	s_press.border_color        = C_BORDER
	s_press.content_margin_left = 14

	btn.add_theme_stylebox_override("normal",   s_norm)
	btn.add_theme_stylebox_override("hover",    s_hov)
	btn.add_theme_stylebox_override("pressed",  s_press)
	btn.add_theme_color_override("font_color",          C_TEXT)
	btn.add_theme_color_override("font_hover_color",    C_TITLE)
	btn.add_theme_color_override("font_pressed_color",  Color.WHITE)
	btn.add_theme_color_override("font_focus_color",    C_TEXT)
	btn.add_theme_font_size_override("font_size", 13)
	if _font:
		btn.add_theme_font_override("font", _font)

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

# ── Panel de equipamiento ──────────────────────────────────────────────────────

func _build_equip_panel() -> Control:
	var root := _make_centered_root(500, 360)
	root.visible = false

	var panel := root.get_child(0) as PanelContainer
	_style_panel(panel, C_PANEL, C_BORDER)

	var margin := panel.get_child(0) as MarginContainer
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# ── Cabecera con selector de personaje ──────────────────────────────────
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)

	var btn_prev := _make_button("◀", 34, 30)
	btn_prev.pressed.connect(func():
		_equip_hero_index = (_equip_hero_index - 1 + HERO_PATHS.size()) % HERO_PATHS.size()
		_refresh_equip())
	header.add_child(btn_prev)

	var hero_name_lbl := Label.new()
	hero_name_lbl.name = "HeroNameLbl"
	hero_name_lbl.custom_minimum_size = Vector2(240, 0)
	hero_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_name_lbl.add_theme_font_size_override("font_size", 16)
	hero_name_lbl.add_theme_color_override("font_color", C_TITLE)
	header.add_child(hero_name_lbl)

	var btn_next := _make_button("▶", 34, 30)
	btn_next.pressed.connect(func():
		_equip_hero_index = (_equip_hero_index + 1) % HERO_PATHS.size()
		_refresh_equip())
	header.add_child(btn_next)

	vbox.add_child(_separator_h(C_BORDER, 1))
	vbox.add_child(_spacer(4))

	var list := VBoxContainer.new()
	list.name = "EquipList"
	list.add_theme_constant_override("separation", 7)
	vbox.add_child(list)

	vbox.add_child(_spacer(4))
	vbox.add_child(_separator_h(C_BORDER, 1))

	var btn_back := _make_button("◀  Volver", 150, 34)
	btn_back.pressed.connect(_show_main)
	vbox.add_child(btn_back)

	return root

func _refresh_equip() -> void:
	# Cargar stats del héroe seleccionado
	var stats: CharacterStats = load(HERO_PATHS[_equip_hero_index])

	# Actualizar nombre en la cabecera
	var name_lbl := _equip_panel.find_child("HeroNameLbl", true, false) as Label
	if name_lbl:
		name_lbl.text = stats.character_name if stats else "Héroe"

	var list := _equip_panel.get_child(0).get_child(0).get_child(0).get_node("EquipList") as VBoxContainer
	for child in list.get_children():
		child.queue_free()

	# ── Stats del personaje ─────────────────────────────────────────────────
	if stats:
		_lbl_colored(list, "ESTADÍSTICAS", 13, C_ACCENT)
		var atk_bonus := Inventory.get_attack_bonus()
		var def_bonus := Inventory.get_defense_bonus()
		var stats_row := HBoxContainer.new()
		stats_row.add_theme_constant_override("separation", 18)
		list.add_child(stats_row)
		_lbl_colored(stats_row, "HP  %d"  % stats.max_hp,  13, C_TEXT)
		_lbl_colored(stats_row, "MP  %d"  % stats.max_mp,  13, C_TEXT)
		_lbl_colored(stats_row, "ATK %d%s" % [stats.attack,  " (+%d)" % atk_bonus if atk_bonus > 0 else ""], 13, C_TEXT)
		_lbl_colored(stats_row, "DEF %d%s" % [stats.defense, " (+%d)" % def_bonus if def_bonus > 0 else ""], 13, C_TEXT)
		list.add_child(_spacer(4))

	# ── Slots actuales ──────────────────────────────────────────────────────
	_lbl_colored(list, "EQUIPO ACTUAL", 13, C_ACCENT)

	_add_slot_row(list, "Arma    :",
		Inventory.equipped_weapon,
		func(): Inventory.unequip(Inventory.equipped_weapon); _refresh_equip(); _refresh_stats())

	_add_slot_row(list, "Armadura:",
		Inventory.equipped_armor,
		func(): Inventory.unequip(Inventory.equipped_armor); _refresh_equip(); _refresh_stats())

	list.add_child(_spacer(4))

	# ── Items disponibles para equipar ─────────────────────────────────────
	_lbl_colored(list, "DISPONIBLE EN INVENTARIO", 13, C_ACCENT)

	var has_any := false
	for item: ItemData in Inventory.items:
		if item.item_type == ItemData.ItemType.CONSUMABLE:
			continue
		has_any = true
		var is_eq := (item == Inventory.equipped_weapon or item == Inventory.equipped_armor)
		var stat  := "ATK+%d" % item.attack_bonus if item.item_type == ItemData.ItemType.WEAPON \
					 else "DEF+%d" % item.defense_bonus

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		list.add_child(row)

		var lbl := Label.new()
		lbl.text = item.item_name + "  " + stat
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", C_MUTED if is_eq else C_TEXT)
		row.add_child(lbl)

		if is_eq:
			_lbl_colored(row, "[equipado]", 12, C_ACCENT)
		else:
			var captured := item
			var btn := _make_button("Equipar", 90, 28)
			btn.pressed.connect(func(): Inventory.equip(captured); _refresh_equip(); _refresh_stats())
			row.add_child(btn)

	if not has_any:
		_lbl_colored(list, "Sin equipo disponible.", 13, C_MUTED)

# ── Guardar / Cargar ──────────────────────────────────────────────────────────

func _do_save(slot: int) -> void:
	SaveManager.save_game(slot)
	_refresh_slot_list()
	_show_slot_feedback("✓  Guardado en ranura %d" % (slot + 1))

func _do_load(slot: int) -> void:
	SaveManager.load_game(slot)
	TutorialManager.skip_all()
	_refresh_stats()
	_show_slot_feedback("✓  Partida cargada")

func _show_feedback(msg: String) -> void:
	_feedback_lbl.text = msg
	_feedback_lbl.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(_feedback_lbl, "modulate:a", 0.0, 0.5)

func _show_slot_feedback(msg: String) -> void:
	_slot_feedback_lbl.text = msg
	_slot_feedback_lbl.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(_slot_feedback_lbl, "modulate:a", 0.0, 0.5)

# ── Panel de ranuras ───────────────────────────────────────────────────────────

func _build_slot_panel() -> Control:
	var root := _make_centered_root(520, 460)
	root.visible = false

	var panel := root.get_child(0) as PanelContainer
	_style_panel(panel, C_PANEL, C_BORDER)

	var margin := panel.get_child(0) as MarginContainer
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.name = "SlotTitle"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", C_TITLE)
	vbox.add_child(title_lbl)

	vbox.add_child(_separator_h(C_BORDER, 1))
	vbox.add_child(_spacer(2))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "SlotList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	vbox.add_child(_spacer(2))
	vbox.add_child(_separator_h(C_BORDER, 1))

	_slot_feedback_lbl = Label.new()
	_slot_feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_feedback_lbl.add_theme_font_size_override("font_size", 12)
	_slot_feedback_lbl.add_theme_color_override("font_color", C_ACCENT)
	_slot_feedback_lbl.modulate.a = 0.0
	vbox.add_child(_slot_feedback_lbl)

	var btn_back := _make_button("◀  Volver", 150, 34)
	btn_back.pressed.connect(_show_main)
	vbox.add_child(btn_back)

	return root

func _refresh_slot_list() -> void:
	var title_lbl := _slot_panel.find_child("SlotTitle", true, false) as Label
	if title_lbl:
		title_lbl.text = "💾  GUARDAR PARTIDA" if _slot_mode == "save" else "📂  CARGAR PARTIDA"

	var list := _slot_panel.find_child("SlotList", true, false) as VBoxContainer
	for child in list.get_children():
		child.queue_free()

	for i in SaveManager.SLOT_COUNT:
		var info := SaveManager.get_slot_info(i)
		var row  := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)

		# Número de ranura
		var num_lbl := Label.new()
		num_lbl.text = "%02d" % (i + 1)
		num_lbl.custom_minimum_size = Vector2(24, 0)
		num_lbl.add_theme_font_size_override("font_size", 13)
		num_lbl.add_theme_color_override("font_color", C_MUTED)
		row.add_child(num_lbl)

		# Info de la ranura
		var info_lbl := Label.new()
		info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_lbl.add_theme_font_size_override("font_size", 13)
		if info["empty"]:
			info_lbl.text = "── Vacía ──"
			info_lbl.add_theme_color_override("font_color", C_MUTED)
		else:
			info_lbl.text = "%s   ✦ %d oro" % [info["save_date"], info["gold"]]
			info_lbl.add_theme_color_override("font_color", C_TEXT)
		row.add_child(info_lbl)

		# Botón de acción
		var captured_i := i
		if _slot_mode == "save":
			var lbl := "Guardar" if info["empty"] else "Sobreescribir"
			var btn := _make_button(lbl, 118, 30)
			btn.pressed.connect(func(): _do_save(captured_i))
			row.add_child(btn)
		else:
			var btn := _make_button("Cargar", 118, 30)
			btn.disabled = info["empty"]
			if not info["empty"]:
				btn.pressed.connect(func(): _do_load(captured_i))
			row.add_child(btn)

# ── Panel de opciones ─────────────────────────────────────────────────────────

func _build_options_panel() -> Control:
	var root := _make_centered_root(460, 390)
	root.visible = false

	var panel := root.get_child(0) as PanelContainer
	_style_panel(panel, C_PANEL, C_BORDER)

	var margin := panel.get_child(0) as MarginContainer
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	_lbl_colored(vbox, "⚙  OPCIONES", 16, C_TITLE)
	vbox.add_child(_separator_h(C_BORDER, 1))
	vbox.add_child(_spacer(4))

	vbox.add_child(_make_volume_row("Música",  "MusicSlider",  "MusicVal"))
	vbox.add_child(_make_volume_row("SFX",     "SFXSlider",    "SFXVal"))

	vbox.add_child(_spacer(6))
	vbox.add_child(_separator_h(C_BORDER, 1))
	vbox.add_child(_spacer(4))
	_lbl_colored(vbox, "VÍDEO", 12, C_MUTED)
	vbox.add_child(_spacer(2))

	# Fila: Pantalla completa
	var fs_row := HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 10)
	vbox.add_child(fs_row)

	var fs_lbl := Label.new()
	fs_lbl.text = "Modo"
	fs_lbl.custom_minimum_size = Vector2(60, 0)
	fs_lbl.add_theme_font_size_override("font_size", 13)
	fs_lbl.add_theme_color_override("font_color", C_TEXT)
	fs_row.add_child(fs_lbl)

	var fs_btn := Button.new()
	fs_btn.name                  = "FullscreenBtn"
	fs_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_btn.add_theme_font_size_override("font_size", 13)
	fs_btn.pressed.connect(_on_fullscreen_toggle)
	fs_row.add_child(fs_btn)

	# Fila: Resolución
	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 10)
	vbox.add_child(res_row)

	var res_lbl := Label.new()
	res_lbl.text = "Resolución"
	res_lbl.custom_minimum_size = Vector2(60, 0)
	res_lbl.add_theme_font_size_override("font_size", 13)
	res_lbl.add_theme_color_override("font_color", C_TEXT)
	res_row.add_child(res_lbl)

	var res_opt := OptionButton.new()
	res_opt.name                  = "ResolutionOpt"
	res_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_opt.add_theme_font_size_override("font_size", 13)
	for label in SettingsManager.RESOLUTION_LABELS:
		res_opt.add_item(label)
	res_opt.item_selected.connect(_on_resolution_selected)
	res_row.add_child(res_opt)

	vbox.add_child(_spacer(4))
	vbox.add_child(_separator_h(C_BORDER, 1))

	var btn_back := _make_button("◀  Volver", 150, 34)
	btn_back.pressed.connect(_show_main)
	vbox.add_child(btn_back)

	return root

func _make_volume_row(label: String, slider_name: String, val_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(60, 0)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C_TEXT)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.name                 = slider_name
	slider.min_value            = 0
	slider.max_value            = 100
	slider.step                 = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.name = val_name
	val_lbl.custom_minimum_size = Vector2(44, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", C_ACCENT)
	row.add_child(val_lbl)

	return row

func _refresh_options() -> void:
	# ── Audio ──
	var music_slider := _options_panel.find_child("MusicSlider", true, false) as HSlider
	var sfx_slider   := _options_panel.find_child("SFXSlider",   true, false) as HSlider
	var music_val    := _options_panel.find_child("MusicVal",     true, false) as Label
	var sfx_val      := _options_panel.find_child("SFXVal",       true, false) as Label

	if music_slider and not music_slider.value_changed.is_connected(_on_music_volume):
		music_slider.value = AudioManager.bgm_volume * 100
		music_slider.value_changed.connect(_on_music_volume)
	if sfx_slider and not sfx_slider.value_changed.is_connected(_on_sfx_volume):
		sfx_slider.value = AudioManager.sfx_volume * 100
		sfx_slider.value_changed.connect(_on_sfx_volume)
	if music_val:
		music_val.text = "%d%%" % int(AudioManager.bgm_volume * 100)
	if sfx_val:
		sfx_val.text = "%d%%" % int(AudioManager.sfx_volume * 100)

	# ── Vídeo ──
	var fs_btn  := _options_panel.find_child("FullscreenBtn",  true, false) as Button
	var res_opt := _options_panel.find_child("ResolutionOpt",  true, false) as OptionButton
	var fs      := SettingsManager.is_fullscreen()

	if fs_btn:
		fs_btn.text = "Pantalla completa  ✓" if fs else "Modo ventana"
	if res_opt:
		res_opt.selected = SettingsManager.get_resolution_idx()
		res_opt.disabled = fs

func _on_music_volume(value: float) -> void:
	AudioManager.set_bgm_volume(value / 100.0)
	var lbl := _options_panel.find_child("MusicVal", true, false) as Label
	if lbl:
		lbl.text = "%d%%" % int(value)

func _on_sfx_volume(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0)
	var lbl := _options_panel.find_child("SFXVal", true, false) as Label
	if lbl:
		lbl.text = "%d%%" % int(value)

func _on_fullscreen_toggle() -> void:
	SettingsManager.set_fullscreen(not SettingsManager.is_fullscreen())
	_refresh_options()

func _on_resolution_selected(idx: int) -> void:
	SettingsManager.set_resolution(idx)

# ── Salir del juego / Menú principal ─────────────────────────────────────────

func _request_confirm(title: String, save_label: String, nosave_label: String, action: Callable) -> void:
	_pending_action = action
	if _confirm_title_lbl:
		_confirm_title_lbl.text = title
	if _btn_save_act:
		_btn_save_act.text    = save_label
		_btn_save_act.visible = SaveManager.has_unsaved_changes
	if _btn_nosave_act:
		_btn_nosave_act.text = nosave_label
	var warn := _confirm_panel.find_child("WarnLbl", true, false) as Label
	if warn:
		warn.visible = SaveManager.has_unsaved_changes
	_confirm_panel.visible = true

func _on_quit_pressed() -> void:
	_request_confirm(
		"¿Salir del juego?",
		"💾  Guardar y salir",
		"✕  Salir sin guardar",
		func(): get_tree().quit()
	)

func _on_main_menu_pressed() -> void:
	_request_confirm(
		"¿Volver al menú principal?",
		"💾  Guardar e ir",
		"⌂  Ir sin guardar",
		func():
			AudioManager.stop_bgm()
			get_tree().paused = false
			SceneTransition.go_to(MAIN_MENU_SCENE)
	)

func _build_confirm_panel() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false

	# Fondo oscuro semitransparente
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(380, 0)
	panel.offset_left  = -190
	panel.offset_right =  190
	panel.offset_top   = -110
	panel.offset_bottom =  110
	_style_panel(panel, C_PANEL, Color(1.0, 0.45, 0.45))
	root.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_confirm_title_lbl = Label.new()
	_confirm_title_lbl.text = "¿Salir del juego?"
	_confirm_title_lbl.add_theme_font_size_override("font_size", 16)
	_confirm_title_lbl.add_theme_color_override("font_color", C_TITLE)
	vbox.add_child(_confirm_title_lbl)
	vbox.add_child(_separator_h(Color(1.0, 0.45, 0.45), 1))

	var warn := Label.new()
	warn.name = "WarnLbl"
	warn.text = "⚠  Tienes cambios sin guardar."
	warn.add_theme_font_size_override("font_size", 13)
	warn.add_theme_color_override("font_color", Color(1.0, 0.80, 0.30))
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warn)

	_btn_save_act = _make_button("💾  Guardar y salir", 320, 38)
	_btn_save_act.pressed.connect(func():
		SaveManager.save_game(0)
		root.visible = false
		if _pending_action.is_valid():
			_pending_action.call()
	)
	vbox.add_child(_btn_save_act)

	_btn_nosave_act = _make_button("✕  Salir sin guardar", 320, 38)
	_btn_nosave_act.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	_btn_nosave_act.pressed.connect(func():
		root.visible = false
		if _pending_action.is_valid():
			_pending_action.call()
	)
	vbox.add_child(_btn_nosave_act)

	var btn_cancel := _make_button("←  Cancelar", 320, 38)
	btn_cancel.pressed.connect(func(): root.visible = false)
	vbox.add_child(btn_cancel)

	return root

func _add_slot_row(parent: Node, label: String, item: ItemData, on_unequip: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var slot_lbl := Label.new()
	slot_lbl.text = label
	slot_lbl.custom_minimum_size = Vector2(72, 0)
	slot_lbl.add_theme_font_size_override("font_size", 13)
	slot_lbl.add_theme_color_override("font_color", C_MUTED)
	row.add_child(slot_lbl)

	if item:
		var stat := "ATK+%d" % item.attack_bonus if item.item_type == ItemData.ItemType.WEAPON \
					else "DEF+%d" % item.defense_bonus
		var item_lbl := Label.new()
		item_lbl.text = item.item_name + "  " + stat
		item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_lbl.add_theme_font_size_override("font_size", 13)
		item_lbl.add_theme_color_override("font_color", C_TEXT)
		row.add_child(item_lbl)

		var btn := _make_button("Desequipar", 105, 28)
		btn.pressed.connect(on_unequip)
		row.add_child(btn)
	else:
		var empty_lbl := Label.new()
		empty_lbl.text = "─────────────────"
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", C_MUTED)
		row.add_child(empty_lbl)
