## Player – CharacterBody2D
## Handles movement, jumping, shooting, weapon management, and pickups.
## Reads base stats from GameState and weapon data from GameData.
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal died()
signal weapon_fired(weapon_id: String)
signal item_picked_up(item_id: String)
signal reached_exit()

# ---------------------------------------------------------------------------
# Movement constants
# ---------------------------------------------------------------------------
@export var move_speed: float = 220.0
@export var jump_force: float = 500.0
@export var gravity_scale: float = 1.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.1

# ---------------------------------------------------------------------------
# Node references (set up in scene)
# ---------------------------------------------------------------------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle
@onready var weapon_cooldown_timer: Timer = $WeaponCooldownTimer
@onready var reload_timer: Timer = $ReloadTimer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var hurt_flash_timer: Timer = $HurtFlashTimer
@onready var invincibility_timer: Timer = $InvincibilityTimer

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _is_reloading: bool = false
var _is_invincible: bool = false
var _facing_right: bool = true
var _coyote_available: bool = false
var _jump_buffered: bool = false
var _on_floor_last: bool = false
var _burst_count_remaining: int = 0
var _burst_timer: float = 0.0

const BURST_INTERVAL: float = 0.08
const HURT_FLASH_DURATION: float = 0.08
const INVINCIBILITY_DURATION: float = 0.6

# ---------------------------------------------------------------------------
# Bullet scene
# ---------------------------------------------------------------------------
const BULLET_SCENE := preload("res://scenes/bullet.tscn")

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("player")
	_apply_state_upgrades()
	GameState.health_changed.connect(_on_health_changed)
	GameState.weapons_changed.connect(_on_weapons_changed)

func _apply_state_upgrades() -> void:
	var speed_level := GameState.get_upgrade_level("speed_boost")
	move_speed += speed_level * 30.0
	var jump_level := GameState.get_upgrade_level("boots")
	jump_force += jump_level * 50.0

# ---------------------------------------------------------------------------
# Input & physics
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	_handle_weapon_input()
	_update_animation()
	if _burst_count_remaining > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_fire_single_bullet()
			_burst_count_remaining -= 1
			_burst_timer = BURST_INTERVAL

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement()
	_handle_jump()
	move_and_slide()
	_update_coyote(delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * gravity_scale * delta
		velocity.y = minf(velocity.y, 1200.0)

func _handle_movement() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * move_speed
	if dir > 0.0:
		_facing_right = true
	elif dir < 0.0:
		_facing_right = false
	if sprite:
		sprite.flip_h = not _facing_right

func _handle_jump() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _on_floor_last:
		_coyote_available = true
		coyote_timer.start(coyote_time)

	if Input.is_action_just_pressed("jump"):
		if on_floor or _coyote_available:
			_do_jump()
		else:
			_jump_buffered = true
			jump_buffer_timer.start(jump_buffer_time)

	if _jump_buffered and on_floor:
		_do_jump()
		_jump_buffered = false

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

	_on_floor_last = on_floor

func _do_jump() -> void:
	velocity.y = -jump_force
	_coyote_available = false
	_jump_buffered = false
	if sprite:
		sprite.play("jump")

func _update_coyote(_delta: float) -> void:
	if not is_on_floor() and _on_floor_last:
		coyote_timer.start(coyote_time)
		_coyote_available = true

# ---------------------------------------------------------------------------
# Weapon input
# ---------------------------------------------------------------------------
func _handle_weapon_input() -> void:
	if Input.is_action_just_pressed("weapon_next"):
		GameState.next_weapon()
	if Input.is_action_just_pressed("weapon_prev"):
		GameState.prev_weapon()
	if Input.is_action_just_pressed("reload"):
		_start_reload()
	if Input.is_action_just_pressed("shoot") or Input.is_action_pressed("shoot"):
		_try_fire()

func _try_fire() -> void:
	if _is_reloading or not weapon_cooldown_timer.is_stopped():
		return
	var weapon_entry := GameState.get_active_weapon()
	if weapon_entry.is_empty():
		return
	var weapon_id: String = weapon_entry["id"]
	var weapon_data := GameData.WEAPONS.get(weapon_id, {})
	if weapon_data.is_empty():
		return
	if weapon_entry["ammo"] <= 0:
		_start_reload()
		return

	GameState.use_ammo(GameState.active_weapon_index)
	weapon_cooldown_timer.start(weapon_data.get("fire_rate", 0.4))

	var burst: int = weapon_data.get("burst_count", 1)
	if burst > 1:
		_burst_count_remaining = burst - 1
		_burst_timer = BURST_INTERVAL

	_fire_single_bullet()
	weapon_fired.emit(weapon_id)

func _fire_single_bullet() -> void:
	var weapon_entry := GameState.get_active_weapon()
	if weapon_entry.is_empty():
		return
	var weapon_id: String = weapon_entry["id"]
	var weapon_data := GameData.WEAPONS.get(weapon_id, {})
	if weapon_data.is_empty():
		return

	var count: int = weapon_data.get("bullet_count", 1)
	var spread: float = weapon_data.get("spread", 0.0)
	var speed: float = weapon_data.get("bullet_speed", 600.0)
	var dmg: int = weapon_data.get("damage", 10)
	var dir := Vector2.RIGHT if _facing_right else Vector2.LEFT

	for i in count:
		var angle_offset := 0.0
		if count > 1:
			angle_offset = randf_range(-spread, spread)
		elif spread > 0.0:
			angle_offset = randf_range(-spread, spread)

		var bullet_dir := dir.rotated(angle_offset)
		var bullet: Node2D = BULLET_SCENE.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = muzzle.global_position if muzzle else global_position
		bullet.setup(bullet_dir * speed, dmg, false,
			weapon_data.get("explosive", false),
			weapon_data.get("explosion_radius", 0.0),
			weapon_data.get("status_effect", ""),
			weapon_data.get("color", Color.WHITE))

func _start_reload() -> void:
	if _is_reloading:
		return
	var weapon_entry := GameState.get_active_weapon()
	if weapon_entry.is_empty():
		return
	var weapon_id: String = weapon_entry["id"]
	var weapon_data := GameData.WEAPONS.get(weapon_id, {})
	if weapon_data.is_empty():
		return
	_is_reloading = true
	reload_timer.start(weapon_data.get("reload_time", 1.5))
	if sprite:
		sprite.play("reload")

# ---------------------------------------------------------------------------
# Damage
# ---------------------------------------------------------------------------
func take_damage(amount: int) -> void:
	if _is_invincible:
		return
	GameState.damage(amount)
	_is_invincible = true
	invincibility_timer.start(INVINCIBILITY_DURATION)
	hurt_flash_timer.start(HURT_FLASH_DURATION)
	if sprite:
		sprite.modulate = Color(1.0, 0.2, 0.2)

# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------
func _update_animation() -> void:
	if not sprite:
		return
	if _is_reloading:
		return
	if not is_on_floor():
		if velocity.y < 0.0:
			sprite.play("jump")
		else:
			sprite.play("fall")
	elif abs(velocity.x) > 10.0:
		sprite.play("run")
	else:
		sprite.play("idle")

# ---------------------------------------------------------------------------
# Timer callbacks
# ---------------------------------------------------------------------------
func _on_reload_timer_timeout() -> void:
	_is_reloading = false
	GameState.reload_weapon(GameState.active_weapon_index)

func _on_coyote_timer_timeout() -> void:
	_coyote_available = false

func _on_jump_buffer_timer_timeout() -> void:
	_jump_buffered = false

func _on_hurt_flash_timer_timeout() -> void:
	if sprite:
		sprite.modulate = Color.WHITE

func _on_invincibility_timer_timeout() -> void:
	_is_invincible = false

# ---------------------------------------------------------------------------
# Signal handlers from GameState
# ---------------------------------------------------------------------------
func _on_health_changed(_new_health: int, _max_health: int) -> void:
	if not GameState.is_alive():
		died.emit()

func _on_weapons_changed(_weapons: Array) -> void:
	pass  # HUD handles the display update

# ---------------------------------------------------------------------------
# Area detection (pickups, exit)
# ---------------------------------------------------------------------------
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("pickup"):
		var item_id: String = area.get_meta("item_id", "")
		if item_id == "exit":
			reached_exit.emit()
			return
		if item_id != "":
			GameState.add_item(item_id)
			item_picked_up.emit(item_id)
			area.queue_free()
	elif area.is_in_group("hazard"):
		take_damage(area.get_meta("damage", 10))
