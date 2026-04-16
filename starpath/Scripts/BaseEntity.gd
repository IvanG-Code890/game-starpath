class_name BaseEntity
extends Node

signal stats_changed
signal defeated

@export var stats: CharacterStats

var current_hp: int
var current_mp: int
var is_alive: bool = true

func _ready():
	if stats:
		current_hp = stats.max_hp
		current_mp = stats.max_mp

func take_damage(amount: int):
	var effective_damage = max(1, amount - (stats.defense / 2))
	current_hp = max(0, current_hp - effective_damage)
	stats_changed.emit()
	
	if current_hp <= 0:
		is_alive = false
		defeated.emit()
