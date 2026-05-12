extends Node

signal changed

var items:            Array[ItemData] = []
var gold:             int             = 150
var equipped_weapon:  ItemData        = null
var equipped_armor:   ItemData        = null

func _ready() -> void:
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
