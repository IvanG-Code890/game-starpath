class_name ItemData
extends Resource

@export var item_name: String = "Poción"
@export var effect_type: String = "heal_hp"  # "heal_hp" | "heal_mp"
@export var amount: int = 50
@export var quantity: int = 3
@export var targets_enemy: bool = false  # false = aliados, true = enemigos
