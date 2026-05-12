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

	# ── Capa "building": antorcha y estatua ──────────────────────────────────
	var building_layer: TileMapLayer = null
	for child in map.get_children():
		if child.name == "building" and child is TileMapLayer:
			building_layer = child
			break
	if building_layer != null:
		var tall_layer := TileMapLayer.new()
		tall_layer.name          = "tall_objects"
		tall_layer.z_index       = 10
		tall_layer.z_as_relative = false
		tall_layer.tile_set      = building_layer.tile_set
		map.add_child(tall_layer)

		# Solo la CABEZA/LLAMA va a z=10; las PATAS se quedan en building.
		var tall_coords := [Vector2i(3, 113), Vector2i(3, 115)]

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

	# ── Borde inferior del dosel (filas 2-4 de "tree") ───────────────────────
	# Estas filas son el collar/tronco superior del árbol. Al estar en z=10
	# tapan al jugador cuando está cerca aunque sea por el sur.
	# Se mueven a una capa hija de WorldMap con y_sort (z=0) para que el
	# jugador quede delante al sur y detrás al norte.
	# Los troncos de "grass" (z=-10) no se tocan: jugador siempre delante.
	var tree_layer2 : TileMapLayer = null
	for child in map.get_children():
		if child.name == "tree" and child is TileMapLayer:
			tree_layer2 = child
			break
	if tree_layer2 != null:
		var lower_layer := TileMapLayer.new()
		lower_layer.name          = "tree_lower"
		lower_layer.z_index       = -1      # z dinámico: se actualiza en _process
		lower_layer.z_as_relative = false   # z absoluto: -1 = debajo jugador (z=0)
		lower_layer.position      = map.position
		lower_layer.tile_set      = tree_layer2.tile_set
		add_child(lower_layer)

		var cells_lower: Array = []
		for cell in tree_layer2.get_used_cells():
			var ac : Vector2i = tree_layer2.get_cell_atlas_coords(cell)
			if ac.y >= 2 and ac.y <= 4:
				cells_lower.append(cell)
		for cell in cells_lower:
			var sid := tree_layer2.get_cell_source_id(cell)
			var alt := tree_layer2.get_cell_alternative_tile(cell)
			var ac  : Vector2i = tree_layer2.get_cell_atlas_coords(cell)
			lower_layer.set_cell(cell, sid, ac, alt)
			tree_layer2.erase_cell(cell)

# Actualiza el z_index de tree_lower cada frame:
# - Si el jugador pisa un tile del collar → z=1 (collar encima del jugador)
# - Si no                                → z=-1 (jugador encima del collar)
func _process(_delta: float) -> void:
	var lower := get_node_or_null("tree_lower") as TileMapLayer
	if lower == null:
		return
	var cell := lower.local_to_map(lower.to_local(player.global_position))
	# Busca tiles del collar en la celda actual y en las 2 filas hacia el sur
	# (± 1 columna). Así el jugador queda tapado cuando está justo encima del collar.
	# Solo miramos sur (dy >= 0) para no activar z=1 cuando el collar ya quedó al norte.
	var under_canopy := false
	for dy in range(0, 3):
		for dx in range(-1, 2):
			if lower.get_cell_source_id(Vector2i(cell.x + dx, cell.y + dy)) != -1:
				under_canopy = true
				break
		if under_canopy:
			break
	lower.z_index = 1 if under_canopy else -1
