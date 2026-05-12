class_name CombatantSprite
extends Node2D

# ── Referencias a los Nodos Visuales de esta escena ────────────────────────
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var mana_bar: ProgressBar = $ManaBar

# ── Referencia al Cerebro Lógico ───────────────
@export var entity_logic: BaseEntity 

func _ready() -> void:
	if not entity_logic:
		push_error("CombatantSprite: ¡A " + name + " le falta asignarle su nodo Logic!")
		return
		
	# Conectamos las señales del cerebro lógico a nuestras funciones visuales
	entity_logic.stats_changed.connect(_on_stats_changed)
	entity_logic.defeated.connect(_on_defeated)
	
	# Inicializamos la barra de vida para que empiece llena
	_on_stats_changed()

# ── Reacciones Visuales ────────────────────────────────────────────────────
func _on_stats_changed() -> void:
	health_bar.max_value = entity_logic.stats.max_hp
	health_bar.value = entity_logic.current_hp
	mana_bar.max_value = entity_logic.stats.max_mp
	mana_bar.value = entity_logic.current_mp

func _on_defeated() -> void:
	print(name + " ha sido derrotado visualmente.")
	# Hacemos que el sprite desaparezca poco a poco al morir (efecto fantasma)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
