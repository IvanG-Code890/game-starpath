class_name Personaje

var nombre: String
var hp_actual: int
var ataque: int

# Constructor de la clase
func _init(nombre_personaje: String, vida: int, poder_ataque: int):
	nombre = nombre_personaje
	hp_actual = vida
	ataque = poder_ataque

# Función que calcula y aplica el daño
func get_damage(cantidad: int):
	hp_actual -= cantidad
	if hp_actual < 0:
		hp_actual = 0
	print(">>> " + nombre + " recibe " + str(cantidad) + " de daño. (HP: " + str(hp_actual) + ")")

# Comprueba si el personaje ha caído
func is_alive() -> bool:
	return hp_actual > 0
