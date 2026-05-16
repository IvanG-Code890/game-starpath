extends Node2D

@onready var player:     PlayerController = $Player
@onready var pause_menu: PauseMenu        = $PauseMenu

func _ready() -> void:
	AudioManager.play_bgm("exploration")
	player.menu_requested.connect(pause_menu.toggle)
	_extract_decorative_tiles()
	_elevate_tall_objects()
	_setup_map_layers()   # DESPUÉS de modificar tiles: garantiza z_index correcto
	call_deferred("_setup_rio_layer")
	call_deferred("_setup_camera_limits")
	if Inventory.returning_from_battle:
		Inventory.returning_from_battle = false
		call_deferred("_restore_pre_battle_state")
	elif SaveManager.has_pending_spawn:
		call_deferred("_restore_saved_position")
	else:
		call_deferred("_trigger_lore_tutorial")

func _restore_pre_battle_state() -> void:
	player.global_position = Inventory.pre_battle_position
	player._last_dir       = Inventory.pre_battle_direction

func _restore_saved_position() -> void:
	SaveManager.apply_pending_spawn(player)

func _trigger_lore_tutorial() -> void:
	TutorialManager.try_show(
		"lore",
		"✦  STARPATH",
		"En el reino de Aetheria, una oscuridad sin nombre avanza desde las tierras del norte.\n\nLyra, joven maga del pueblo de Valden, recibe una señal del cosmos: las estrellas se apagan una a una.\n\nSolo tú puedes seguir el Camino de las Estrellas y descubrir la verdad antes de que la última luz se extinga.",
		true
	)

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
			child.z_index       = -10
			child.z_as_relative = false
		elif child.name in object_layers:
			child.z_index       = 10
			child.z_as_relative = false
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

# Separa la capa "tree" en dos partes:
#   • Capa "tree" original (z=10):  conserva las hojas/copa  → tapa al jugador (z=0)
#   • tree_trunk (z=-1):            recibe los troncos       → jugador encima del tronco
# Con y_sort_enabled=false en WorldMap, el z_index es el único criterio de orden,
# así que z=10 > z=0 (jugador) > z=-1 funciona siempre, independientemente de la Y.
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

	# ── Árboles ──────────────────────────────────────────────────────────────
	# Separa troncos (atlas.y == 2) a una nueva capa z=-1.
	# Las hojas (atlas.y != 2) se quedan en la capa "tree" original.
	# _setup_map_layers() le asignará z=10 a "tree", que con y_sort=false
	# garantiza que las hojas SIEMPRE queden encima del jugador (z=0).
	var tree_layer2: TileMapLayer = null
	for child in map.get_children():
		if child.name == "tree" and child is TileMapLayer:
			tree_layer2 = child
			break
	if tree_layer2 == null:
		return

	var tree_trunk := TileMapLayer.new()
	tree_trunk.name          = "tree_trunk"
	tree_trunk.z_index       = -1
	tree_trunk.z_as_relative = false
	tree_trunk.tile_set      = tree_layer2.tile_set
	map.add_child(tree_trunk)

	# Mueve SOLO los troncos a tree_trunk y los borra de la capa original.
	# Las hojas permanecen en "tree" (z=10 tras _setup_map_layers).
	var trunk_cells: Array = []
	for cell in tree_layer2.get_used_cells():
		if tree_layer2.get_cell_atlas_coords(cell).y == 2:
			trunk_cells.append(cell)

	for cell in trunk_cells:
		var src := tree_layer2.get_cell_source_id(cell)
		var alt := tree_layer2.get_cell_alternative_tile(cell)
		var ac  := tree_layer2.get_cell_atlas_coords(cell)
		tree_trunk.set_cell(cell, src, ac, alt)
		tree_layer2.erase_cell(cell)

func _setup_camera_limits() -> void:
	var map := get_node_or_null("map1")
	if map == null:
		return
	# Usa la capa "ground" como referencia del área total del mapa
	var ref_layer: TileMapLayer = null
	for child in map.get_children():
		if child is TileMapLayer and child.name == "ground":
			ref_layer = child
			break
	if ref_layer == null:
		return

	var rect      := ref_layer.get_used_rect()           # en coordenadas de tile
	var tile_size := ref_layer.tile_set.tile_size         # px por tile (ej. Vector2i(32,32))
	var origin: Vector2 = (map as Node2D).global_position

	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return

	cam.limit_left   = int(origin.x + rect.position.x * tile_size.x)
	cam.limit_top    = int(origin.y + rect.position.y * tile_size.y)
	cam.limit_right  = int(origin.x + (rect.position.x + rect.size.x) * tile_size.x)
	cam.limit_bottom = int(origin.y + (rect.position.y + rect.size.y) * tile_size.y)
