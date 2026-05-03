class_name BaseEntity
extends Node

signal stats_changed
signal defeated
signal defense_changed(defending: bool)

@export var stats: CharacterStats

var current_hp: int
var current_mp: int
var is_alive: bool    = true
var is_defending: bool = false

func _ready():
	if stats:
		current_hp = stats.max_hp
		current_mp = stats.max_mp

func take_damage(amount: int):
	var effective_damage = max(1, amount - (stats.defense / 2))
	if is_defending:
		effective_damage = max(1, effective_damage / 2)
		is_defending = false
		defense_changed.emit(false)
	current_hp = max(0, current_hp - effective_damage)
	stats_changed.emit()

	if current_hp <= 0:
		is_alive = false
		defeated.emit()

func start_defending() -> void:
	is_defending = true
	defense_changed.emit(true)

# Descuenta MP y emite stats_changed. Devuelve false si no hay suficiente.
func spend_mp(amount: int) -> bool:
	if current_mp < amount:
		return false
	current_mp -= amount
	stats_changed.emit()
	return true

# Devuelve false si no hay MP suficiente (el BattleManager puede loguear el aviso).
func heal_hp(amount: int) -> void:
	current_hp = mini(current_hp + amount, stats.max_hp)
	stats_changed.emit()

func heal_mp(amount: int) -> void:
	current_mp = mini(current_mp + amount, stats.max_mp)
	stats_changed.emit()

func heal_self(hp_amount: int = 30, mp_cost: int = 15) -> bool:
	if current_mp < mp_cost:
		return false
	current_mp -= mp_cost
	current_hp = mini(current_hp + hp_amount, stats.max_hp)
	stats_changed.emit()
	return true
