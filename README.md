# Sewer Taipan

A **Godot 4** game template inspired by the classic *Taipan* trading game — but instead of turn-based combat between port visits, you fight your way through randomised **Megaman-style side-scrolling sewer levels** to reach each new city.

---

## Concept

> *You are a trader navigating the grimy sewer underworld beneath a forgotten city.
> Buy low. Sell high. Blast anything that stands in your way.*

The game alternates between two distinct modes:

| Mode | Description |
|------|-------------|
| **City screen** | Flat, menu-based trading hub. Visit the market, armory, clinic, inn, and workshop. |
| **Travel level** | Procedurally generated side-scrolling platformer. Start on the left, reach the exit on the right. |

---

## Features

### 🏙️ City (Menu-Based)
- **Market** – Buy and sell 8 sewer-themed commodities at fluctuating prices
- **Armory** – Buy/sell 6 different weapons; restock ammo packs
- **Clinic** – Pay gold to heal HP
- **Inn** – Rest to recover health (advances the day); buy rumours about distant markets
- **Travel** – Choose a destination and set off into the tunnels
- **Inventory** – Use or drop consumable items
- **Workshop** – Upgrade cargo hold, armor plating, weapon slots, boots, and speed

### 🎮 Platformer Level (Megaman-Style)
- Procedurally generated levels scaled to destination city difficulty (1–4)
- Full player movement: run, jump with coyote time & jump buffering, fall
- **6 weapons** with unique behaviours:
  - Rust Blaster (pistol, fast semi-auto)
  - Sewer Shotgun (wide spread)
  - Toxic Sprayer (rapid-fire, poisons enemies)
  - Junk Launcher (explosive grenades)
  - Mold Cannon (heavy, slow)
  - Pipe Ripper (burst fire)
- Weapon switching (Q / E), reload (R), drop item (G)
- **5 enemy types**: Sewer Rat, Mold Monster, Sewer Guard, Toxic Slug, Rust Golem (boss)
- Item pickups (health packs, ammo, shields, buffs)
- Die → Retry or Main Menu; reach the exit → arrive at destination

### 🗺️ Sewer Cities
All 8 cities have sewer/junk-themed names and unique commodity specialities:

| City | Speciality |
|------|-----------|
| Sludge Harbor | Rat Pelts, Contaminated Water |
| Mucktown | Mold Spores, Fungus Brew |
| Drainpipe Alley | Rusted Components, Old Batteries |
| Cesspool Junction | Toxic Sludge, Scrap Metal |
| Gutter City | Old Batteries, Rusted Components |
| Scumburg | Scrap Metal, Toxic Sludge |
| Filth Hollow | Rat Pelts, Mold Spores |
| Rotgut Row | Fungus Brew, Mold Spores |

### 📦 Commodities
Scrap Metal · Rat Pelts · Toxic Sludge · Mold Spores · Rusted Components · Contaminated Water · Fungus Brew · Old Batteries

### 💾 Save System
Games are auto-saved on travel and can be manually saved from the city screen. Saved to `user://savegame.cfg`.

---

## Project Structure

```
project.godot          ← Godot 4 project file
icon.svg               ← Project icon

scripts/
  autoloads/
    game_data.gd       ← All static game definitions (cities, weapons, items, enemies, rumours)
    game_state.gd      ← Dynamic game state singleton (health, gold, inventory, save/load)
  player.gd            ← Player CharacterBody2D (movement, shooting, weapon management)
  bullet.gd            ← Projectile Area2D
  enemy.gd             ← Enemy CharacterBody2D with patrol/chase/guard AI
  item_pickup.gd       ← Collectible item Area2D
  level_generator.gd   ← Procedural platformer level generator
  platformer_level.gd  ← Level root: win/lose conditions, HUD management
  city_ui.gd           ← City scene TabContainer controller
  trader.gd            ← Static buy/sell/upgrade logic
  rumour_system.gd     ← Rumour generation helper
  hud.gd               ← In-level heads-up display
  main_menu.gd         ← Main menu screen

scenes/
  main_menu.tscn       ← Main menu
  city.tscn            ← City trading hub
  platformer_level.tscn← Side-scrolling travel level
  player.tscn          ← Player prefab
  bullet.tscn          ← Bullet prefab
  enemy.tscn           ← Enemy prefab
  item_pickup.tscn     ← Pickup prefab
  ui/
    hud.tscn           ← In-level HUD overlay
```

---

## Controls

| Action | Key / Button |
|--------|-------------|
| Move Left / Right | A / D or Arrow Keys |
| Jump | Space / W / Up Arrow |
| Shoot | Left Click / Z |
| Next Weapon | E |
| Previous Weapon | Q |
| Reload | R |
| Drop Item | G |
| Inventory | I |
| Pause | Escape |

---

## Getting Started

1. Open **Godot 4** (version 4.2+)
2. Import the project by pointing Godot at the project directory
3. Open `project.godot` and run the project
4. The main menu will appear — click **New Game** to start

> **Note:** This is a template project. Placeholder visuals use `ColorRect` nodes. To complete the game, add proper sprite sheets, tilemaps, sound effects, and a theme resource.

---

## Extending the Template

- **Add art**: Replace `ColorRect` placeholders in `player.tscn`, `enemy.tscn`, and `item_pickup.tscn` with `AnimatedSprite2D` nodes and your own sprite sheets
- **Add a TileSet**: Create a `TileSet` resource and assign it to the `TileMapLayer` in `platformer_level.tscn` to get proper tile-based level rendering
- **More cities**: Extend the `CITIES` array in `game_data.gd`
- **More weapons**: Extend the `WEAPONS` dictionary — the firing system automatically handles all weapon properties
- **Market events**: The `MARKET_EVENTS` array in `game_data.gd` is ready to hook into a world-event scheduler
- **Sound**: Add `AudioStreamPlayer` nodes and trigger them from the relevant script methods

---

## License

This is a game template provided as-is. Use it however you like.
