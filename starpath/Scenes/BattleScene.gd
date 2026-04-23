extends Node2D

@onready var battle_manager = $BattleManager
@onready var hero_logic = $HeroSprite/Logic
@onready var enemy_logic = $EnemySprite/Logic

# ── REFERENCIAS SEPARADAS DE LA INTERFAZ ───────────────────────────────────
# Enganchamos las dos ramas por separado en lugar de coger el CanvasLayer entero
@onready var menu_combate = $BattleUI/VBoxContainer
@onready var end_panel = $BattleUI/Panel
@onready var result_label = $BattleUI/Panel/VBoxContainer/LblResolution

func _ready() -> void:
	print("--- CARGANDO ESCENA DE BATALLA ---")
	
	# Escondemos ambas pantallas al empezar
	menu_combate.visible = false 
	end_panel.visible = false 
	
	# Conectamos las señales
	battle_manager.action_menu_toggled.connect(_on_menu_toggled)
	battle_manager.battle_ended.connect(_on_battle_ended)
	
	var team_heroes: Array[BaseEntity] = [hero_logic]
	var team_enemies: Array[BaseEntity] = [enemy_logic]
	
	battle_manager.start_battle(team_heroes, team_enemies)

func _on_menu_toggled(show_menu: bool) -> void:
	# Encendemos/apagamos SOLO el menú de combate, no el Canvas entero
	if not end_panel.visible:
		menu_combate.visible = show_menu

func _on_btn_atacar_pressed() -> void:
	# Añado este print para que confirmemos si el clic llega
	print("¡Clic detectado en el botón Atacar!")
	battle_manager.player_action_selected("Atacar")

func _on_battle_ended(player_won: bool) -> void:
	# Ocultamos el menú de combate y mostramos el panel de Fin
	menu_combate.visible = false 
	end_panel.visible = true
	
	if player_won:
		result_label.text = "¡VICTORIA!"
	else:
		result_label.text = "DERROTA..."

func _on_btn_reiniciar_pressed() -> void:
	get_tree().reload_current_scene()


func _on_attack_button_pressed() -> void:
	pass # Replace with function body.
