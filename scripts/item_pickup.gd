## ItemPickup – Area2D
## Represents a collectible item or ammo pack on the ground.
## Automatically collected when the player overlaps it.
extends Area2D

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
@export var item_id: String = "bandage"

@onready var label: Label = $Label
@onready var sprite: ColorRect = $ColorRect
@onready var bob_tween: Tween = null

# ---------------------------------------------------------------------------
# Item color map (visual indicator of item type)
# ---------------------------------------------------------------------------
const ITEM_COLORS: Dictionary = {
	"bandage": Color(1.0, 0.3, 0.3),
	"med_kit": Color(1.0, 0.1, 0.1),
	"junk_shield": Color(0.5, 0.5, 0.8),
	"toxic_resist": Color(0.2, 0.9, 0.2),
	"ammo_pack": Color(0.9, 0.8, 0.2),
	"sewer_map": Color(0.7, 0.5, 0.2),
	# Ammo types
	"standard_rounds": Color(0.8, 0.8, 0.6),
	"junk_shells": Color(0.7, 0.5, 0.3),
	"toxic_canisters": Color(0.3, 0.8, 0.3),
	"junk_grenades": Color(1.0, 0.5, 0.0),
	"mold_rounds": Color(0.4, 0.6, 0.3),
	# Weapons (dropped by enemies)
	"rust_blaster": Color(0.8, 0.5, 0.2),
	"sewer_shotgun": Color(0.6, 0.3, 0.1),
}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_update_visuals()
	body_entered.connect(_on_body_entered)
	_start_bob()

func set_item(id: String) -> void:
	item_id = id
	set_meta("item_id", id)
	if is_node_ready():
		_update_visuals()

func _update_visuals() -> void:
	set_meta("item_id", item_id)
	if sprite:
		sprite.color = ITEM_COLORS.get(item_id, Color(0.9, 0.9, 0.9))
	if label:
		var item_data := GameData.ITEMS.get(item_id, {})
		label.text = item_data.get("name", item_id.capitalize())

func _start_bob() -> void:
	if bob_tween:
		bob_tween.kill()
	bob_tween = create_tween()
	bob_tween.set_loops()
	bob_tween.tween_property(self, "position:y", position.y - 6.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	bob_tween.tween_property(self, "position:y", position.y, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ---------------------------------------------------------------------------
# Collection
# ---------------------------------------------------------------------------
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_collect(body)

func _collect(player: Node) -> void:
	# Check if it's a weapon pickup
	if GameData.WEAPONS.has(item_id):
		if not GameState.add_weapon(item_id):
			return  # No weapon slot available
	else:
		GameState.add_item(item_id)
	# Notify the player via its signal if it has the item_picked_up signal
	if player.has_signal("item_picked_up"):
		player.item_picked_up.emit(item_id)
	queue_free()
