## MainMenu – Control
## The game's main menu screen.
extends Control

@onready var new_game_btn: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var continue_btn: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	if continue_btn:
		continue_btn.disabled = not GameState.has_save()

func _on_new_game_pressed() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file(GameState.CITY_SCENE)

func _on_continue_pressed() -> void:
	if GameState.load_game():
		get_tree().change_scene_to_file(GameState.CITY_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
