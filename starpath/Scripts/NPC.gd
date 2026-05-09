## NPC.gd
## NPC estático con zona de interacción.
##
## Configura en el Inspector:
##   · speaker_name  → nombre que aparece en la caja de diálogo
##   · dialog_lines  → array de frases (una por "página")
##   · npc_texture   → sprite del NPC (Texture2D)
##
## El jugador pulsa Enter/Espacio cuando aparece el indicador "E"

extends Node2D
class_name NPC

@export var speaker_name : String        = "Aldeano"
@export var dialog_lines : Array[String] = ["Hola, viajero."]

## Si es true, abre la tienda en lugar del diálogo
@export var is_merchant  : bool          = false
## Nombre que aparece en la cabecera de la tienda
@export var shop_name    : String        = "Tienda"
## Items a la venta (se rellena automáticamente si está vacío)
@export var shop_catalog : Array[ItemData] = []

## Spritesheet del NPC (mismo formato Pipoya: 3 columnas × 4 filas, 32×32 px)
@export var npc_texture  : Texture2D

## Fila del spritesheet que se muestra en idle
## 0 = abajo  |  1 = izquierda  |  2 = derecha  |  3 = arriba
@export_range(0, 3) var sprite_row: int = 0

@onready var _sprite       : Sprite2D = $Sprite2D
@onready var _hint         : Label    = $InteractHint
@onready var _interact_area: Area2D   = $InteractArea

var _player   : PlayerController = null
var _in_range : bool             = false

func _ready() -> void:
	if npc_texture:
		var atlas    := AtlasTexture.new()
		atlas.atlas   = npc_texture
		atlas.region  = Rect2(32, sprite_row * 32, 32, 32)
		_sprite.texture = atlas

	if is_merchant and shop_catalog.is_empty():
		_fill_default_catalog()

	_hint.hide()
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)

func _fill_default_catalog() -> void:
	# ── Guerrero ────────────────────────────────────────────────────────────
	var sword             := ItemData.new()
	sword.item_name        = "Espada de Hierro"
	sword.item_type        = ItemData.ItemType.WEAPON
	sword.attack_bonus     = 15
	sword.price            = 50
	sword.shop_category    = "guerrero"
	shop_catalog.append(sword)

	var shield            := ItemData.new()
	shield.item_name       = "Escudo de Madera"
	shield.item_type       = ItemData.ItemType.ARMOR
	shield.defense_bonus   = 10
	shield.price           = 40
	shield.shop_category   = "guerrero"
	shop_catalog.append(shield)

	var armor             := ItemData.new()
	armor.item_name        = "Armadura de Cuero"
	armor.item_type        = ItemData.ItemType.ARMOR
	armor.defense_bonus    = 20
	armor.price            = 80
	armor.shop_category    = "guerrero"
	shop_catalog.append(armor)

	# ── Mago ────────────────────────────────────────────────────────────────
	var staff             := ItemData.new()
	staff.item_name        = "Bastón de Roble"
	staff.item_type        = ItemData.ItemType.WEAPON
	staff.attack_bonus     = 10
	staff.price            = 35
	staff.shop_category    = "mago"
	shop_catalog.append(staff)

	var robe              := ItemData.new()
	robe.item_name         = "Túnica de Aprendiz"
	robe.item_type         = ItemData.ItemType.ARMOR
	robe.defense_bonus     = 7
	robe.price             = 30
	robe.shop_category     = "mago"
	shop_catalog.append(robe)

	var arcane_staff      := ItemData.new()
	arcane_staff.item_name      = "Báculo Arcano"
	arcane_staff.item_type      = ItemData.ItemType.WEAPON
	arcane_staff.attack_bonus   = 22
	arcane_staff.price          = 95
	arcane_staff.shop_category  = "mago"
	shop_catalog.append(arcane_staff)

	# ── Objetos ─────────────────────────────────────────────────────────────
	var pocion            := ItemData.new()
	pocion.item_name       = "Poción"
	pocion.item_type       = ItemData.ItemType.CONSUMABLE
	pocion.effect_type     = "heal_hp"
	pocion.amount          = 50
	pocion.price           = 20
	pocion.shop_category   = "objeto"
	shop_catalog.append(pocion)

	var eter              := ItemData.new()
	eter.item_name         = "Éter"
	eter.item_type         = ItemData.ItemType.CONSUMABLE
	eter.effect_type       = "heal_mp"
	eter.amount            = 30
	eter.price             = 15
	eter.shop_category     = "objeto"
	shop_catalog.append(eter)

# ── Detección del jugador ─────────────────────────────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	if body is not PlayerController:
		return
	_player   = body as PlayerController
	_in_range = true
	_player.interaction_requested.connect(_on_interact)
	if not DialogManager.is_open:
		_hint.show()

func _on_body_exited(body: Node2D) -> void:
	if body is not PlayerController:
		return
	_in_range = false
	if _player and _player.interaction_requested.is_connected(_on_interact):
		_player.interaction_requested.disconnect(_on_interact)
	_player = null
	_hint.hide()

# ── Interacción ───────────────────────────────────────────────────────────────
func _on_interact() -> void:
	if not _in_range:
		return
	if is_merchant:
		if ShopManager.is_open:
			return
		_hint.hide()
		ShopManager.open_shop(shop_catalog, shop_name)
		ShopManager.shop_closed.connect(_on_closed, CONNECT_ONE_SHOT)
	else:
		if DialogManager.is_open:
			return
		_hint.hide()
		DialogManager.start_dialog(dialog_lines, speaker_name)
		DialogManager.dialog_finished.connect(_on_closed, CONNECT_ONE_SHOT)

func _on_closed() -> void:
	if _in_range:
		_hint.show()
