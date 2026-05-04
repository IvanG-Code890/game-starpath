extends Node2D

@onready var player:      PlayerController = $Player
@onready var battle_zones: Node2D          = $BattleZones
@onready var pause_menu:  PauseMenu        = $PauseMenu

func _ready() -> void:
	player.menu_requested.connect(pause_menu.toggle)
	for zone in battle_zones.get_children():
		if zone is Area2D:
			zone.body_entered.connect(_on_battle_zone_entered)

func _on_battle_zone_entered(body: Node2D) -> void:
	if body is PlayerController:
		get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")
