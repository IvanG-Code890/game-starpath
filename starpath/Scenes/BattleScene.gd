extends Node2D

@onready var battle_manager = $BattleManager

@onready var hero_logic = $HeroSprite/Logic
@onready var enemy_logic = $EnemySprite/Logic

func _ready() -> void:
	print("--- CARGANDO ESCENA DE BATALLA ---")
	
	# Creamos los equipos
	var team_heroes: Array[BaseEntity] = [hero_logic]
	var team_enemies: Array[BaseEntity] = [enemy_logic]
	
	# Le damos al botón de inicio del BattleManager
	battle_manager.start_battle(team_heroes, team_enemies)
