extends Node

var items: Array[ItemData] = []

func _ready() -> void:
	var pocion := ItemData.new()
	pocion.item_name = "Poción"
	pocion.effect_type = "heal_hp"
	pocion.amount = 50
	pocion.quantity = 3
	items.append(pocion)

	var eter := ItemData.new()
	eter.item_name = "Éter"
	eter.effect_type = "heal_mp"
	eter.amount = 30
	eter.quantity = 2
	items.append(eter)

func use_item(item: ItemData) -> void:
	item.quantity -= 1

func get_available() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in items:
		if item.quantity > 0:
			result.append(item)
	return result
