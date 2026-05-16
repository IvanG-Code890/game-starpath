class_name Enemy
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is PlayerController:
		Inventory.pre_battle_position  = body.global_position
		Inventory.pre_battle_direction = body._last_dir
		Inventory.returning_from_battle = true
		SceneTransition.go_to("res://Scenes/Battle/BattleScene.tscn")
