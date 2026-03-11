## HUD – CanvasLayer
## In-platformer-level heads-up display.
## Shows health bar, armor, gold, active weapon info, ammo counter, and day.
extends CanvasLayer

@onready var health_bar: ProgressBar = $Panel/VBoxContainer/HealthRow/HealthBar
@onready var health_label: Label = $Panel/VBoxContainer/HealthRow/HealthLabel
@onready var armor_label: Label = $Panel/VBoxContainer/ArmorLabel
@onready var gold_label: Label = $Panel/VBoxContainer/GoldLabel
@onready var weapon_label: Label = $Panel/VBoxContainer/WeaponRow/WeaponLabel
@onready var ammo_label: Label = $Panel/VBoxContainer/WeaponRow/AmmoLabel
@onready var day_label: Label = $Panel/VBoxContainer/DayLabel
@onready var message_label: Label = $MessageLabel
@onready var message_timer: Timer = $MessageTimer

func _ready() -> void:
	GameState.health_changed.connect(_on_health_changed)
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.weapons_changed.connect(_on_weapons_changed)
	GameState.day_changed.connect(_on_day_changed)
	_refresh_all()

func _refresh_all() -> void:
	_on_health_changed(GameState.player_health, GameState.player_max_health)
	_on_gold_changed(GameState.gold)
	_on_weapons_changed(GameState.weapons)
	_on_day_changed(GameState.day)

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_health_changed(hp: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
	if health_label:
		health_label.text = "%d / %d" % [hp, max_hp]
	if armor_label:
		armor_label.text = "Armor: %d" % GameState.player_armor

func _on_gold_changed(new_gold: int) -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % new_gold

func _on_weapons_changed(weapons: Array) -> void:
	if weapons.is_empty():
		if weapon_label:
			weapon_label.text = "No Weapon"
		if ammo_label:
			ammo_label.text = ""
		return
	var entry: Dictionary = weapons[GameState.active_weapon_index]
	var weapon_data := GameData.WEAPONS.get(entry["id"], {})
	if weapon_label:
		weapon_label.text = weapon_data.get("name", entry["id"])
	if ammo_label:
		ammo_label.text = "%d / %d" % [entry["ammo"], weapon_data.get("magazine_size", 0)]

func _on_day_changed(new_day: int) -> void:
	if day_label:
		day_label.text = "Day %d" % new_day

# ---------------------------------------------------------------------------
# Temporary message display
# ---------------------------------------------------------------------------
func show_message(text: String, duration: float = 2.5) -> void:
	if message_label:
		message_label.text = text
		message_label.visible = true
	message_timer.start(duration)

func _on_message_timer_timeout() -> void:
	if message_label:
		message_label.visible = false
