class_name CharacterStats
extends Resource

enum ClassType { GUERRERO, MAGO, PICARO, SANADOR, PALADIN, ARQUERO }

@export var character_name: String = "Héroe"
@export var character_class: ClassType = ClassType.GUERRERO
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var attack: int = 20
@export var defense: int = 10
@export var speed: int = 15
@export var skills: Array[SkillData] = []
