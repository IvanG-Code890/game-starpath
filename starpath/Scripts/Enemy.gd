class_name Enemy
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is PlayerController:
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/BattleScene.tscn")
