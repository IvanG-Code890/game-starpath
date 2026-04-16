class_name BattleManager
extends Node

# ── Máquina de Estados ─────────────────────────────────────────────────────
enum BattleState { STARTING, NEXT_TURN, PLAYER_INPUT, ENEMY_TURN, WON, LOST }
var current_state: BattleState = BattleState.STARTING

# ── Referencias a los componentes de Lógica ────────────────────────────────
@export var turn_queue: TurnQueue

# ── Señales para que la Interfaz Gráfica escuche ────────────
signal text_log_updated(message: String)
signal action_menu_toggled(show: bool)
signal battle_ended(victory: bool)

func _ready() -> void:
	if not turn_queue:
		push_error("BattleManager: No se ha asignado un TurnQueue.")
		return

# Función que llamaremos desde fuera para arrancar la pelea
func start_battle(heroes: Array[BaseEntity], enemies: Array[BaseEntity]) -> void:
	current_state = BattleState.STARTING
	_log("¡El combate comienza!")
	
	# Juntamos a todos y se los pasamos a la cola de turnos
	var all_combatants: Array[BaseEntity] = []
	all_combatants.append_array(heroes)
	all_combatants.append_array(enemies)
	
	turn_queue.setup_queue(all_combatants)
	
	# Damos 1 segundo de pausa para que se vea bien y pasamos al primer turno
	await get_tree().create_timer(1.0).timeout
	advance_to_next_turn()

func advance_to_next_turn() -> void:
	# 1. Comprobar si alguien ha ganado antes de dar el turno
	if _check_win_condition():
		return
		
	current_state = BattleState.NEXT_TURN
	
	# 2. Pedimos a la cola de turnos quién va ahora
	var active_entity = turn_queue.get_next_entity()
	_log("Es el turno de: " + active_entity.stats.character_name)
	
	await get_tree().create_timer(0.5).timeout
	
	# 3. Decidimos qué pasa según quién sea el atacante
	# (Usamos grupos de Godot para saber si es héroe o enemigo)
	if active_entity.is_in_group("Heroes"):
		current_state = BattleState.PLAYER_INPUT
		_log("Esperando tu orden...")
		action_menu_toggled.emit(true) # Avisamos a la UI para que muestre botones
	else:
		current_state = BattleState.ENEMY_TURN
		action_menu_toggled.emit(false) # Ocultamos botones
		_execute_enemy_ai(active_entity)

func _execute_enemy_ai(enemy: BaseEntity) -> void:
	_log("El enemigo " + enemy.stats.character_name + " está pensando...")
	await get_tree().create_timer(1.5).timeout
	
	_log(enemy.stats.character_name + " ataca ferozmente.")
	# AQUÍ IRÁ EL ACTION PROCESSOR PARA APLICAR EL DAÑO
	
	await get_tree().create_timer(1.0).timeout
	advance_to_next_turn()

func _check_win_condition() -> bool:
	# NOTA: En el futuro, aquí comprobaremos si todos los héroes o todos los enemigos tienen HP 0
	# De momento devolvemos false para que el bucle no pare
	return false

# Función auxiliar para enviar textos a la futura Interfaz Gráfica
func _log(message: String) -> void:
	print(message)
	text_log_updated.emit(message)
