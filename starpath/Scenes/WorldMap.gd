extends Node2D

@onready var player:     PlayerController = $Player
@onready var pause_menu: PauseMenu        = $PauseMenu

func _ready() -> void:
	player.menu_requested.connect(pause_menu.toggle)
	_setup_map_layers()
	_extract_decorative_tiles()
	_elevate_tall_objects()
	call_deferred("_setup_rio_layer")

func _setup_rio_layer() -> void:
	var map := get_node_or_null("map1")
	if map == null:
		return
	var rio := map.find_child("rio", true, false)
	if rio == null:
		return
	for child in rio.get_children():
		if child is StaticBody2D:
			child.collision_layer = 2

func _setup_map_layers() -> void:
	var map := get_node_or_null("map1")
	if map == null:
		return
	var ground_layers := ["ground", "grass", "water", "water_grass", "farm", "building"]
	var object_layers := ["tree", "building_up", "farm_up"]
	for child in map.get_children():
		if child.name in ground_layers:
			child.z_index = -10
		elif child.name in object_layers:
			child.z_index = 10
		# Mueve los tiles de agua a la capa de colisión 2
		# para que BridgeArea pueda ignorarlos cambiando la máscara del jugador
		if child.name == "water" and child is TileMapLayer:
			var ts := child.tile_set.duplicate() as TileSet
			for i in ts.get_physics_layers_count():
				ts.set_physics_layer_collision_layer(i, 2)
			child.tile_set = ts

# Mueve arbustos (40-42), hierbas (48-49) y flores (51-55) de la capa "tree"
# a una nueva capa con z=-5 para que el jugador quede encima.
func _extract_decorative_tiles() -> void:
	var map := get_node_or_null("map1")
	if map == null:
		return

	var tree_layer: TileMapLayer = null
	for child in map.get_children():
		if child.name == "tree" and child is TileMapLayer:
			tree_layer = child
			break
	if tree_layer == null:
		return

	var deco_layer := TileMapLayer.new()
	deco_layer.name          = "deco_layer"
	deco_layer.z_index       = -5
	deco_layer.z_as_relative = false
	deco_layer.tile_set      = tree_layer.tile_set
	map.add_child(deco_layer)

	var deco_atlas_coords := [
		Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5),  # arbustos  ID 40-42
		Vector2i(0, 6), Vector2i(1, 6),                   # hierbas   ID 48-49
		Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6),  # flores    ID 51-53
		Vector2i(6, 6), Vector2i(7, 6)                    # flores    ID 54-55
	]

	var cells_to_move: Array = []
	for cell in tree_layer.get_used_cells():
		if tree_layer.get_cell_atlas_coords(cell) in deco_atlas_coords:
			cells_to_move.append(cell)

	for cell in cells_to_move:
		var src := tree_layer.get_cell_source_id(cell)
		var alt := tree_layer.get_cell_alternative_tile(cell)
		var ac  := tree_layer.get_cell_atlas_coords(cell)
		deco_layer.set_cell(cell, src, ac, alt)
		tree_layer.erase_cell(cell)

# Mueve la antorcha (y otros objetos altos del building layer) a z=10
# para que cubran al jugador igual que los árboles.
# ID 907 → atlas (3,113)  cabeza antorcha
# ID 915 → atlas (3,114)  patas  antorcha
func _elevate_tall_objects() -> void:
	var map := get_node_or_null("map1")
	if map == null:
		return

	var building_layer: TileMapLayer = null
	for child in map.get_children():
		if child.name == "building" and child is TileMapLayer:
			building_layer = child
			break
	if building_layer == null:
		return

	var tall_layer := TileMapLayer.new()
	tall_layer.name          = "tall_objects"
	tall_layer.z_index       = 10
	tall_layer.z_as_relative = false
	tall_layer.tile_set      = building_layer.tile_set
	map.add_child(tall_layer)

	# Solo la CABEZA/LLAMA va a z=10 (tapa al jugador como el dosel de un árbol).
	# Las PATAS (3,114) se quedan en building (z=-10): el jugador pasa por delante.
	var tall_coords := [Vector2i(3, 113)]

	var cells_to_move: Array = []
	for cell in building_layer.get_used_cells():
		if building_layer.get_cell_atlas_coords(cell) in tall_coords:
			cells_to_move.append(cell)

	for cell in cells_to_move:
		var src := building_layer.get_cell_source_id(cell)
		var alt := building_layer.get_cell_alternative_tile(cell)
		var ac  := building_layer.get_cell_atlas_coords(cell)
		tall_layer.set_cell(cell, src, ac, alt)
		building_layer.erase_cell(cell)
