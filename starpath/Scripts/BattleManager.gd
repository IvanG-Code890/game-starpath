class_name BattleManager
extends Node

# ── Máquina de Estados ─────────────────────────────────────────────────────
enum BattleState { STARTING, NEXT_TURN, PLAYER_INPUT, ENEMY_TURN, WON, LOST }
var current_state: BattleState = BattleState.STARTING

# ── Referencias a los componentes de Lógica ────────────────────────────────
@export var turn_queue: TurnQueue

# ── Señales para que la Interfaz Gráfica escuche ───────────────────────────
signal text_log_updated(message: String)
signal action_menu_toggled(show: bool)
signal battle_ended(player_won: bool)

func _ready() -> void:
	if not turn_queue:
		push_error("BattleManager: No se ha asignado un TurnQueue.")
		return

# ── BUCLE PRINCIPAL DEL COMBATE ────────────────────────────────────────────

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
	if _check_battle_end():
		return
		
	current_state = BattleState.NEXT_TURN
	
	# 2. Pedimos a la cola de turnos quién va ahora
	var active_entity = turn_queue.get_next_entity()
	_log("Es el turno de: " + active_entity.stats.character_name)
	
	await get_tree().create_timer(0.5).timeout
	
	# 3. Decidimos qué pasa según quién sea el atacante
	if active_entity.get_parent().is_in_group("Heroes"):
		current_state = BattleState.PLAYER_INPUT
		_log("Esperando tu orden...")
		action_menu_toggled.emit(true) # Avisamos a la UI para mostrar botones
	else:
		current_state = BattleState.ENEMY_TURN
		action_menu_toggled.emit(false) # Ocultamos botones
		_execute_enemy_ai(active_entity)

func _execute_enemy_ai(enemy: BaseEntity) -> void:
	_log("El enemigo " + enemy.stats.character_name + " está pensando...")
	await get_tree().create_timer(1.0).timeout
	
	_log(enemy.stats.character_name + " ataca ferozmente.")
	await get_tree().create_timer(0.5).timeout
	
	# 1. El enemigo busca al héroe
	var target = _get_first_hero()
	
	# 2. Le aplica daño
	if target:
		var damage_dealt = enemy.stats.attack
		target.take_damage(damage_dealt)
		_log("¡Ay! " + target.stats.character_name + " recibe daño.")
	
	await get_tree().create_timer(1.0).timeout
	advance_to_next_turn()

func player_action_selected(action_name: String) -> void:
	if current_state != BattleState.PLAYER_INPUT:
		return
		
	action_menu_toggled.emit(false)
	
	# 1. Identificamos quién ataca y quién recibe
	var attacker = turn_queue.queue[turn_queue.active_index - 1]
	var defender = _get_first_enemy()
	
	_log(attacker.stats.character_name + " usa " + action_name + "!")
	await get_tree().create_timer(1.0).timeout
	
	# 2. El ataque del héroe se lo pasamos a la función de recibir daño del limo
	if defender:
		var damage_dealt = attacker.stats.attack
		defender.take_damage(damage_dealt)
		_log("¡PUM! " + defender.stats.character_name + " recibe daño.")
	
	await get_tree().create_timer(1.0).timeout
	advance_to_next_turn()

# ── COMPROBACIÓN DE VICTORIA/DERROTA ───────────────────────────────────────

func _check_battle_end() -> bool:
	var heroes_alive = false
	var enemies_alive = false
	
	for entity in turn_queue.queue:
		if entity.is_alive:
			if entity.get_parent().is_in_group("Heroes"):
				heroes_alive = true
			elif entity.get_parent().is_in_group("Enemies"):
				enemies_alive = true
				
	if not heroes_alive:
		_log("¡Derrota! Todos los héroes han caído.")
		current_state = BattleState.LOST
		battle_ended.emit(false) # false = el jugador no ganó
		return true
	elif not enemies_alive:
		_log("¡Victoria! Los enemigos han sido derrotados.")
		current_state = BattleState.WON
		battle_ended.emit(true) # true = el jugador ganó
		return true
		
	return false # Si ambos equipos tienen vivos, el combate sigue

# ── FUNCIONES AUXILIARES (HELPERS) ─────────────────────────────────────────

func _log(message: String) -> void:
	print(message)
	text_log_updated.emit(message)
	
func _get_first_enemy() -> BaseEntity:
	for entity in turn_queue.queue:
		if entity.get_parent().is_in_group("Enemies") and entity.is_alive:
			return entity
	return null

func _get_first_hero() -> BaseEntity:
	for entity in turn_queue.queue:
		if entity.get_parent().is_in_group("Heroes") and entity.is_alive:
			return entity
	return null
