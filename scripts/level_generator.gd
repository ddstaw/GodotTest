## LevelGenerator – Node
## Procedurally generates a side-scrolling platformer level.
## The level difficulty scales with the destination city's difficulty rating.
extends Node

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------
@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var enemies_container: Node2D = $Enemies
@onready var pickups_container: Node2D = $Pickups
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var exit_area: Area2D = $ExitArea

# ---------------------------------------------------------------------------
# Generation parameters
# ---------------------------------------------------------------------------
@export var level_width: int = 100          # tiles across
@export var tile_size: int = 32
@export var floor_y: int = 15               # tile row for the base floor
@export var min_platform_width: int = 3
@export var max_platform_width: int = 8
@export var platform_gap_min: int = 2
@export var platform_gap_max: int = 5

# Tile IDs within the TileSet (must match the TileSet resource)
const TILE_GROUND := Vector2i(0, 0)
const TILE_PLATFORM := Vector2i(1, 0)
const TILE_HAZARD := Vector2i(2, 0)

# Scene resources
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PICKUP_SCENE := preload("res://scenes/item_pickup.tscn")

# ---------------------------------------------------------------------------
# Generation entry point
# ---------------------------------------------------------------------------
func generate() -> void:
	var difficulty: int = _get_difficulty()
	_clear()
	_generate_floor()
	_generate_platforms(difficulty)
	_generate_hazards(difficulty)
	_place_enemies(difficulty)
	_place_pickups(difficulty)
	_place_exit()

func _get_difficulty() -> int:
	var dest := GameData.get_city_by_id(GameState.destination_city_id)
	return dest.get("level_difficulty", 1)

func _clear() -> void:
	tile_map.clear()
	for child in enemies_container.get_children():
		child.queue_free()
	for child in pickups_container.get_children():
		child.queue_free()

# ---------------------------------------------------------------------------
# Floor
# ---------------------------------------------------------------------------
func _generate_floor() -> void:
	for x in range(-2, level_width + 2):
		tile_map.set_cell(Vector2i(x, floor_y), 0, TILE_GROUND)
		# Underground fill
		for y in range(floor_y + 1, floor_y + 4):
			tile_map.set_cell(Vector2i(x, y), 0, TILE_GROUND)

# ---------------------------------------------------------------------------
# Platforms
# ---------------------------------------------------------------------------
func _generate_platforms(difficulty: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var x := 8
	while x < level_width - 6:
		var width: int = rng.randi_range(min_platform_width, max_platform_width)
		var height: int = rng.randi_range(floor_y - 7, floor_y - 3)
		for px in range(x, x + width):
			tile_map.set_cell(Vector2i(px, height), 0, TILE_PLATFORM)
		x += width + rng.randi_range(platform_gap_min, platform_gap_max + difficulty)

# ---------------------------------------------------------------------------
# Hazards (spikes, slime pools)
# ---------------------------------------------------------------------------
func _generate_hazards(difficulty: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var hazard_count := difficulty * 3 + rng.randi_range(2, 5)
	for _i in hazard_count:
		var x := rng.randi_range(6, level_width - 8)
		tile_map.set_cell(Vector2i(x, floor_y - 1), 0, TILE_HAZARD)

# ---------------------------------------------------------------------------
# Enemy placement
# ---------------------------------------------------------------------------
func _place_enemies(difficulty: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var enemy_types: Array[String] = ["sewer_rat"]
	if difficulty >= 2:
		enemy_types.append("toxic_slug")
	if difficulty >= 3:
		enemy_types.append("mold_monster")
	if difficulty >= 4:
		enemy_types.append("sewer_guard")

	var count := difficulty * 3 + rng.randi_range(2, 5)
	for _i in count:
		var x := rng.randi_range(8, level_width - 8)
		var type_id: String = enemy_types[rng.randi() % enemy_types.size()]
		var enemy: Node2D = ENEMY_SCENE.instantiate()
		enemies_container.add_child(enemy)
		enemy.type_id = type_id
		enemy.global_position = Vector2(x * tile_size, (floor_y - 1) * tile_size)

	# Place a boss (Rust Golem) at high difficulties
	if difficulty >= 3 and rng.randf() < 0.5:
		var boss: Node2D = ENEMY_SCENE.instantiate()
		enemies_container.add_child(boss)
		boss.type_id = "rust_golem"
		boss.global_position = Vector2((level_width - 15) * tile_size, (floor_y - 1) * tile_size)

# ---------------------------------------------------------------------------
# Pickup placement
# ---------------------------------------------------------------------------
func _place_pickups(difficulty: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pickup_types := ["bandage", "ammo_pack", "standard_rounds"]
	if difficulty >= 2:
		pickup_types.append("med_kit")
		pickup_types.append("toxic_resist")
	var count := rng.randi_range(3, 6 + difficulty)
	for _i in count:
		var x := rng.randi_range(6, level_width - 6)
		var item_id: String = pickup_types[rng.randi() % pickup_types.size()]
		var pickup: Node2D = PICKUP_SCENE.instantiate()
		pickups_container.add_child(pickup)
		pickup.global_position = Vector2(x * tile_size, (floor_y - 2) * tile_size)
		pickup.set_item(item_id)

# ---------------------------------------------------------------------------
# Exit (right edge)
# ---------------------------------------------------------------------------
func _place_exit() -> void:
	if exit_area:
		exit_area.global_position = Vector2((level_width - 2) * tile_size, (floor_y - 1) * tile_size)

# ---------------------------------------------------------------------------
# Background
# ---------------------------------------------------------------------------
func _ready() -> void:
	generate()
