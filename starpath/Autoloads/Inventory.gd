extends Node

signal changed
signal level_changed(new_level: int)

const HERO_STATS_PATH := "res://Resources/Characters/Hero.tres"

var items:            Array[ItemData] = []
var gold:             int             = 150
var equipped_weapon:  ItemData        = null
var equipped_armor:   ItemData        = null

var current_hp: int = 0
var current_mp: int = 0

# Posición guardada justo antes de entrar en combate
var pre_battle_position:  Vector2 = Vector2.ZERO
var pre_battle_direction: String  = "down"
var returning_from_battle: bool   = false

# ── Progresión ────────────────────────────────────────────────────────────────
var current_level: int = 1
var current_xp:    int = 0

# Base stats leídas de Hero.tres en _ready() (no cambian por nivel)
var _base_max_hp: int = 80
var _base_max_mp: int = 100

## HP máximo según nivel actual (base + bonificación por nivel).
func get_max_hp() -> int:
	return _base_max_hp + (current_level - 1) * 10

## MP máximo según nivel actual.
func get_max_mp() -> int:
	return _base_max_mp + (current_level - 1) * 5

## XP necesaria para pasar del nivel actual al siguiente.
func xp_to_next() -> int:
	return current_level * 100

## Otorga XP; si supera el umbral, sube de nivel (puede ocurrir varias veces).
func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_next():
		current_xp -= xp_to_next()
		current_level += 1
		_apply_level_up()
	changed.emit()

func _apply_level_up() -> void:
	current_hp = get_max_hp()   # HP y MP restaurados al nuevo máximo
	current_mp = get_max_mp()
	level_changed.emit(current_level)

## Bonificación de ataque acumulada por niveles.
func get_level_atk_bonus() -> int:
	return (current_level - 1) * 2

## Bonificación de defensa acumulada por niveles.
func get_level_def_bonus() -> int:
	return current_level - 1

## Inicializa HP/MP al máximo para el nivel actual (usar en nueva partida y carga).
func init_stats() -> void:
	current_hp = get_max_hp()
	current_mp = get_max_mp()

func _ready() -> void:
	var base: CharacterStats = load(HERO_STATS_PATH)
	if base:
		_base_max_hp = base.max_hp
		_base_max_mp = base.max_mp
	init_stats()
	var pocion := ItemData.new()
	pocion.item_name   = "Poción"
	pocion.item_type   = ItemData.ItemType.CONSUMABLE
	pocion.effect_type = "heal_hp"
	pocion.amount      = 50
	pocion.quantity    = 3
	items.append(pocion)

	var eter := ItemData.new()
	eter.item_name   = "Éter"
	eter.item_type   = ItemData.ItemType.CONSUMABLE
	eter.effect_type = "heal_mp"
	eter.amount      = 30
	eter.quantity    = 2
	items.append(eter)

func use_item(item: ItemData) -> void:
	item.quantity -= 1
	changed.emit()

func get_available() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in items:
		if item.quantity > 0:
			result.append(item)
	return result

## Añade un item al inventario (los consumibles se apilan por nombre).
func add_item(source: ItemData) -> void:
	if source.item_type == ItemData.ItemType.CONSUMABLE:
		for item in items:
			if item.item_name == source.item_name:
				item.quantity += 1
				changed.emit()
				return
	var copy          := source.duplicate() as ItemData
	copy.quantity      = 1
	items.append(copy)
	changed.emit()

func equip(item: ItemData) -> void:
	if item.item_type == ItemData.ItemType.WEAPON:
		equipped_weapon = item
	elif item.item_type == ItemData.ItemType.ARMOR:
		equipped_armor = item
	changed.emit()

func unequip(item: ItemData) -> void:
	if item == equipped_weapon:
		equipped_weapon = null
	elif item == equipped_armor:
		equipped_armor = null
	changed.emit()

## Quita una unidad del item; si es arma/armadura lo elimina del array (y desequipa).
func remove_item(item: ItemData) -> void:
	if item.item_type == ItemData.ItemType.CONSUMABLE:
		item.quantity -= 1
		if item.quantity <= 0:
			items.erase(item)
	else:
		unequip(item)
		items.erase(item)
	changed.emit()

func get_attack_bonus() -> int:
	return equipped_weapon.attack_bonus if equipped_weapon else 0

func get_defense_bonus() -> int:
	return equipped_armor.defense_bonus if equipped_armor else 0
