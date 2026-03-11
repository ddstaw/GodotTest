## GameState – Autoload singleton
## Tracks all dynamic game state: player stats, inventory, city, progress.
## Provides save/load functionality and scene transition helpers.
extends Node

signal health_changed(new_health: int, max_health: int)
signal gold_changed(new_gold: int)
signal cargo_changed(cargo: Dictionary, capacity: int)
signal weapons_changed(weapons: Array)
signal day_changed(new_day: int)
signal city_changed(new_city_id: String)
signal game_over()

# ---------------------------------------------------------------------------
# Scene paths
# ---------------------------------------------------------------------------
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const CITY_SCENE := "res://scenes/city.tscn"
const PLATFORMER_SCENE := "res://scenes/platformer_level.tscn"

# ---------------------------------------------------------------------------
# Player base stats
# ---------------------------------------------------------------------------
var player_health: int = 100
var player_max_health: int = 100
var player_armor: int = 0

var gold: int = 500

var current_city_id: String = "sludge_harbor"
var destination_city_id: String = ""

var day: int = 1

var cargo: Dictionary = {}
var cargo_capacity: int = 50

# weapons: Array of { "id": String, "ammo": int }
var weapons: Array = [{"id": "rust_blaster", "ammo": 12}]
var active_weapon_index: int = 0
var max_weapon_slots: int = 2

# consumable items in inventory: { item_id: quantity }
var inventory_items: Dictionary = {}

# upgrade levels: { upgrade_id: level }
var upgrades: Dictionary = {}

# known rumours heard this playthrough
var rumours_heard: Array[String] = []

# price modifiers per city per commodity (set by market events)
var price_modifiers: Dictionary = {}

# statistics
var total_profit: int = 0
var enemies_killed: int = 0
var levels_completed: int = 0
var days_played: int = 0

# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Ensure cargo is empty at start
	cargo.clear()

# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------
func damage(amount: int) -> void:
	var absorbed := mini(player_armor, amount)
	player_armor = max(0, player_armor - absorbed)
	var real_damage := amount - absorbed
	player_health = max(0, player_health - real_damage)
	health_changed.emit(player_health, player_max_health)
	if player_health <= 0:
		game_over.emit()

func heal(amount: int) -> void:
	player_health = mini(player_health + amount, player_max_health)
	health_changed.emit(player_health, player_max_health)

func add_armor(amount: int) -> void:
	player_armor += amount

func is_alive() -> bool:
	return player_health > 0

# ---------------------------------------------------------------------------
# Gold
# ---------------------------------------------------------------------------
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

# ---------------------------------------------------------------------------
# Cargo (trade goods)
# ---------------------------------------------------------------------------
func get_cargo_used() -> int:
	var total := 0
	for commodity_id in cargo:
		var weight: int = GameData.COMMODITIES.get(commodity_id, {}).get("weight", 1)
		total += cargo[commodity_id] * weight
	return total

func get_cargo_free() -> int:
	return cargo_capacity - get_cargo_used()

func add_cargo(commodity_id: String, quantity: int) -> bool:
	var weight: int = GameData.COMMODITIES.get(commodity_id, {}).get("weight", 1)
	if get_cargo_free() < quantity * weight:
		return false
	cargo[commodity_id] = cargo.get(commodity_id, 0) + quantity
	cargo_changed.emit(cargo, cargo_capacity)
	return true

func remove_cargo(commodity_id: String, quantity: int) -> bool:
	if cargo.get(commodity_id, 0) < quantity:
		return false
	cargo[commodity_id] -= quantity
	if cargo[commodity_id] <= 0:
		cargo.erase(commodity_id)
	cargo_changed.emit(cargo, cargo_capacity)
	return true

# ---------------------------------------------------------------------------
# Weapons
# ---------------------------------------------------------------------------
func get_active_weapon() -> Dictionary:
	if weapons.is_empty():
		return {}
	return weapons[active_weapon_index]

func switch_weapon(index: int) -> void:
	if index >= 0 and index < weapons.size():
		active_weapon_index = index
		weapons_changed.emit(weapons)

func next_weapon() -> void:
	if weapons.is_empty():
		return
	active_weapon_index = (active_weapon_index + 1) % weapons.size()
	weapons_changed.emit(weapons)

func prev_weapon() -> void:
	if weapons.is_empty():
		return
	active_weapon_index = (active_weapon_index - 1 + weapons.size()) % weapons.size()
	weapons_changed.emit(weapons)

func add_weapon(weapon_id: String) -> bool:
	if weapons.size() >= max_weapon_slots:
		return false
	var weapon_data: Dictionary = GameData.WEAPONS.get(weapon_id, {})
	weapons.append({"id": weapon_id, "ammo": weapon_data.get("magazine_size", 0)})
	weapons_changed.emit(weapons)
	return true

func drop_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	weapons.remove_at(index)
	active_weapon_index = clampi(active_weapon_index, 0, max(0, weapons.size() - 1))
	weapons_changed.emit(weapons)

func use_ammo(weapon_index: int) -> bool:
	if weapon_index < 0 or weapon_index >= weapons.size():
		return false
	if weapons[weapon_index]["ammo"] <= 0:
		return false
	weapons[weapon_index]["ammo"] -= 1
	weapons_changed.emit(weapons)
	return true

func reload_weapon(weapon_index: int) -> void:
	if weapon_index < 0 or weapon_index >= weapons.size():
		return
	var weapon_id: String = weapons[weapon_index]["id"]
	var weapon_data: Dictionary = GameData.WEAPONS.get(weapon_id, {})
	weapons[weapon_index]["ammo"] = weapon_data.get("magazine_size", 0)
	weapons_changed.emit(weapons)

# ---------------------------------------------------------------------------
# Inventory items (consumables)
# ---------------------------------------------------------------------------
func add_item(item_id: String, quantity: int = 1) -> void:
	inventory_items[item_id] = inventory_items.get(item_id, 0) + quantity

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if inventory_items.get(item_id, 0) < quantity:
		return false
	inventory_items[item_id] -= quantity
	if inventory_items[item_id] <= 0:
		inventory_items.erase(item_id)
	return true

func use_item(item_id: String) -> bool:
	var item_data: Dictionary = GameData.ITEMS.get(item_id, {})
	if item_data.is_empty():
		return false
	if not remove_item(item_id):
		return false
	match item_data.get("type", ""):
		"consumable":
			if item_data.has("heal_amount"):
				heal(item_data["heal_amount"])
			if item_data.has("armor_amount"):
				add_armor(item_data["armor_amount"])
	return true

# ---------------------------------------------------------------------------
# Upgrades
# ---------------------------------------------------------------------------
func get_upgrade_level(upgrade_id: String) -> int:
	return upgrades.get(upgrade_id, 0)

func apply_upgrade(upgrade_id: String) -> bool:
	var upgrade_data: Dictionary = GameData.UPGRADES.get(upgrade_id, {})
	if upgrade_data.is_empty():
		return false
	var current_level := get_upgrade_level(upgrade_id)
	var max_level: int = upgrade_data["levels"].size()
	if current_level >= max_level:
		return false
	var price: int = upgrade_data["prices"][current_level]
	if not spend_gold(price):
		return false
	upgrades[upgrade_id] = current_level + 1
	var effect: String = upgrade_data["effect"]
	var effect_value: int = upgrade_data["effect_values"][current_level]
	match effect:
		"cargo_capacity":
			cargo_capacity += effect_value
			cargo_changed.emit(cargo, cargo_capacity)
		"max_health":
			player_max_health += effect_value
			player_health = mini(player_health + effect_value, player_max_health)
			health_changed.emit(player_health, player_max_health)
		"weapon_slots":
			max_weapon_slots = mini(max_weapon_slots + effect_value, 4)
			weapons_changed.emit(weapons)
		"jump_force", "speed":
			pass  # Applied by the player node when it reads GameState
	return true

# ---------------------------------------------------------------------------
# City & travel
# ---------------------------------------------------------------------------
func travel_to(city_id: String) -> void:
	destination_city_id = city_id
	# Load the platformer level; on completion it will call arrive_at_city()
	get_tree().change_scene_to_file(PLATFORMER_SCENE)

func arrive_at_city(city_id: String) -> void:
	current_city_id = city_id
	day += 1
	days_played += 1
	day_changed.emit(day)
	city_changed.emit(current_city_id)
	# Refresh market prices on arrival
	_refresh_prices(city_id)
	get_tree().change_scene_to_file(CITY_SCENE)

func _refresh_prices(city_id: String) -> void:
	if not price_modifiers.has(city_id):
		price_modifiers[city_id] = {}
	for commodity_id in GameData.COMMODITIES:
		var mod := randf_range(0.8, 1.3)
		price_modifiers[city_id][commodity_id] = mod

func get_price(commodity_id: String, city_id: String = current_city_id) -> int:
	var mod: float = 1.0
	if price_modifiers.has(city_id) and price_modifiers[city_id].has(commodity_id):
		mod = price_modifiers[city_id][commodity_id]
	return GameData.get_commodity_price(commodity_id, city_id, mod)

# ---------------------------------------------------------------------------
# Rumours
# ---------------------------------------------------------------------------
func generate_rumours(count: int = 3) -> Array[String]:
	var result: Array[String] = []
	for i in count:
		result.append(GameData.get_random_rumour(current_city_id))
	rumours_heard.append_array(result)
	return result

# ---------------------------------------------------------------------------
# Save / Load  (basic Dictionary-based persistence via ConfigFile)
# ---------------------------------------------------------------------------
const SAVE_PATH := "user://savegame.cfg"

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "health", player_health)
	cfg.set_value("player", "max_health", player_max_health)
	cfg.set_value("player", "armor", player_armor)
	cfg.set_value("player", "gold", gold)
	cfg.set_value("player", "cargo_capacity", cargo_capacity)
	cfg.set_value("player", "max_weapon_slots", max_weapon_slots)
	cfg.set_value("world", "current_city_id", current_city_id)
	cfg.set_value("world", "day", day)
	cfg.set_value("inventory", "cargo", cargo)
	cfg.set_value("inventory", "weapons", weapons)
	cfg.set_value("inventory", "items", inventory_items)
	cfg.set_value("upgrades", "data", upgrades)
	cfg.set_value("stats", "total_profit", total_profit)
	cfg.set_value("stats", "enemies_killed", enemies_killed)
	cfg.set_value("stats", "levels_completed", levels_completed)
	cfg.save(SAVE_PATH)

func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	player_health = cfg.get_value("player", "health", 100)
	player_max_health = cfg.get_value("player", "max_health", 100)
	player_armor = cfg.get_value("player", "armor", 0)
	gold = cfg.get_value("player", "gold", 500)
	cargo_capacity = cfg.get_value("player", "cargo_capacity", 50)
	max_weapon_slots = cfg.get_value("player", "max_weapon_slots", 2)
	current_city_id = cfg.get_value("world", "current_city_id", "sludge_harbor")
	day = cfg.get_value("world", "day", 1)
	cargo = cfg.get_value("inventory", "cargo", {})
	weapons = cfg.get_value("inventory", "weapons", [{"id": "rust_blaster", "ammo": 12}])
	inventory_items = cfg.get_value("inventory", "items", {})
	upgrades = cfg.get_value("upgrades", "data", {})
	total_profit = cfg.get_value("stats", "total_profit", 0)
	enemies_killed = cfg.get_value("stats", "enemies_killed", 0)
	levels_completed = cfg.get_value("stats", "levels_completed", 0)
	_refresh_prices(current_city_id)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func new_game() -> void:
	player_health = 100
	player_max_health = 100
	player_armor = 0
	gold = 500
	current_city_id = "sludge_harbor"
	destination_city_id = ""
	day = 1
	cargo = {}
	cargo_capacity = 50
	weapons = [{"id": "rust_blaster", "ammo": 12}]
	active_weapon_index = 0
	max_weapon_slots = 2
	inventory_items = {}
	upgrades = {}
	rumours_heard = []
	price_modifiers = {}
	total_profit = 0
	enemies_killed = 0
	levels_completed = 0
	days_played = 0
	_refresh_prices(current_city_id)
