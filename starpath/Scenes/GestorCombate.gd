extends Node

var jugador: Personaje
var enemigo: Personaje

# Variable para controlar de quién es el turno
var turno_del_jugador: bool = true

func _ready():
	print("--- INICIANDO SIMULADOR DE COMBATE ---")
	
	# Instanciamos a los combatientes
	jugador = Personaje.new("Ivan Gastineau Laine", 100, 25)
	enemigo = Personaje.new("Limo Corrupto", 60, 15)
	
	print("Aparece un " + enemigo.nombre + " salvaje.")
	print("Turno de: " + jugador.nombre)
	print("Pulsa 'Espacio' para atacar.")

func _process(_delta):
	# Simulamos el botón de ataque con la barra espaciadora
	if Input.is_action_just_pressed("ui_accept"): 
		procesar_turno()

func procesar_turno():
	if turno_del_jugador:
		# Ataca el jugador
		print("\n¡" + jugador.nombre + " ataca!")
		enemigo.recibir_dano(jugador.ataque)
		
		if verificar_victoria(): return
		
		# Cambiamos de turno
		turno_del_jugador = false
		print("\nTurno de: " + enemigo.nombre)
		
		# Simulamos que el enemigo ataca automáticamente después de 1 segundo
		await get_tree().create_timer(1.0).timeout
		procesar_turno() 
		
	else:
		# Ataca el enemigo
		print("\n¡" + enemigo.nombre + " contraataca!")
		jugador.recibir_dano(enemigo.ataque)
		
		if verificar_victoria(): return
		
		# Vuelve el turno al jugador
		turno_del_jugador = true
		print("\nTurno de: " + jugador.nombre + ". Pulsa 'Espacio'.")

func verificar_victoria() -> bool:
	if not enemigo.esta_vivo():
		print("\n¡VICTORIA! El enemigo ha sido derrotado.")
		set_process(false) # Detenemos el input
		return true
	elif not jugador.esta_vivo():
		print("\nDERROTA... Has caído en combate.")
		set_process(false)
		return true
	return false
