## Trader – handles the buy/sell logic for a single commodity or item vendor.
## Instantiated and configured by the city UI panels.
class_name Trader
extends RefCounted

# ---------------------------------------------------------------------------
# Commodity trading
# ---------------------------------------------------------------------------
static func buy_commodity(commodity_id: String, quantity: int, city_id: String) -> Dictionary:
	var price_per_unit := GameState.get_price(commodity_id, city_id)
	var total_cost := price_per_unit * quantity
	if GameState.gold < total_cost:
		return {"ok": false, "reason": "Not enough gold."}
	if not GameState.add_cargo(commodity_id, quantity):
		return {"ok": false, "reason": "Not enough cargo space."}
	GameState.spend_gold(total_cost)
	return {"ok": true, "cost": total_cost}

static func sell_commodity(commodity_id: String, quantity: int, city_id: String) -> Dictionary:
	if GameState.cargo.get(commodity_id, 0) < quantity:
		return {"ok": false, "reason": "You don't have that much."}
	var price_per_unit := GameState.get_price(commodity_id, city_id)
	# Sell price is slightly less than buy price
	var sell_price := roundi(price_per_unit * 0.85)
	var total_gain := sell_price * quantity
	GameState.remove_cargo(commodity_id, quantity)
	GameState.add_gold(total_gain)
	GameState.total_profit += total_gain
	return {"ok": true, "gain": total_gain}

# ---------------------------------------------------------------------------
# Weapon / item shop
# ---------------------------------------------------------------------------
static func buy_weapon(weapon_id: String) -> Dictionary:
	var weapon_data := GameData.WEAPONS.get(weapon_id, {})
	if weapon_data.is_empty():
		return {"ok": false, "reason": "Unknown weapon."}
	var price: int = weapon_data.get("buy_price", 9999)
	if GameState.gold < price:
		return {"ok": false, "reason": "Not enough gold."}
	if not GameState.add_weapon(weapon_id):
		return {"ok": false, "reason": "No weapon slot available. Drop a weapon first."}
	GameState.spend_gold(price)
	return {"ok": true}

static func sell_weapon(weapon_index: int) -> Dictionary:
	if weapon_index < 0 or weapon_index >= GameState.weapons.size():
		return {"ok": false, "reason": "Invalid weapon slot."}
	var weapon_id: String = GameState.weapons[weapon_index]["id"]
	var weapon_data := GameData.WEAPONS.get(weapon_id, {})
	var sell_price: int = weapon_data.get("sell_price", 0)
	GameState.drop_weapon(weapon_index)
	GameState.add_gold(sell_price)
	return {"ok": true, "gain": sell_price}

static func buy_item(item_id: String) -> Dictionary:
	var item_data := GameData.ITEMS.get(item_id, {})
	if item_data.is_empty():
		return {"ok": false, "reason": "Unknown item."}
	var price: int = item_data.get("buy_price", 9999)
	if not GameState.spend_gold(price):
		return {"ok": false, "reason": "Not enough gold."}
	GameState.add_item(item_id)
	return {"ok": true}

static func sell_item(item_id: String) -> Dictionary:
	if GameState.inventory_items.get(item_id, 0) <= 0:
		return {"ok": false, "reason": "You don't have that item."}
	var item_data := GameData.ITEMS.get(item_id, {})
	var sell_price: int = item_data.get("sell_price", 0)
	GameState.remove_item(item_id)
	GameState.add_gold(sell_price)
	return {"ok": true, "gain": sell_price}

static func buy_ammo(ammo_type: String) -> Dictionary:
	var ammo_data := GameData.AMMO_TYPES.get(ammo_type, {})
	if ammo_data.is_empty():
		return {"ok": false, "reason": "Unknown ammo type."}
	var price: int = ammo_data.get("buy_price", 999)
	if not GameState.spend_gold(price):
		return {"ok": false, "reason": "Not enough gold."}
	# Refill matching weapon magazines
	for i in GameState.weapons.size():
		var entry := GameState.weapons[i]
		var wd := GameData.WEAPONS.get(entry["id"], {})
		if wd.get("ammo_type", "") == ammo_type:
			var pack_size: int = ammo_data.get("pack_size", 10)
			var mag: int = wd.get("magazine_size", 10)
			GameState.weapons[i]["ammo"] = mini(entry["ammo"] + pack_size, mag)
	GameState.weapons_changed.emit(GameState.weapons)
	return {"ok": true}

# ---------------------------------------------------------------------------
# Repairs / healing (clinic)
# ---------------------------------------------------------------------------
static func buy_heal(amount: int) -> Dictionary:
	var cost := amount * 1  # 1 gold per HP
	if not GameState.spend_gold(cost):
		return {"ok": false, "reason": "Not enough gold."}
	GameState.heal(amount)
	return {"ok": true}

static func get_heal_cost(amount: int) -> int:
	return amount

# ---------------------------------------------------------------------------
# Upgrades (workshop)
# ---------------------------------------------------------------------------
static func buy_upgrade(upgrade_id: String) -> Dictionary:
	var result := GameState.apply_upgrade(upgrade_id)
	if result:
		return {"ok": true}
	var upgrade_data := GameData.UPGRADES.get(upgrade_id, {})
	if upgrade_data.is_empty():
		return {"ok": false, "reason": "Unknown upgrade."}
	var current_level := GameState.get_upgrade_level(upgrade_id)
	if current_level >= upgrade_data["levels"].size():
		return {"ok": false, "reason": "Already at max level."}
	return {"ok": false, "reason": "Not enough gold."}
