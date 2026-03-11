## Bullet – Area2D
## A fired projectile that travels in a direction, deals damage on contact,
## and optionally explodes or applies a status effect.
extends Area2D

# ---------------------------------------------------------------------------
# Properties set by the firing weapon
# ---------------------------------------------------------------------------
var _velocity: Vector2 = Vector2.ZERO
var _damage: int = 10
var _from_enemy: bool = false
var _explosive: bool = false
var _explosion_radius: float = 0.0
var _status_effect: String = ""
var _color: Color = Color.WHITE
var _lifetime: float = 2.0

@onready var sprite: ColorRect = $ColorRect
@onready var lifetime_timer: Timer = $LifetimeTimer

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
func setup(
	vel: Vector2,
	dmg: int,
	from_enemy: bool = false,
	explosive: bool = false,
	expl_radius: float = 0.0,
	status: String = "",
	col: Color = Color.WHITE
) -> void:
	_velocity = vel
	_damage = dmg
	_from_enemy = from_enemy
	_explosive = explosive
	_explosion_radius = expl_radius
	_status_effect = status
	_color = col
	if sprite:
		sprite.color = col
	rotation = _velocity.angle()

func _ready() -> void:
	if sprite:
		sprite.color = _color
	lifetime_timer.start(_lifetime)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	global_position += _velocity * delta

# ---------------------------------------------------------------------------
# Collision handling
# ---------------------------------------------------------------------------
func _on_body_entered(body: Node) -> void:
	if body is TileMapLayer or body.is_in_group("terrain"):
		_hit(null)
		return

	if _from_enemy and body.is_in_group("player"):
		body.take_damage(_damage)
		_hit(body)
	elif not _from_enemy and body.is_in_group("enemy"):
		body.take_damage(_damage)
		if _status_effect != "":
			body.apply_status(_status_effect)
		_hit(body)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("hazard"):
		_hit(null)

func _hit(target: Node) -> void:
	if _explosive and _explosion_radius > 0.0:
		_do_explosion()
	# Simple visual flash – in a full implementation spawn a particle effect
	queue_free()

func _do_explosion() -> void:
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _explosion_radius
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 0xFFFFFFFF
	var results := space.intersect_shape(query, 32)
	for result in results:
		var obj := result["collider"]
		if _from_enemy and obj.is_in_group("player"):
			obj.take_damage(_damage)
		elif not _from_enemy and obj.is_in_group("enemy"):
			obj.take_damage(_damage)

# ---------------------------------------------------------------------------
# Lifetime
# ---------------------------------------------------------------------------
func _on_lifetime_timer_timeout() -> void:
	queue_free()
