class_name TurnQueue
extends Node

var queue: Array[BaseEntity] = []
var active_index: int = 0

func setup_queue(entities: Array[BaseEntity]):
	queue = entities
	# Ordenación por velocidad (Mayor a menor)
	queue.sort_custom(func(a, b): return a.stats.speed > b.stats.speed)
	active_index = 0

func get_next_entity() -> BaseEntity:
	var entity = queue[active_index]
	active_index = (active_index + 1) % queue.size()
	
	if not entity.is_alive:
		return get_next_entity()
	return entity
