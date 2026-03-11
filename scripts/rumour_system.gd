## RumourSystem – generates and manages rumours heard at the inn.
class_name RumourSystem
extends RefCounted

## Generate a fresh batch of rumours for the current city.
static func get_rumours(count: int = 3) -> Array[String]:
	return GameState.generate_rumours(count)

## Apply a rumour's effect to the game state (price hints, etc.).
## Currently rumours are purely informational, but this hook
## allows future implementation of rumour-triggered market events.
static func apply_rumour_effect(_rumour: String) -> void:
	pass
