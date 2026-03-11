## PlatformerLevel – Node2D
## Root script for the side-scrolling travel level.
## Manages win/lose conditions and HUD messaging.
extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var player: CharacterBody2D = $Player
@onready var level_generator: Node = $LevelGenerator
@onready var death_screen: CanvasLayer = $DeathScreen
@onready var level_complete_screen: CanvasLayer = $LevelCompleteScreen
@onready var camera: Camera2D = $Player/Camera2D

var _level_complete: bool = false

func _ready() -> void:
	player.died.connect(_on_player_died)
	player.reached_exit.connect(_on_level_complete)
	GameState.game_over.connect(_on_player_died)

	if death_screen:
		death_screen.visible = false
	if level_complete_screen:
		level_complete_screen.visible = false

	var dest_city := GameData.get_city_by_id(GameState.destination_city_id)
	if hud and hud.has_method("show_message"):
		var dest_name: String = dest_city.get("name", "???")
		hud.show_message("Heading to %s..." % dest_name, 3.0)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not _level_complete:
		_toggle_pause()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused

func _on_player_died() -> void:
	if _level_complete:
		return
	await get_tree().create_timer(1.0).timeout
	if death_screen:
		death_screen.visible = true

func _on_level_complete() -> void:
	if _level_complete:
		return
	_level_complete = true
	GameState.levels_completed += 1
	if level_complete_screen:
		level_complete_screen.visible = true
	await get_tree().create_timer(2.0).timeout
	GameState.arrive_at_city(GameState.destination_city_id)

# Called by the "Retry" button on the death screen
func _on_retry_pressed() -> void:
	GameState.heal(GameState.player_max_health)
	get_tree().reload_current_scene()

# Called by the "Main Menu" button on the death screen
func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file(GameState.MAIN_MENU_SCENE)
