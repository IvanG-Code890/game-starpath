class_name CombatantSprite
extends Node2D

signal clicked(entity: BaseEntity)

# ── Referencias a los Nodos Visuales de esta escena ────────────────────────
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var mana_bar: ProgressBar = $ManaBar

# ── Referencia al Cerebro Lógico ───────────────
@export var entity_logic: BaseEntity

var is_selectable: bool = false  # BattleScene lo activa durante la selección de objetivo

var _prev_hp: int = 0
var _initialized: bool = false

func _ready() -> void:
	if not entity_logic:
		push_error("CombatantSprite: ¡A " + name + " le falta asignarle su nodo Logic!")
		return

	entity_logic.stats_changed.connect(_on_stats_changed)
	entity_logic.defeated.connect(_on_defeated)
	entity_logic.defense_changed.connect(_on_defense_changed)

	# Solo los sprites que tienen ClickArea (enemigos) responden al ratón
	if has_node("ClickArea"):
		$ClickArea.input_event.connect(_on_click_area_input)
		$ClickArea.mouse_entered.connect(_on_mouse_entered)
		$ClickArea.mouse_exited.connect(_on_mouse_exited)

	_on_stats_changed()
	_initialized = true

# ── Selección de objetivo ──────────────────────────────────────────────────

func _on_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_selectable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(entity_logic)

func _on_mouse_entered() -> void:
	if is_selectable:
		sprite.modulate = Color(1.5, 1.4, 0.7)  # amarillo cálido — hover

func _on_mouse_exited() -> void:
	if is_selectable:
		sprite.modulate = Color(0.55, 0.8, 1.0) if entity_logic.is_defending else Color(1, 1, 1)

# ── Reacciones Visuales ────────────────────────────────────────────────────

func _on_stats_changed() -> void:
	health_bar.max_value = entity_logic.stats.max_hp
	health_bar.value = entity_logic.current_hp
	mana_bar.max_value = entity_logic.stats.max_mp
	mana_bar.value = entity_logic.current_mp

func _on_defeated() -> void:
	print(name + " ha sido derrotado visualmente.")
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)

# ── Número flotante de daño / curación ────────────────────────────────────

func _spawn_floating_text(text: String, color: Color) -> void:
	var label := Label.new()
	label.text     = text
	label.modulate = color
	label.z_index  = 10
	label.add_theme_font_size_override("font_size", 22)
	label.position = sprite.position + Vector2(-20, -80)
	add_child(label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.2)
	tween.finished.connect(label.queue_free)
