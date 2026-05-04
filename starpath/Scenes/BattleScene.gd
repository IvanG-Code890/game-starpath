extends Node2D

@onready var battle_manager = $BattleManager
@onready var hero_logic     = $HeroSprite/Logic
@onready var hero2_logic    = $Hero2Sprite/Logic
@onready var enemy_logic    = $EnemySprite/Logic
@onready var enemy2_logic   = $Enemy2Sprite/Logic
@onready var battle_hud     = $BattleHUD

@onready var menu_combate     = $BattleUI/VBoxContainer
@onready var cancel_btn       = $BattleUI/CancelarButton
@onready var curar_btn        = $BattleUI/VBoxContainer/CurarButton
@onready var magia_btn        = $BattleUI/VBoxContainer/MagiaButton
@onready var skills_panel     = $BattleUI/SkillsPanel
@onready var skills_container = $BattleUI/SkillsPanel/VBoxContainer
@onready var objetos_panel      = $BattleUI/ObjetosPanel
@onready var objetos_container  = $BattleUI/ObjetosPanel/VBoxContainer
@onready var end_panel        = $BattleUI/Panel
@onready var result_label     = $BattleUI/Panel/VBoxContainer/LblResolution

var _active_hero: BaseEntity = null

# Nombres de clase para el botón de habilidades
const CLASS_NAMES := {
	0: "Guerrero",
	1: "Mago",
	2: "Pícaro",
	3: "Sanador",
	4: "Paladín",
	5: "Arquero"
}

# Clases que tienen panel de habilidades mágicas
const MAGIC_CLASSES := [
	CharacterStats.ClassType.MAGO,
	CharacterStats.ClassType.SANADOR
]

func _ready() -> void:
	print("--- CARGANDO ESCENA DE BATALLA ---")

	menu_combate.visible  = false
	end_panel.visible     = false
	skills_panel.visible  = false
	objetos_panel.visible = false
	cancel_btn.visible    = false

	battle_manager.action_menu_toggled.connect(_on_menu_toggled)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.active_entity_changed.connect(battle_hud.set_active_entity)
	battle_manager.active_entity_changed.connect(_on_active_entity_changed)
	battle_manager.target_selection_needed.connect(_on_target_selection_needed)
	battle_manager.ally_target_selection_needed.connect(_on_ally_target_selection_needed)

	var team_heroes:  Array[BaseEntity] = [hero_logic, hero2_logic]
	var team_enemies: Array[BaseEntity] = [enemy_logic, enemy2_logic]

	battle_hud.setup(team_heroes)
	battle_manager.start_battle(team_heroes, team_enemies)

# ── Seguimiento del héroe activo ──────────────────────────────────────────────

func _on_active_entity_changed(entity: BaseEntity) -> void:
	if entity.get_parent().is_in_group("Heroes"):
		_active_hero = entity

# ── Actualización del menú según la clase del héroe ──────────────────────────

func _update_menu_for_hero(hero: BaseEntity) -> void:
	if hero == null:
		return

	var class_id: int = hero.stats.character_class
	var class_label: String = CLASS_NAMES.get(class_id, "Héroe")

	# Botón de habilidades: solo Mago y Sanador
	var has_skills: bool = class_id in MAGIC_CLASSES
	magia_btn.visible = has_skills
	if has_skills:
		magia_btn.text = "Hab. de %s ▶" % class_label

	# Curar: solo Sanador
	curar_btn.visible = (class_id == CharacterStats.ClassType.SANADOR)

	# Reconstruir botones de habilidades para este héroe
	_build_skill_buttons(hero)

func _build_skill_buttons(hero: BaseEntity) -> void:
	for child in skills_container.get_children():
		child.queue_free()
	for skill: SkillData in hero.stats.skills:
		var btn := Button.new()
		btn.text = "%s  (%d MP)" % [skill.skill_name, skill.mp_cost]
		btn.custom_minimum_size = Vector2(160, 0)
		btn.pressed.connect(_on_skill_btn_pressed.bind(skill))
		skills_container.add_child(btn)

# ── Señales del BattleManager ─────────────────────────────────────────────────

func _on_menu_toggled(show_menu: bool) -> void:
	if not end_panel.visible:
		menu_combate.visible = show_menu
		if not show_menu:
			skills_panel.visible  = false
			objetos_panel.visible = false
		else:
			cancel_btn.visible = false
			_update_menu_for_hero(_active_hero)

func _on_target_selection_needed(enemies: Array[BaseEntity]) -> void:
	for entity in [enemy_logic, enemy2_logic]:
		var s := entity.get_parent() as CombatantSprite
		if s:
			s.is_selectable = false
			if s.clicked.is_connected(_on_enemy_sprite_clicked):
				s.clicked.disconnect(_on_enemy_sprite_clicked)

	if enemies.is_empty():
		return

	for entity: BaseEntity in enemies:
		var s := entity.get_parent() as CombatantSprite
		if s:
			s.is_selectable = true
			s.clicked.connect(_on_enemy_sprite_clicked)

	cancel_btn.visible = true

func _on_ally_target_selection_needed(allies: Array[BaseEntity]) -> void:
	for entity in [hero_logic, hero2_logic]:
		var s := entity.get_parent() as CombatantSprite
		if s:
			s.is_selectable = false
			if s.clicked.is_connected(_on_ally_sprite_clicked):
				s.clicked.disconnect(_on_ally_sprite_clicked)

	if allies.is_empty():
		return

	for entity: BaseEntity in allies:
		var s := entity.get_parent() as CombatantSprite
		if s:
			s.is_selectable = true
			s.clicked.connect(_on_ally_sprite_clicked)

	cancel_btn.visible = true

func _on_ally_sprite_clicked(entity: BaseEntity) -> void:
	battle_manager.player_target_confirmed(entity)

func _on_enemy_sprite_clicked(entity: BaseEntity) -> void:
	battle_manager.player_target_confirmed(entity)

# ── Botones del menú ──────────────────────────────────────────────────────────

func _on_btn_atacar_pressed() -> void:
	battle_manager.player_action_selected("Atacar")

func _on_btn_curar_pressed() -> void:
	battle_manager.player_action_selected("Curar")

func _on_btn_defender_pressed() -> void:
	battle_manager.player_action_selected("Defender")

func _on_btn_magia_pressed() -> void:
	objetos_panel.visible = false
	skills_panel.visible  = not skills_panel.visible
	cancel_btn.visible    = skills_panel.visible

func _on_btn_objetos_pressed() -> void:
	skills_panel.visible = false
	if not objetos_panel.visible:
		_refresh_item_buttons()
	objetos_panel.visible = not objetos_panel.visible
	cancel_btn.visible    = objetos_panel.visible

func _refresh_item_buttons() -> void:
	for child in objetos_container.get_children():
		child.queue_free()
	var available := Inventory.get_available()
	if available.is_empty():
		var lbl := Label.new()
		lbl.text = "Sin objetos"
		objetos_container.add_child(lbl)
	else:
		for item: ItemData in available:
			var btn := Button.new()
			btn.text = "%s  x%d" % [item.item_name, item.quantity]
			btn.custom_minimum_size = Vector2(160, 0)
			btn.pressed.connect(_on_item_btn_pressed.bind(item))
			objetos_container.add_child(btn)

func _on_item_btn_pressed(item: ItemData) -> void:
	objetos_panel.visible = false
	battle_manager.player_item_selected(item)

func _on_btn_cancelar_pressed() -> void:
	cancel_btn.visible    = false
	skills_panel.visible  = false
	objetos_panel.visible = false
	if battle_manager.current_state == BattleManager.BattleState.SELECTING_TARGET:
		battle_manager.player_target_cancelled()
	else:
		menu_combate.visible = true

func _on_skill_btn_pressed(skill: SkillData) -> void:
	skills_panel.visible = false
	cancel_btn.visible   = false
	battle_manager.player_skill_selected(skill)

func _on_battle_ended(player_won: bool) -> void:
	menu_combate.visible = false
	end_panel.visible    = true
	result_label.text    = "¡VICTORIA!" if player_won else "DERROTA..."

func _on_btn_reiniciar_pressed() -> void:
	get_tree().reload_current_scene()
