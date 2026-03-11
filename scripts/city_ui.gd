## CityUI – Control
## Master controller for the city scene.
## Manages the tab panels: Market, Armory, Clinic, Inn, Travel, Inventory.
extends Control

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------
@onready var city_name_label: Label = $Header/CityNameLabel
@onready var city_desc_label: Label = $Header/CityDescLabel
@onready var gold_label: Label = $Header/StatsRow/GoldLabel
@onready var health_label: Label = $Header/StatsRow/HealthLabel
@onready var cargo_label: Label = $Header/StatsRow/CargoLabel
@onready var day_label: Label = $Header/StatsRow/DayLabel
@onready var tab_container: TabContainer = $TabContainer
@onready var status_label: Label = $StatusLabel

# Market panel nodes
@onready var market_list: ItemList = $TabContainer/Market/MarketList
@onready var market_qty_spin: SpinBox = $TabContainer/Market/QuantityRow/QuantitySpinBox
@onready var market_buy_btn: Button = $TabContainer/Market/ActionRow/BuyButton
@onready var market_sell_btn: Button = $TabContainer/Market/ActionRow/SellButton
@onready var market_price_label: Label = $TabContainer/Market/PriceLabel

# Armory panel nodes
@onready var armory_weapon_list: ItemList = $TabContainer/Armory/WeaponList
@onready var armory_buy_list: ItemList = $TabContainer/Armory/BuyList
@onready var armory_buy_btn: Button = $TabContainer/Armory/ArmoryButtonRow/BuyButton
@onready var armory_sell_btn: Button = $TabContainer/Armory/ArmoryButtonRow/SellButton
@onready var ammo_list: ItemList = $TabContainer/Armory/AmmoList
@onready var ammo_buy_btn: Button = $TabContainer/Armory/AmmoBuyButton

# Clinic panel nodes
@onready var clinic_heal_slider: HSlider = $TabContainer/Clinic/HealRow/HealSlider
@onready var clinic_cost_label: Label = $TabContainer/Clinic/HealRow/CostLabel
@onready var clinic_heal_btn: Button = $TabContainer/Clinic/HealButton

# Inn panel nodes
@onready var rumour_list: RichTextLabel = $TabContainer/Inn/RumourList
@onready var rest_btn: Button = $TabContainer/Inn/InnButtonRow/RestButton
@onready var rumours_btn: Button = $TabContainer/Inn/InnButtonRow/RumoursButton

# Travel panel nodes
@onready var city_dest_list: ItemList = $TabContainer/Travel/CityList
@onready var travel_btn: Button = $TabContainer/Travel/TravelButton
@onready var travel_info_label: Label = $TabContainer/Travel/InfoLabel

# Inventory panel nodes
@onready var inv_list: ItemList = $TabContainer/Inventory/InventoryList
@onready var inv_use_btn: Button = $TabContainer/Inventory/InvButtonRow/UseButton
@onready var inv_drop_btn: Button = $TabContainer/Inventory/InvButtonRow/DropButton

# Upgrades panel nodes
@onready var upgrade_list: ItemList = $TabContainer/Upgrades/UpgradeList
@onready var upgrade_buy_btn: Button = $TabContainer/Upgrades/BuyButton

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _selected_commodity: String = ""
var _selected_weapon_slot: int = -1
var _selected_ammo_type: String = ""
var _selected_dest_city_id: String = ""
var _selected_item_id: String = ""
var _selected_upgrade_id: String = ""

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	GameState.health_changed.connect(_refresh_header)
	GameState.gold_changed.connect(func(_g): _refresh_header())
	GameState.cargo_changed.connect(func(_c, _cap): _refresh_header(); _refresh_market())
	GameState.weapons_changed.connect(func(_w): _refresh_armory())
	_refresh_header()
	_refresh_market()
	_refresh_armory()
	_refresh_travel()
	_refresh_inventory()
	_refresh_upgrades()

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
func _refresh_header(_a = null, _b = null) -> void:
	var city := GameData.get_city_by_id(GameState.current_city_id)
	if city_name_label:
		city_name_label.text = city.get("name", "Unknown City")
	if city_desc_label:
		city_desc_label.text = city.get("description", "")
	if gold_label:
		gold_label.text = "Gold: %d" % GameState.gold
	if health_label:
		health_label.text = "HP: %d/%d" % [GameState.player_health, GameState.player_max_health]
	if cargo_label:
		cargo_label.text = "Cargo: %d/%d" % [GameState.get_cargo_used(), GameState.cargo_capacity]
	if day_label:
		day_label.text = "Day %d" % GameState.day

# ---------------------------------------------------------------------------
# Market panel
# ---------------------------------------------------------------------------
func _refresh_market() -> void:
	if not market_list:
		return
	market_list.clear()
	for commodity_id in GameData.COMMODITIES:
		var cdata := GameData.COMMODITIES[commodity_id]
		var buy_price := GameState.get_price(commodity_id)
		var owned: int = GameState.cargo.get(commodity_id, 0)
		var text := "%s  Buy: %dg  Sell: %dg  Owned: %d" % [
			cdata["name"], buy_price, roundi(buy_price * 0.85), owned
		]
		market_list.add_item(text)
		market_list.set_item_metadata(market_list.item_count - 1, commodity_id)

func _on_market_list_item_selected(index: int) -> void:
	_selected_commodity = market_list.get_item_metadata(index)
	var price := GameState.get_price(_selected_commodity)
	if market_price_label:
		market_price_label.text = "Buy: %dg  Sell: %dg" % [price, roundi(price * 0.85)]

func _on_buy_button_pressed() -> void:
	if _selected_commodity == "":
		_show_status("Select a commodity first.")
		return
	var qty := int(market_qty_spin.value) if market_qty_spin else 1
	var result := Trader.buy_commodity(_selected_commodity, qty, GameState.current_city_id)
	if result["ok"]:
		_show_status("Bought %dx %s for %dg." % [qty, GameData.COMMODITIES[_selected_commodity]["name"], result.get("cost", 0)])
	else:
		_show_status("Could not buy: %s" % result.get("reason", "Unknown error."))
	_refresh_market()

func _on_sell_button_pressed() -> void:
	if _selected_commodity == "":
		_show_status("Select a commodity first.")
		return
	var qty := int(market_qty_spin.value) if market_qty_spin else 1
	var result := Trader.sell_commodity(_selected_commodity, qty, GameState.current_city_id)
	_show_status("Sold." if result["ok"] else result.get("reason", "Error"))
	_refresh_market()

# ---------------------------------------------------------------------------
# Armory panel
# ---------------------------------------------------------------------------
func _refresh_armory() -> void:
	if not armory_weapon_list:
		return
	armory_weapon_list.clear()
	for i in GameState.weapons.size():
		var entry := GameState.weapons[i]
		var wd := GameData.WEAPONS.get(entry["id"], {})
		var active_marker := " [ACTIVE]" if i == GameState.active_weapon_index else ""
		armory_weapon_list.add_item("%s  Ammo: %d/%d%s" % [
			wd.get("name", entry["id"]), entry["ammo"], wd.get("magazine_size", 0), active_marker
		])
		armory_weapon_list.set_item_metadata(i, i)

	if armory_buy_list:
		armory_buy_list.clear()
		for weapon_id in GameData.WEAPONS:
			var wd := GameData.WEAPONS[weapon_id]
			armory_buy_list.add_item("%s  %dg" % [wd["name"], wd["buy_price"]])
			armory_buy_list.set_item_metadata(armory_buy_list.item_count - 1, weapon_id)

	if ammo_list:
		ammo_list.clear()
		for ammo_id in GameData.AMMO_TYPES:
			var ad := GameData.AMMO_TYPES[ammo_id]
			ammo_list.add_item("%s  %dg / pack of %d" % [ad["name"], ad["buy_price"], ad["pack_size"]])
			ammo_list.set_item_metadata(ammo_list.item_count - 1, ammo_id)

func _on_armory_weapon_list_item_selected(index: int) -> void:
	_selected_weapon_slot = index

func _on_armory_buy_list_item_selected(index: int) -> void:
	if armory_buy_list:
		_selected_weapon_slot = -1  # signal "buy mode"
		var weapon_id: String = armory_buy_list.get_item_metadata(index)
		_selected_commodity = weapon_id

func _on_armory_buy_pressed() -> void:
	if _selected_commodity == "" or not GameData.WEAPONS.has(_selected_commodity):
		_show_status("Select a weapon to buy.")
		return
	var result := Trader.buy_weapon(_selected_commodity)
	_show_status(result.get("reason", "Weapon purchased!") if not result["ok"] else "Purchased!")
	_refresh_armory()

func _on_armory_sell_pressed() -> void:
	if _selected_weapon_slot < 0:
		_show_status("Select a weapon to sell.")
		return
	var result := Trader.sell_weapon(_selected_weapon_slot)
	_show_status(result.get("reason", "Sold!") if not result["ok"] else "Sold for %dg!" % result.get("gain", 0))
	_refresh_armory()

func _on_ammo_list_item_selected(index: int) -> void:
	if ammo_list:
		_selected_ammo_type = ammo_list.get_item_metadata(index)

func _on_ammo_buy_pressed() -> void:
	if _selected_ammo_type == "":
		_show_status("Select an ammo type.")
		return
	var result := Trader.buy_ammo(_selected_ammo_type)
	_show_status(result.get("reason", "Ammo purchased!") if not result["ok"] else "Ammo refilled!")
	_refresh_armory()

# ---------------------------------------------------------------------------
# Clinic panel
# ---------------------------------------------------------------------------
func _on_heal_slider_value_changed(value: float) -> void:
	var amount := int(value)
	var cost := Trader.get_heal_cost(amount)
	if clinic_cost_label:
		clinic_cost_label.text = "Cost: %dg" % cost

func _on_clinic_heal_pressed() -> void:
	if not clinic_heal_slider:
		return
	var amount := int(clinic_heal_slider.value)
	var result := Trader.buy_heal(amount)
	_show_status(result.get("reason", "Healed!") if not result["ok"] else "Healed %d HP!" % amount)

# ---------------------------------------------------------------------------
# Inn panel
# ---------------------------------------------------------------------------
func _on_rumours_pressed() -> void:
	var rumours := RumourSystem.get_rumours(3)
	if rumour_list:
		rumour_list.clear()
		for r in rumours:
			rumour_list.append_text("• " + r + "\n\n")
	var inn_cost := 10
	GameState.spend_gold(inn_cost)
	_show_status("You pay %dg for the gossip." % inn_cost)

func _on_rest_pressed() -> void:
	var rest_cost := 20
	if not GameState.spend_gold(rest_cost):
		_show_status("Can't afford to rest (%dg)." % rest_cost)
		return
	GameState.heal(30)
	_show_status("You rest at the inn. Healed 30 HP. Day advances.")
	GameState.day += 1
	GameState.day_changed.emit(GameState.day)
	_refresh_header()

# ---------------------------------------------------------------------------
# Travel panel
# ---------------------------------------------------------------------------
func _refresh_travel() -> void:
	if not city_dest_list:
		return
	city_dest_list.clear()
	for city in GameData.CITIES:
		if city["id"] == GameState.current_city_id:
			continue
		city_dest_list.add_item("%s  (Difficulty: %d)" % [city["name"], city["level_difficulty"]])
		city_dest_list.set_item_metadata(city_dest_list.item_count - 1, city["id"])

func _on_city_list_item_selected(index: int) -> void:
	_selected_dest_city_id = city_dest_list.get_item_metadata(index)
	var dest := GameData.get_city_by_id(_selected_dest_city_id)
	if travel_info_label:
		travel_info_label.text = dest.get("description", "")

func _on_travel_pressed() -> void:
	if _selected_dest_city_id == "":
		_show_status("Select a destination.")
		return
	GameState.save_game()
	GameState.travel_to(_selected_dest_city_id)

# ---------------------------------------------------------------------------
# Inventory panel
# ---------------------------------------------------------------------------
func _refresh_inventory() -> void:
	if not inv_list:
		return
	inv_list.clear()
	for item_id in GameState.inventory_items:
		var qty: int = GameState.inventory_items[item_id]
		var idata := GameData.ITEMS.get(item_id, {})
		inv_list.add_item("%s x%d" % [idata.get("name", item_id), qty])
		inv_list.set_item_metadata(inv_list.item_count - 1, item_id)

func _on_inv_list_item_selected(index: int) -> void:
	_selected_item_id = inv_list.get_item_metadata(index)

func _on_inv_use_pressed() -> void:
	if _selected_item_id == "":
		_show_status("Select an item first.")
		return
	if GameState.use_item(_selected_item_id):
		_show_status("Used %s." % GameData.ITEMS.get(_selected_item_id, {}).get("name", _selected_item_id))
	else:
		_show_status("Cannot use that item.")
	_refresh_inventory()

func _on_inv_drop_pressed() -> void:
	if _selected_item_id == "":
		_show_status("Select an item first.")
		return
	GameState.remove_item(_selected_item_id)
	_show_status("Dropped item.")
	_refresh_inventory()

# ---------------------------------------------------------------------------
# Upgrades panel
# ---------------------------------------------------------------------------
func _refresh_upgrades() -> void:
	if not upgrade_list:
		return
	upgrade_list.clear()
	for upgrade_id in GameData.UPGRADES:
		var udata := GameData.UPGRADES[upgrade_id]
		var current_level := GameState.get_upgrade_level(upgrade_id)
		var max_level: int = udata["levels"].size()
		var text: String
		if current_level >= max_level:
			text = "%s  [MAX]" % udata["name"]
		else:
			var price: int = udata["prices"][current_level]
			text = "%s  Level %d/%d  Cost: %dg" % [udata["name"], current_level + 1, max_level, price]
		upgrade_list.add_item(text)
		upgrade_list.set_item_metadata(upgrade_list.item_count - 1, upgrade_id)

func _on_upgrade_list_item_selected(index: int) -> void:
	_selected_upgrade_id = upgrade_list.get_item_metadata(index)

func _on_upgrade_buy_pressed() -> void:
	if _selected_upgrade_id == "":
		_show_status("Select an upgrade.")
		return
	var result := Trader.buy_upgrade(_selected_upgrade_id)
	_show_status("Upgraded!" if result["ok"] else result.get("reason", "Failed."))
	_refresh_upgrades()
	_refresh_header()

# ---------------------------------------------------------------------------
# Save & return to main menu
# ---------------------------------------------------------------------------
func _on_save_pressed() -> void:
	GameState.save_game()
	_show_status("Game saved.")

func _on_main_menu_pressed() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(GameState.MAIN_MENU_SCENE)

# ---------------------------------------------------------------------------
# Status bar
# ---------------------------------------------------------------------------
func _show_status(msg: String) -> void:
	if status_label:
		status_label.text = msg
