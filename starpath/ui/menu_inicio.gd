extends Control

# ── Nodos principales ─────────────────────────────────────────────────────────
@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options_panel: Panel = $Options
@onready var music_slider: HSlider = $Options/OptionsMargin/VBox/MusicRow/MusicVolumeSlider
@onready var sfx_slider: HSlider = $Options/OptionsMargin/VBox/SFXRow/SFXVolumeSlider
@onready var window_mode_option: OptionButton = $Options/OptionsMargin/VBox/WindowModeRow/WindowModeOption
@onready var menu_music: AudioStreamPlayer = $MenuMusic

# ── UI dinámica ───────────────────────────────────────────────────────────────
var _music_pct: Label
var _sfx_pct: Label
var _load_panel: Panel
var _slot_list: VBoxContainer
var _font: Font

const WORLD_MAP_SCENE := "res://Scenes/World/WorldMap.tscn"
const FONT_PATH := "res://Assets/Fonts/CinzelDecorative-Bold.ttf"


func _ready() -> void:
	_font = load(FONT_PATH)

	main_buttons.visible = true
	options_panel.visible = false

	_setup_audio()
	_setup_window_mode()
	_build_load_panel()


# ══════════════════════════════════════════════════════════════════════════════
#  AUDIO
# ══════════════════════════════════════════════════════════════════════════════

func _ensure_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		return idx
	# Crear el bus si no existe
	var new_idx := AudioServer.bus_count
	AudioServer.add_bus(new_idx)
	AudioServer.set_bus_name(new_idx, bus_name)
	AudioServer.set_bus_send(new_idx, "Master")
	return new_idx


func _setup_audio() -> void:
	# Asegurar que los buses existan
	_ensure_bus("Music")
	_ensure_bus("SFX")

	# Crear etiquetas de porcentaje junto a cada slider
	_music_pct = _make_pct_label()
	music_slider.get_parent().add_child(_music_pct)

	_sfx_pct = _make_pct_label()
	sfx_slider.get_parent().add_child(_sfx_pct)

	# Valor inicial desde el bus
	var m_bus := AudioServer.get_bus_index("Music")
	var m_db := AudioServer.get_bus_volume_db(m_bus)
	music_slider.set_value_no_signal(db_to_linear(m_db) if m_db > -79.0 else 0.0)

	var s_bus := AudioServer.get_bus_index("SFX")
	var s_db := AudioServer.get_bus_volume_db(s_bus)
	sfx_slider.set_value_no_signal(db_to_linear(s_db) if s_db > -79.0 else 0.0)

	_music_pct.text = "%d%%" % int(music_slider.value * 100)
	_sfx_pct.text = "%d%%" % int(sfx_slider.value * 100)

	# Conectar señales
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)


func _make_pct_label() -> Label:
	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(60, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _font:
		lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.text = "50%"
	return lbl


func _on_music_changed(val: float) -> void:
	var db := linear_to_db(val) if val > 0.0 else -80.0
	# Controlar el bus
	var bus := AudioServer.get_bus_index("Music")
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, db)
	# Controlar directamente el reproductor de música del menú
	if menu_music:
		menu_music.volume_db = db
	_music_pct.text = "%d%%" % int(val * 100)


func _on_sfx_changed(val: float) -> void:
	var bus := AudioServer.get_bus_index("SFX")
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, linear_to_db(val) if val > 0.0 else -80.0)
	_sfx_pct.text = "%d%%" % int(val * 100)


# ══════════════════════════════════════════════════════════════════════════════
#  VENTANA
# ══════════════════════════════════════════════════════════════════════════════

func _setup_window_mode() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("Ventana", 0)
	window_mode_option.add_item("Pantalla completa", 1)
	window_mode_option.select(1 if SettingsManager.is_fullscreen() else 0)


func _on_window_mode_selected(index: int) -> void:
	SettingsManager.set_fullscreen(index == 1)


# ══════════════════════════════════════════════════════════════════════════════
#  PANEL CARGAR PARTIDA
# ══════════════════════════════════════════════════════════════════════════════

func _build_load_panel() -> void:
	_load_panel = Panel.new()
	_load_panel.anchor_left = 0.5
	_load_panel.anchor_top = 0.5
	_load_panel.anchor_right = 0.5
	_load_panel.anchor_bottom = 0.5
	_load_panel.offset_left = -300.0
	_load_panel.offset_top = -250.0
	_load_panel.offset_right = 300.0
	_load_panel.offset_bottom = 250.0
	_load_panel.visible = false
	add_child(_load_panel)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	_load_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Título
	var title := Label.new()
	title.text = "Cargar partida"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font:
		title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	# Scroll con los slots
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_slot_list = VBoxContainer.new()
	_slot_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slot_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_slot_list)

	# Botón volver
	var back_btn := Button.new()
	back_btn.text = "Volver"
	back_btn.custom_minimum_size = Vector2(0, 44)
	if _font:
		back_btn.add_theme_font_override("font", _font)
	back_btn.add_theme_font_size_override("font_size", 22)
	back_btn.add_theme_color_override("font_color", Color.BLACK)
	back_btn.pressed.connect(_on_load_back_pressed)
	vbox.add_child(back_btn)


func _populate_load_slots() -> void:
	# Limpiar slots anteriores
	for child in _slot_list.get_children():
		child.queue_free()

	var has_any := false
	for slot in range(SaveManager.SLOT_COUNT):
		var info := SaveManager.get_slot_info(slot)
		if info.get("empty", true):
			continue

		has_any = true
		var btn := Button.new()
		btn.text = "Slot %d  —  %s  —  %d oro" % [slot + 1, info.get("save_date", "??"), info.get("gold", 0)]
		btn.custom_minimum_size = Vector2(0, 40)
		if _font:
			btn.add_theme_font_override("font", _font)
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", Color.BLACK)
		btn.pressed.connect(_on_slot_selected.bind(slot))
		_slot_list.add_child(btn)

	if not has_any:
		var lbl := Label.new()
		lbl.text = "No hay partidas guardadas"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _font:
			lbl.add_theme_font_override("font", _font)
		lbl.add_theme_font_size_override("font_size", 18)
		_slot_list.add_child(lbl)


func _on_slot_selected(slot: int) -> void:
	if SaveManager.load_game(slot):
		get_tree().change_scene_to_file(WORLD_MAP_SCENE)


func _on_load_back_pressed() -> void:
	_load_panel.visible = false
	main_buttons.visible = true


# ══════════════════════════════════════════════════════════════════════════════
#  BOTONES PRINCIPALES
# ══════════════════════════════════════════════════════════════════════════════

func _on_new_game_pressed() -> void:
	Inventory.gold = 150
	Inventory.items.clear()
	Inventory.equipped_weapon = null
	Inventory.equipped_armor = null
	SaveManager.has_unsaved_changes = true
	get_tree().change_scene_to_file(WORLD_MAP_SCENE)


func _on_load_game_pressed() -> void:
	main_buttons.visible = false
	_populate_load_slots()
	_load_panel.visible = true


func _on_options_pressed() -> void:
	main_buttons.visible = false
	options_panel.visible = true


func _on_back_options_pressed() -> void:
	options_panel.visible = false
	main_buttons.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()
