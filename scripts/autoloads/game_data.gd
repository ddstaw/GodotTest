## GameData – Autoload singleton
## Holds all static, read-only definitions for the game:
## cities, commodities, weapons, enemies, items, and rumour templates.
extends Node

# ---------------------------------------------------------------------------
# City definitions
# ---------------------------------------------------------------------------
const CITIES: Array[Dictionary] = [
	{
		"id": "sludge_harbor",
		"name": "Sludge Harbor",
		"description": "A grimy port where barges of refuse drift in on the tide.",
		"base_prices": {"scrap_metal": 12, "rat_pelts": 8, "toxic_sludge": 4, "mold_spores": 6, "rusted_components": 15, "contaminated_water": 2, "fungus_brew": 9, "old_batteries": 20},
		"special_goods": ["rat_pelts", "contaminated_water"],
		"level_difficulty": 1,
	},
	{
		"id": "mucktown",
		"name": "Mucktown",
		"description": "Built on centuries of accumulated filth. Locals are proud of it.",
		"base_prices": {"scrap_metal": 10, "rat_pelts": 11, "toxic_sludge": 7, "mold_spores": 5, "rusted_components": 12, "contaminated_water": 3, "fungus_brew": 14, "old_batteries": 18},
		"special_goods": ["mold_spores", "fungus_brew"],
		"level_difficulty": 1,
	},
	{
		"id": "drainpipe_alley",
		"name": "Drainpipe Alley",
		"description": "A labyrinthine city of interconnected pipes. Easy to get lost forever.",
		"base_prices": {"scrap_metal": 14, "rat_pelts": 9, "toxic_sludge": 5, "mold_spores": 8, "rusted_components": 10, "contaminated_water": 4, "fungus_brew": 11, "old_batteries": 22},
		"special_goods": ["rusted_components", "old_batteries"],
		"level_difficulty": 2,
	},
	{
		"id": "cesspool_junction",
		"name": "Cesspool Junction",
		"description": "Where four main sewer lines converge, so does all manner of trade.",
		"base_prices": {"scrap_metal": 11, "rat_pelts": 13, "toxic_sludge": 9, "mold_spores": 7, "rusted_components": 16, "contaminated_water": 5, "fungus_brew": 8, "old_batteries": 17},
		"special_goods": ["toxic_sludge", "scrap_metal"],
		"level_difficulty": 2,
	},
	{
		"id": "gutter_city",
		"name": "Gutter City",
		"description": "The jewel of the sewer underworld, if jewels were made of rust.",
		"base_prices": {"scrap_metal": 9, "rat_pelts": 10, "toxic_sludge": 6, "mold_spores": 9, "rusted_components": 13, "contaminated_water": 6, "fungus_brew": 16, "old_batteries": 25},
		"special_goods": ["old_batteries", "rusted_components"],
		"level_difficulty": 3,
	},
	{
		"id": "scumburg",
		"name": "Scumburg",
		"description": "Don't let the name fool you. Actually, let it fool you exactly the right amount.",
		"base_prices": {"scrap_metal": 16, "rat_pelts": 7, "toxic_sludge": 10, "mold_spores": 4, "rusted_components": 14, "contaminated_water": 3, "fungus_brew": 12, "old_batteries": 19},
		"special_goods": ["scrap_metal", "toxic_sludge"],
		"level_difficulty": 3,
	},
	{
		"id": "filth_hollow",
		"name": "Filth Hollow",
		"description": "Carved into the bedrock below the city sewers. Very exclusive.",
		"base_prices": {"scrap_metal": 13, "rat_pelts": 15, "toxic_sludge": 8, "mold_spores": 11, "rusted_components": 11, "contaminated_water": 7, "fungus_brew": 10, "old_batteries": 23},
		"special_goods": ["rat_pelts", "mold_spores"],
		"level_difficulty": 4,
	},
	{
		"id": "rotgut_row",
		"name": "Rotgut Row",
		"description": "Famous for its fermented fungi spirits and suspiciously cheap medical care.",
		"base_prices": {"scrap_metal": 10, "rat_pelts": 12, "toxic_sludge": 11, "mold_spores": 13, "rusted_components": 9, "contaminated_water": 8, "fungus_brew": 6, "old_batteries": 21},
		"special_goods": ["fungus_brew", "mold_spores"],
		"level_difficulty": 4,
	},
]

# ---------------------------------------------------------------------------
# Commodity definitions
# ---------------------------------------------------------------------------
const COMMODITIES: Dictionary = {
	"scrap_metal": {
		"name": "Scrap Metal",
		"description": "Twisted hunks of salvaged metal. Always in demand.",
		"base_price": 12,
		"weight": 2,
		"icon": "scrap_metal",
	},
	"rat_pelts": {
		"name": "Rat Pelts",
		"description": "Surprisingly soft. Fashionable in certain circles.",
		"base_price": 9,
		"weight": 1,
		"icon": "rat_pelts",
	},
	"toxic_sludge": {
		"name": "Toxic Sludge",
		"description": "Dangerous to handle but essential for several industries.",
		"base_price": 6,
		"weight": 3,
		"icon": "toxic_sludge",
	},
	"mold_spores": {
		"name": "Mold Spores",
		"description": "Cultivated mold used in medicine, food, and mild warfare.",
		"base_price": 7,
		"weight": 1,
		"icon": "mold_spores",
	},
	"rusted_components": {
		"name": "Rusted Components",
		"description": "Old machine parts. Still function if you bang them hard enough.",
		"base_price": 13,
		"weight": 2,
		"icon": "rusted_components",
	},
	"contaminated_water": {
		"name": "Contaminated Water",
		"description": "Mostly water. Mostly.",
		"base_price": 4,
		"weight": 4,
		"icon": "contaminated_water",
	},
	"fungus_brew": {
		"name": "Fungus Brew",
		"description": "A potent beverage brewed from sewer mushrooms. Popular at parties.",
		"base_price": 10,
		"weight": 2,
		"icon": "fungus_brew",
	},
	"old_batteries": {
		"name": "Old Batteries",
		"description": "Corroded power cells that still hold a trickle of charge.",
		"base_price": 20,
		"weight": 1,
		"icon": "old_batteries",
	},
}

# ---------------------------------------------------------------------------
# Weapon definitions
# ---------------------------------------------------------------------------
const WEAPONS: Dictionary = {
	"rust_blaster": {
		"name": "Rust Blaster",
		"description": "A semi-automatic pistol cobbled from corroded pipe fittings.",
		"damage": 15,
		"fire_rate": 0.4,
		"magazine_size": 12,
		"reload_time": 1.2,
		"bullet_speed": 600.0,
		"bullet_count": 1,
		"spread": 0.05,
		"buy_price": 50,
		"sell_price": 30,
		"ammo_type": "standard_rounds",
		"color": Color(0.8, 0.5, 0.2),
	},
	"sewer_shotgun": {
		"name": "Sewer Shotgun",
		"description": "Fires a wide spray of junk fragments. Devastating at close range.",
		"damage": 12,
		"fire_rate": 0.9,
		"magazine_size": 6,
		"reload_time": 2.0,
		"bullet_speed": 500.0,
		"bullet_count": 6,
		"spread": 0.35,
		"buy_price": 120,
		"sell_price": 70,
		"ammo_type": "junk_shells",
		"color": Color(0.6, 0.3, 0.1),
	},
	"toxic_sprayer": {
		"name": "Toxic Sprayer",
		"description": "Unleashes a pressurised jet of toxic sludge. Causes lingering damage.",
		"damage": 8,
		"fire_rate": 0.1,
		"magazine_size": 30,
		"reload_time": 1.8,
		"bullet_speed": 400.0,
		"bullet_count": 1,
		"spread": 0.15,
		"buy_price": 150,
		"sell_price": 90,
		"ammo_type": "toxic_canisters",
		"color": Color(0.2, 0.8, 0.2),
		"status_effect": "poison",
	},
	"junk_launcher": {
		"name": "Junk Launcher",
		"description": "Lobs explosive balls of compressed garbage. Handle with care.",
		"damage": 50,
		"fire_rate": 1.5,
		"magazine_size": 4,
		"reload_time": 2.5,
		"bullet_speed": 350.0,
		"bullet_count": 1,
		"spread": 0.0,
		"buy_price": 200,
		"sell_price": 120,
		"ammo_type": "junk_grenades",
		"color": Color(1.0, 0.6, 0.0),
		"explosive": true,
		"explosion_radius": 80.0,
	},
	"mold_cannon": {
		"name": "Mold Cannon",
		"description": "A heavy weapon that fires dense mold clusters. Slow but powerful.",
		"damage": 40,
		"fire_rate": 1.2,
		"magazine_size": 8,
		"reload_time": 3.0,
		"bullet_speed": 450.0,
		"bullet_count": 1,
		"spread": 0.02,
		"buy_price": 180,
		"sell_price": 100,
		"ammo_type": "mold_rounds",
		"color": Color(0.4, 0.6, 0.3),
	},
	"pipe_ripper": {
		"name": "Pipe Ripper",
		"description": "A burst-fire weapon that shreds anything in front of it.",
		"damage": 18,
		"fire_rate": 0.08,
		"magazine_size": 24,
		"reload_time": 1.5,
		"bullet_speed": 700.0,
		"bullet_count": 1,
		"spread": 0.08,
		"buy_price": 160,
		"sell_price": 95,
		"ammo_type": "standard_rounds",
		"burst_count": 3,
		"color": Color(0.5, 0.5, 0.9),
	},
}

# ---------------------------------------------------------------------------
# Ammo type definitions
# ---------------------------------------------------------------------------
const AMMO_TYPES: Dictionary = {
	"standard_rounds": {"name": "Standard Rounds", "buy_price": 5, "pack_size": 30},
	"junk_shells": {"name": "Junk Shells", "buy_price": 8, "pack_size": 12},
	"toxic_canisters": {"name": "Toxic Canisters", "buy_price": 10, "pack_size": 40},
	"junk_grenades": {"name": "Junk Grenades", "buy_price": 20, "pack_size": 6},
	"mold_rounds": {"name": "Mold Rounds", "buy_price": 12, "pack_size": 16},
}

# ---------------------------------------------------------------------------
# Consumable / pickup item definitions
# ---------------------------------------------------------------------------
const ITEMS: Dictionary = {
	"bandage": {
		"name": "Bandage",
		"description": "A dirty rag that somehow stops bleeding.",
		"heal_amount": 20,
		"buy_price": 15,
		"sell_price": 8,
		"type": "consumable",
	},
	"med_kit": {
		"name": "Med Kit",
		"description": "A battered first-aid box. Better than nothing.",
		"heal_amount": 60,
		"buy_price": 40,
		"sell_price": 20,
		"type": "consumable",
	},
	"junk_shield": {
		"name": "Junk Shield",
		"description": "Strapped-on scrap that absorbs a hit or two.",
		"armor_amount": 30,
		"buy_price": 35,
		"sell_price": 18,
		"type": "armor",
	},
	"toxic_resist": {
		"name": "Toxic Resist Pill",
		"description": "Grants temporary resistance to poison and toxic damage.",
		"duration": 30.0,
		"buy_price": 25,
		"sell_price": 12,
		"type": "consumable",
		"effect": "poison_resist",
	},
	"ammo_pack": {
		"name": "Ammo Pack",
		"description": "A mixed bag of ammunition. Refills all weapons partially.",
		"ammo_refill": 0.5,
		"buy_price": 20,
		"sell_price": 10,
		"type": "consumable",
	},
	"sewer_map": {
		"name": "Sewer Map",
		"description": "A hand-drawn map revealing hidden routes and shortcuts.",
		"buy_price": 60,
		"sell_price": 30,
		"type": "quest_item",
		"effect": "reveal_shortcut",
	},
}

# ---------------------------------------------------------------------------
# Enemy definitions
# ---------------------------------------------------------------------------
const ENEMIES: Dictionary = {
	"sewer_rat": {
		"name": "Sewer Rat",
		"description": "Oversized and aggressive. Found everywhere in the tunnels.",
		"health": 20,
		"damage": 8,
		"speed": 120.0,
		"jump_force": 280.0,
		"score": 10,
		"drop_chance": 0.3,
		"drops": ["bandage", "standard_rounds"],
		"color": Color(0.5, 0.35, 0.2),
		"ai_type": "patrol",
	},
	"mold_monster": {
		"name": "Mold Monster",
		"description": "A shambling mass of sentient fungus. Spits mold spores.",
		"health": 50,
		"damage": 15,
		"speed": 70.0,
		"jump_force": 200.0,
		"score": 30,
		"drop_chance": 0.5,
		"drops": ["mold_rounds", "mold_spores"],
		"color": Color(0.3, 0.5, 0.2),
		"ai_type": "chase",
		"ranged_attack": true,
	},
	"sewer_guard": {
		"name": "Sewer Guard",
		"description": "An armed enforcer protecting someone's turf. And their pension.",
		"health": 80,
		"damage": 20,
		"speed": 90.0,
		"jump_force": 320.0,
		"score": 50,
		"drop_chance": 0.6,
		"drops": ["standard_rounds", "bandage", "med_kit"],
		"color": Color(0.4, 0.4, 0.6),
		"ai_type": "guard",
		"ranged_attack": true,
	},
	"toxic_slug": {
		"name": "Toxic Slug",
		"description": "Leaves a trail of poison slime. Slow but relentless.",
		"health": 35,
		"damage": 12,
		"speed": 50.0,
		"jump_force": 0.0,
		"score": 20,
		"drop_chance": 0.4,
		"drops": ["toxic_canisters"],
		"color": Color(0.2, 0.7, 0.1),
		"ai_type": "patrol",
		"leaves_slime": true,
	},
	"rust_golem": {
		"name": "Rust Golem",
		"description": "An ancient construct of corroded iron. Near-unstoppable.",
		"health": 200,
		"damage": 35,
		"speed": 55.0,
		"jump_force": 250.0,
		"score": 150,
		"drop_chance": 0.8,
		"drops": ["scrap_metal", "rusted_components", "old_batteries"],
		"color": Color(0.6, 0.4, 0.2),
		"ai_type": "chase",
		"is_boss": true,
	},
}

# ---------------------------------------------------------------------------
# Rumour templates
# ---------------------------------------------------------------------------
const RUMOURS: Array[String] = [
	"They say {commodity} prices in {city} are through the roof right now.",
	"Word is that {city} is desperately short on {commodity}. Good time to buy some.",
	"A shipment of {commodity} got lost in the tunnels near {city}. Prices may spike.",
	"I heard the guards in {city} are cracking down. Watch yourself.",
	"There's a weapons dealer in {city} selling {weapon} for cheap. Couldn't believe it.",
	"Rumour has it the {enemy} population near {city} is exploding. Be careful on the road.",
	"Someone found a secret route between {city_a} and {city_b}. Faster and safer, I hear.",
	"The fungus harvest failed in {city}. Fungus Brew prices are going to sky-rocket.",
	"There's a hidden cache of {commodity} somewhere in the tunnels west of {city}.",
	"Old Baxter sold his entire {commodity} stock in {city} for double the normal price!",
	"The Rust Golem sightings near {city} have tripled this week. I wouldn't travel that route.",
	"They say the clinic in {city} is selling Med Kits for half price as a promotion.",
	"A new trader just set up shop in {city}. Nobody knows where they come from.",
	"The water got even more contaminated near {city}. Prices for water purifiers are up.",
	"I heard someone found a Mold Cannon in the deep tunnels. Just lying there.",
	"Big fight broke out in {city} between two trading factions. Business is disrupted.",
]

# ---------------------------------------------------------------------------
# Price fluctuation events
# ---------------------------------------------------------------------------
const MARKET_EVENTS: Array[Dictionary] = [
	{"name": "Rat Plague", "commodity": "rat_pelts", "effect": -0.4, "description": "A rat plague has flooded the market with pelts."},
	{"name": "Mold Blight", "commodity": "mold_spores", "effect": 0.6, "description": "A mold blight has made spores scarce."},
	{"name": "Sludge Spill", "commodity": "toxic_sludge", "effect": -0.3, "description": "A massive sludge spill means the stuff is everywhere."},
	{"name": "Salvage Boom", "commodity": "scrap_metal", "effect": -0.25, "description": "A major ruin was excavated, flooding the scrap market."},
	{"name": "Battery Shortage", "commodity": "old_batteries", "effect": 0.5, "description": "A critical shortage of batteries has driven prices up."},
	{"name": "Fungus Festival", "commodity": "fungus_brew", "effect": 0.4, "description": "The annual Fungus Festival has created huge demand."},
	{"name": "Pipe Burst", "commodity": "contaminated_water", "effect": -0.5, "description": "A major pipe burst has flooded everything with water."},
	{"name": "Tech Demand", "commodity": "rusted_components", "effect": 0.45, "description": "A new workshop opened and they need every component."},
]

# ---------------------------------------------------------------------------
# Player upgrade definitions
# ---------------------------------------------------------------------------
const UPGRADES: Dictionary = {
	"cargo_hold": {
		"name": "Cargo Hold Upgrade",
		"description": "Increases maximum cargo capacity by 20 units.",
		"levels": [1, 2, 3, 4],
		"prices": [100, 250, 500, 900],
		"effect": "cargo_capacity",
		"effect_values": [20, 20, 20, 20],
	},
	"armor_plating": {
		"name": "Armor Plating",
		"description": "Increases maximum health by 25 points.",
		"levels": [1, 2, 3, 4],
		"prices": [80, 200, 400, 750],
		"effect": "max_health",
		"effect_values": [25, 25, 25, 25],
	},
	"weapon_slots": {
		"name": "Weapon Holster",
		"description": "Adds an extra weapon slot (max 4 weapons).",
		"levels": [1, 2, 3],
		"prices": [120, 300, 600],
		"effect": "weapon_slots",
		"effect_values": [1, 1, 1],
	},
	"boots": {
		"name": "Power Boots",
		"description": "Enhanced jumping ability.",
		"levels": [1, 2],
		"prices": [90, 220],
		"effect": "jump_force",
		"effect_values": [50, 50],
	},
	"speed_boost": {
		"name": "Speed Implant",
		"description": "Increases movement speed.",
		"levels": [1, 2],
		"prices": [110, 280],
		"effect": "speed",
		"effect_values": [30, 30],
	},
}

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

func get_city_by_id(city_id: String) -> Dictionary:
	for city in CITIES:
		if city["id"] == city_id:
			return city
	return {}

func get_random_city_id() -> String:
	return CITIES[randi() % CITIES.size()]["id"]

func get_commodity_price(commodity_id: String, city_id: String, modifier: float = 1.0) -> int:
	var city := get_city_by_id(city_id)
	if city.is_empty() or not city["base_prices"].has(commodity_id):
		return 0
	var base: int = city["base_prices"][commodity_id]
	if commodity_id in city.get("special_goods", []):
		modifier *= randf_range(0.6, 0.9)
	else:
		modifier *= randf_range(0.85, 1.25)
	return max(1, roundi(base * modifier))

func get_random_rumour(current_city_id: String) -> String:
	var template: String = RUMOURS[randi() % RUMOURS.size()]
	var commodity_keys := COMMODITIES.keys()
	var weapon_keys := WEAPONS.keys()
	var enemy_keys := ENEMIES.keys()
	var city_names: Array[String] = []
	for c in CITIES:
		city_names.append(c["name"])
	var other_cities: Array[String] = city_names.filter(
		func(n): return n != get_city_by_id(current_city_id).get("name", "")
	)

	template = template.replace("{commodity}", COMMODITIES[commodity_keys[randi() % commodity_keys.size()]]["name"])
	template = template.replace("{city}", city_names[randi() % city_names.size()])
	template = template.replace("{city_a}", city_names[randi() % city_names.size()])
	template = template.replace("{city_b}", other_cities[randi() % other_cities.size()] if not other_cities.is_empty() else city_names[0])
	template = template.replace("{weapon}", WEAPONS[weapon_keys[randi() % weapon_keys.size()]]["name"])
	template = template.replace("{enemy}", ENEMIES[enemy_keys[randi() % enemy_keys.size()]]["name"])
	return template
