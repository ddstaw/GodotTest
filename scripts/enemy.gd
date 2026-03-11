## Enemy – CharacterBody2D
## Base enemy controller. Supports patrol, chase, and guard AI modes.
## Configured by a type_id that maps to GameData.ENEMIES.
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal died(enemy_node: Node)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
@export var type_id: String = "sewer_rat"

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------
@onready var sprite: ColorRect = $ColorRect
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var patrol_timer: Timer = $PatrolTimer
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var health_bar: ProgressBar = $HealthBar

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------
var _data: Dictionary = {}
var _health: int = 20
var _max_health: int = 20
var _target: Node = null
var _patrol_dir: int = 1
var _ai_state: String = "patrol"
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _slime_trail_timer: float = 0.0

const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const SLIME_INTERVAL: float = 0.5

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_data = GameData.ENEMIES.get(type_id, GameData.ENEMIES["sewer_rat"])
	_health = _data.get("health", 20)
	_max_health = _health
	add_to_group("enemy")
	_update_visuals()
	patrol_timer.start(randf_range(1.5, 3.5))
	detection_area.body_entered.connect(_on_body_entered_detection)
	detection_area.body_exited.connect(_on_body_exited_detection)
	if attack_area:
		attack_area.body_entered.connect(_on_body_entered_attack)
	_update_health_bar()

func _update_visuals() -> void:
	if sprite:
		sprite.color = _data.get("color", Color(0.5, 0.35, 0.2))

# ---------------------------------------------------------------------------
# Physics
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

	match _ai_state:
		"patrol":
			_patrol(delta)
		"chase":
			_chase(delta)
		"guard":
			_guard(delta)

	move_and_slide()

	if _data.get("leaves_slime", false):
		_slime_trail_timer += delta
		if _slime_trail_timer >= SLIME_INTERVAL:
			_slime_trail_timer = 0.0
			_spawn_slime()

# ---------------------------------------------------------------------------
# AI modes
# ---------------------------------------------------------------------------
func _patrol(_delta: float) -> void:
	var speed: float = _data.get("speed", 80.0) * 0.6
	velocity.x = _patrol_dir * speed
	if is_on_wall():
		_patrol_dir *= -1
	if sprite:
		sprite.scale.x = _patrol_dir

func _chase(_delta: float) -> void:
	if not is_instance_valid(_target):
		_ai_state = "patrol"
		return
	var speed: float = _data.get("speed", 80.0)
	var dir := sign(_target.global_position.x - global_position.x)
	velocity.x = dir * speed
	if sprite:
		sprite.scale.x = dir
	# Jump to reach target if on floor and target is higher
	var jump_force: float = _data.get("jump_force", 200.0)
	if jump_force > 0 and is_on_floor() and _target.global_position.y < global_position.y - 40.0:
		velocity.y = -jump_force
	if _data.get("ranged_attack", false) and attack_cooldown.is_stopped():
		_ranged_attack()

func _guard(_delta: float) -> void:
	if not is_instance_valid(_target):
		velocity.x = 0.0
		return
	var dist := global_position.distance_to(_target.global_position)
	var speed: float = _data.get("speed", 80.0)
	if dist > 200.0:
		var dir := sign(_target.global_position.x - global_position.x)
		velocity.x = dir * speed
		if sprite:
			sprite.scale.x = dir
	else:
		velocity.x = 0.0
		if _data.get("ranged_attack", false) and attack_cooldown.is_stopped():
			_ranged_attack()

# ---------------------------------------------------------------------------
# Ranged attack
# ---------------------------------------------------------------------------
func _ranged_attack() -> void:
	if not is_instance_valid(_target):
		return
	attack_cooldown.start(randf_range(1.5, 3.0))
	var dir := (_target.global_position - global_position).normalized()
	var bullet: Node2D = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.setup(dir * 300.0, _data.get("damage", 10), true)

# ---------------------------------------------------------------------------
# Damage & death
# ---------------------------------------------------------------------------
func take_damage(amount: int) -> void:
	_health = max(0, _health - amount)
	_update_health_bar()
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1.5, 0.5, 0.5), 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if _health <= 0:
		_die()

func apply_status(status: String) -> void:
	match status:
		"poison":
			# Tick damage every second for 5 seconds
			var timer := Timer.new()
			add_child(timer)
			timer.wait_time = 1.0
			timer.autostart = true
			var ticks := 5
			timer.timeout.connect(func():
				ticks -= 1
				take_damage(5)
				if ticks <= 0:
					timer.queue_free()
			)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = _max_health
		health_bar.value = _health

func _die() -> void:
	GameState.enemies_killed += 1
	_try_drop()
	died.emit(self)
	queue_free()

func _try_drop() -> void:
	if randf() > _data.get("drop_chance", 0.3):
		return
	var drops: Array = _data.get("drops", [])
	if drops.is_empty():
		return
	var drop_id: String = drops[randi() % drops.size()]
	# Spawn a pickup at this position
	var pickup_scene := load("res://scenes/item_pickup.tscn")
	if pickup_scene:
		var pickup: Node2D = pickup_scene.instantiate()
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = global_position
		pickup.set_item(drop_id)

func _spawn_slime() -> void:
	pass  # Placeholder: spawn a hazard Area2D at current position

# ---------------------------------------------------------------------------
# Detection area callbacks
# ---------------------------------------------------------------------------
func _on_body_entered_detection(body: Node) -> void:
	if body.is_in_group("player"):
		_target = body
		_ai_state = _data.get("ai_type", "patrol")
		if _ai_state == "patrol":
			_ai_state = "chase"

func _on_body_exited_detection(body: Node) -> void:
	if body == _target:
		_target = null
		_ai_state = "patrol"
		patrol_timer.start(randf_range(1.5, 3.5))

func _on_body_entered_attack(body: Node) -> void:
	if body.is_in_group("player") and attack_cooldown.is_stopped():
		body.take_damage(_data.get("damage", 8))
		attack_cooldown.start(1.0)

# ---------------------------------------------------------------------------
# Patrol timer
# ---------------------------------------------------------------------------
func _on_patrol_timer_timeout() -> void:
	_patrol_dir *= -1
	patrol_timer.start(randf_range(1.5, 3.5))
