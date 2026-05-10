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

var _main_panel:  Control
var _items_panel: Control
var _equip_panel: Control
var _sell_panel:  Control
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
			if _items_panel.visible or _equip_panel.visible or _sell_panel.visible:
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
	_sell_panel  = _build_sell_panel()
	add_child(_main_panel)
	add_child(_items_panel)
	add_child(_equip_panel)
	add_child(_sell_panel)

# ── Panel principal ────────────────────────────────────────────────────────────

func _build_main_panel() -> Control:
	var root := _make_centered_root(520, 370)

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

	var btn_sell := _make_button("✦  Vender", 170, 38)
	btn_sell.pressed.connect(_show_sell)
	right.add_child(btn_sell)

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
	_equip_panel.visible = false
	_sell_panel.visible  = false

func _show_items() -> void:
	_main_panel.visible  = false
	_items_panel.visible = true
	_equip_panel.visible = false
	_refresh_item_list()

func _show_equip() -> void:
	_main_panel.visible  = false
	_items_panel.visible = false
	_equip_panel.visible = true
	_sell_panel.visible  = false
	_refresh_equip()

func _show_sell() -> void:
	_main_panel.visible  = false
	_items_panel.visible = false
	_equip_panel.visible = false
	_sell_panel.visible  = true
	_refresh_sell()

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

# ── Panel de venta ─────────────────────────────────────────────────────────────

func _build_sell_panel() -> Control:
	var root := _make_centered_root(420, 340)
	root.visible = false

	var panel := root.get_child(0) as PanelContainer
	_style_panel(panel, C_PANEL, C_BORDER)

	var margin := panel.get_child(0) as MarginContainer
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_lbl_colored(vbox, "✦  VENDER", 16, C_TITLE)
	vbox.add_child(_separator_h(C_BORDER, 1))
	vbox.add_child(_spacer(4))

	var list := VBoxContainer.new()
	list.name = "SellList"
	list.add_theme_constant_override("separation", 6)
	vbox.add_child(list)

	vbox.add_child(_spacer(4))
	vbox.add_child(_separator_h(C_BORDER, 1))

	var gold_row := HBoxContainer.new()
	vbox.add_child(gold_row)
	var gold_icon := Label.new()
	gold_icon.text = "Oro actual:"
	gold_icon.add_theme_font_size_override("font_size", 13)
	gold_icon.add_theme_color_override("font_color", C_MUTED)
	gold_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gold_row.add_child(gold_icon)
	var sell_gold_lbl := Label.new()
	sell_gold_lbl.name = "SellGoldLbl"
	sell_gold_lbl.add_theme_font_size_override("font_size", 13)
	sell_gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	gold_row.add_child(sell_gold_lbl)

	vbox.add_child(_separator_h(C_BORDER, 1))

	var btn_back := _make_button("◀  Volver", 150, 34)
	btn_back.pressed.connect(_show_main)
	vbox.add_child(btn_back)

	return root

func _refresh_sell() -> void:
	var list := _sell_panel.find_child("SellList", true, false) as VBoxContainer
	for child in list.get_children():
		child.queue_free()

	var gold_lbl := _sell_panel.find_child("SellGoldLbl", true, false) as Label
	if gold_lbl:
		gold_lbl.text = "%d ✦" % Inventory.gold

	var available := Inventory.get_available()
	if available.is_empty():
		_lbl_colored(list, "No tienes objetos para vender.", 13, C_MUTED)
		return

	for item: ItemData in available:
		var sell_price: int = maxi(1, item.price / 2 as int)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		list.add_child(row)

		var name_lbl := Label.new()
		var qty_text := " ×%d" % item.quantity if item.item_type == ItemData.ItemType.CONSUMABLE else ""
		name_lbl.text = item.item_name + qty_text
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", C_TEXT)
		row.add_child(name_lbl)

		var price_lbl := Label.new()
		price_lbl.text = "%d ✦" % sell_price
		price_lbl.custom_minimum_size = Vector2(48, 0)
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price_lbl.add_theme_font_size_override("font_size", 13)
		price_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
		row.add_child(price_lbl)

		var captured := item
		var btn := _make_button("Vender", 80, 28)
		btn.pressed.connect(func():
			Inventory.gold += sell_price
			Inventory.remove_item(captured)
			_refresh_sell()
			_refresh_stats()
		)
		row.add_child(btn)

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
