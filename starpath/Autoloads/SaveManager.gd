extends Node

signal game_saved(slot: int)
signal game_loaded(slot: int)

const SLOT_COUNT := 20

var has_unsaved_changes: bool = true

# Posición pendiente a aplicar cuando el WorldMap termine de cargar
var _pending_pos: Vector2 = Vector2.ZERO
var _pending_dir: String  = ""
var has_pending_spawn: bool = false

func _ready() -> void:
	Inventory.changed.connect(func(): has_unsaved_changes = true)

func _slot_path(slot: int) -> String:
	return "user://slot_%02d.save" % slot

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

# Returns {empty, save_date, gold} for display in the slot list.
func get_slot_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {"empty": true}
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return {"empty": true}
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null:
		return {"empty": true}
	return {
		"empty":     false,
		"save_date": data.get("save_date", "??"),
		"gold":      int(data.get("gold", 0)),
		"level":     int(data.get("level", 1)),
	}

func save_game(slot: int) -> void:
	var data: Dictionary = {}
	data["save_date"] = Time.get_datetime_string_from_system().replace("T", " ").left(16)

	var player := _find_player()
	if player:
		data["pos_x"] = player.global_position.x
		data["pos_y"] = player.global_position.y
		data["dir"]   = player._last_dir

	data["gold"]  = Inventory.gold
	data["level"] = Inventory.current_level
	data["xp"]    = Inventory.current_xp

	var items_arr: Array = []
	for item: ItemData in Inventory.items:
		items_arr.append(_serialize_item(item))
	data["items"] = items_arr

	data["equipped_weapon"] = Inventory.equipped_weapon.item_name if Inventory.equipped_weapon else ""
	data["equipped_armor"]  = Inventory.equipped_armor.item_name  if Inventory.equipped_armor  else ""

	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

	has_unsaved_changes = false
	game_saved.emit(slot)

func load_game(slot: int) -> bool:
	if not has_save(slot):
		return false

	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null:
		return false

	Inventory.gold            = int(data.get("gold", 150))
	Inventory.current_level   = int(data.get("level", 1))
	Inventory.current_xp      = int(data.get("xp",    0))
	Inventory.items.clear()
	Inventory.equipped_weapon = null
	Inventory.equipped_armor  = null

	for item_dict in data.get("items", []):
		Inventory.items.append(_deserialize_item(item_dict))

	var wp_name: String = data.get("equipped_weapon", "")
	var ar_name: String = data.get("equipped_armor",  "")
	for item: ItemData in Inventory.items:
		if wp_name != "" and item.item_name == wp_name:
			Inventory.equipped_weapon = item
		elif ar_name != "" and item.item_name == ar_name:
			Inventory.equipped_armor = item

	# Refrescar HP/MP según el nivel restaurado
	Inventory.init_stats()
	Inventory.changed.emit()

	# Guardar posición pendiente; WorldMap la aplicará en _ready()
	if data.has("pos_x"):
		_pending_pos      = Vector2(float(data["pos_x"]), float(data["pos_y"]))
		_pending_dir      = data.get("dir", "down")
		has_pending_spawn = true

	game_loaded.emit(slot)
	return true

## Llamar desde WorldMap._ready() para colocar al jugador en la posición guardada.
func apply_pending_spawn(player: PlayerController) -> void:
	if not has_pending_spawn:
		return
	player.global_position = _pending_pos
	player._last_dir       = _pending_dir
	has_pending_spawn      = false

func _find_player() -> PlayerController:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0] as PlayerController

func _serialize_item(item: ItemData) -> Dictionary:
	return {
		"item_name":     item.item_name,
		"item_type":     int(item.item_type),
		"effect_type":   item.effect_type,
		"amount":        item.amount,
		"quantity":      item.quantity,
		"targets_enemy": item.targets_enemy,
		"price":         item.price,
		"attack_bonus":  item.attack_bonus,
		"defense_bonus": item.defense_bonus,
		"shop_category": item.shop_category,
	}

func _deserialize_item(d: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.item_name     = d.get("item_name",     "")
	item.item_type     = d.get("item_type",     0) as ItemData.ItemType
	item.effect_type   = d.get("effect_type",   "")
	item.amount        = d.get("amount",        0)
	item.quantity      = d.get("quantity",      1)
	item.targets_enemy = d.get("targets_enemy", false)
	item.price         = d.get("price",         0)
	item.attack_bonus  = d.get("attack_bonus",  0)
	item.defense_bonus = d.get("defense_bonus", 0)
	item.shop_category = d.get("shop_category", "todo")
	return item
