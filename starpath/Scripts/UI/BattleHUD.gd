class_name BattleHUD
extends CanvasLayer

# Diccionarios para acceder a los nodos UI de cada entidad por referencia directa.
# La clave es el BaseEntity; el valor es el nodo de control correspondiente.
var _hp_bars:   Dictionary = {}
var _sp_bars:   Dictionary = {}
var _hp_labels: Dictionary = {}
var _sp_labels: Dictionary = {}
var _panels:    Dictionary = {}

# Llama esto UNA vez antes de start_battle, pasando todos los combatientes.
func setup(entities: Array[BaseEntity]) -> void:
	for entity in entities:
		_build_row(entity)

# Resalta la entidad activa; las demás se atenúan.
func set_active_entity(entity: BaseEntity) -> void:
	for ent: BaseEntity in _panels:
		if ent == entity:
			_panels[ent].modulate = Color(1.3, 1.3, 0.85)
		else:
			_panels[ent].modulate = Color(0.55, 0.55, 0.55)

# ── Construcción dinámica de filas ────────────────────────────────────────────

func _build_row(entity: BaseEntity) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",     5)
	margin.add_theme_constant_override("margin_bottom",  5)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	# Nombre del personaje
	var name_lbl := Label.new()
	name_lbl.text = entity.stats.character_name
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)

	# Fila HP (verde)
	var hp := _build_bar_row("HP", Color(0.15, 0.75, 0.3), entity.current_hp, entity.stats.max_hp)
	vbox.add_child(hp[0])
	_hp_bars[entity]   = hp[1]
	_hp_labels[entity] = hp[2]

	# Fila SP (azul)
	var sp := _build_bar_row("SP", Color(0.2, 0.5, 1.0), entity.current_mp, entity.stats.max_mp)
	vbox.add_child(sp[0])
	_sp_bars[entity]   = sp[1]
	_sp_labels[entity] = sp[2]

	# La señal stats_changed ya existe — la reutilizamos sin tocar BaseEntity.
	entity.stats_changed.connect(func(): _refresh(entity))

	$Container.add_child(panel)
	_panels[entity] = panel

	# El HUD es solo visual: ignorar todos los eventos de ratón para que
	# los clics pasen al mundo 2D y lleguen a las ClickArea de los enemigos.
	_set_mouse_ignore(panel)

func _set_mouse_ignore(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_ignore(child)

func _build_bar_row(prefix: String, color: Color, val: int, max_val: int) -> Array:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = max_val
	bar.value    = val
	bar.modulate = color
	hbox.add_child(bar)

	var lbl := Label.new()
	lbl.text = "%s  %d / %d" % [prefix, val, max_val]
	lbl.add_theme_font_size_override("font_size", 12)
	hbox.add_child(lbl)

	return [hbox, bar, lbl]

# ── Actualización en tiempo real ──────────────────────────────────────────────

func _refresh(entity: BaseEntity) -> void:
	_hp_bars[entity].value    = entity.current_hp
	_hp_labels[entity].text   = "HP  %d / %d" % [entity.current_hp, entity.stats.max_hp]
	_sp_bars[entity].value    = entity.current_mp
	_sp_labels[entity].text   = "SP  %d / %d" % [entity.current_mp, entity.stats.max_mp]
