class_name PauseMenu
extends CanvasLayer

const HERO_PATHS: Array[String] = [
	"res://Resources/Characters/Hero.tres",
]
var _equip_hero_index: int = 0

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
	var root := _make_centered_root(520, 520)

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

	left.add_child(_spacer(4))
	left.add_child(_separator_h(C_BORDER, 1))
	left.add_child(_spacer(2))

	var gold_lbl := Label.new()
	gold_lbl.name = "GoldLbl"
	gold_lbl.add_theme_font_size_override("font_size", 13)
	gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	left.add_child(gold_lbl)

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

	var btn_equip := _make_button("⚔  Equipamiento", 170, 38)
	btn_equip.pressed.connect(_show_equip)
	right.add_child(btn_equip)

	var btn_items := _make_button("⚗  Objetos", 170, 38)
	btn_items.pressed.connect(_show_items)
	right.add_child(btn_items)

	var btn_opts := _make_button("⚙  Opciones", 170, 38)
	btn_opts.pressed.connect(_show_options)
	right.add_child(btn_opts)

	right.add_child(_separator_h(C_BORDER, 1))
	right.add_child(_spacer(2))

	var btn_save := _make_button("💾  Guardar partida", 170, 38)
	btn_save.pressed.connect(func(): _show_slots("save"))
	right.add_child(btn_save)

	var btn_load := _make_button("📂  Cargar partida", 170, 38)
	btn_load.pressed.connect(func(): _show_slots("load"))
	right.add_child(btn_load)

	right.add_child(_spacer(2))
	right.add_child(_separator_h(C_BORDER, 1))
	right.add_child(_spacer(4))

	var btn_quit := _make_button("⏻  Salir del juego", 170, 38)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_quit.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	right.add_child(btn_quit)

	var btn_close := _make_button("✕  Cerrar  [Esc]", 170, 38)
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
	var card := _main_panel.get_child(0).get_child(0).get_child(0).get_child(0) as VBoxContainer

	var atk_bonus := Inventory.get_attack_bonus()
	var def_bonus := Inventory.get_defense_bonus()

	_set_lbl(card, "HP",  "HP   %d / %d" % [stats.max_hp, stats.max_hp])
	_set_lbl(card, "MP",  "MP   %d / %d" % [stats.max_mp, stats.max_mp])
	_set_lbl(card, "ATK", "ATK  %d%s" % [stats.attack, "  (+%d)" % atk_bonus if atk_bonus > 0 else ""])
	_set_lbl(card, "DEF", "DEF  %d%s" % [stats.defense, "  (+%d)" % def_bonus if def_bonus > 0 else ""])
	_set_lbl(card, "VEL", "VEL  %d"   % stats.speed)

	var gold_lbl := _main_panel.find_child("GoldLbl", true, false) as Label
	if gold_lbl:
		gold_lbl.text = "✦  Oro:  %d" % Inventory.gold

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

# ── Salir del juego ───────────────────────────────────────────────────────────

func _on_quit_pressed() -> void:
	_confirm_panel.visible = true
	var warn := _confirm_panel.find_child("WarnLbl", true, false) as Label
	var btn_save_quit := _confirm_panel.find_child("BtnSaveQuit", true, false) as Button
	var has_unsaved   := SaveManager.has_unsaved_changes
	if warn:
		warn.visible = has_unsaved
	if btn_save_quit:
		btn_save_quit.visible = has_unsaved

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

	_lbl_colored(vbox, "¿Salir del juego?", 16, C_TITLE)
	vbox.add_child(_separator_h(Color(1.0, 0.45, 0.45), 1))

	var warn := Label.new()
	warn.name = "WarnLbl"
	warn.text = "⚠  Tienes cambios sin guardar."
	warn.add_theme_font_size_override("font_size", 13)
	warn.add_theme_color_override("font_color", Color(1.0, 0.80, 0.30))
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warn)

	var btn_save_quit := _make_button("💾  Guardar y salir", 320, 38)
	btn_save_quit.name = "BtnSaveQuit"
	btn_save_quit.pressed.connect(_on_save_and_quit)
	vbox.add_child(btn_save_quit)

	var btn_quit := _make_button("✕  Salir sin guardar", 320, 38)
	btn_quit.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	btn_quit.pressed.connect(func(): get_tree().quit())
	vbox.add_child(btn_quit)

	var btn_cancel := _make_button("←  Cancelar", 320, 38)
	btn_cancel.pressed.connect(func(): root.visible = false)
	vbox.add_child(btn_cancel)

	return root

func _on_save_and_quit() -> void:
	# Guarda en la ranura 0 automáticamente y luego sale
	SaveManager.save_game(0)
	get_tree().quit()

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
