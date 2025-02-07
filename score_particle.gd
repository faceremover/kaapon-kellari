extends Label

@export var points: int
@export var move_speed: float = 5.0
@export var initial_thrust: float = 100.0  # Initial random thrust
@export var thrust_decay: float = 2.0  # How fast the thrust decays

signal score_reached(points: int)

var velocity: Vector2
var thrust_velocity: Vector2
var target_position: Vector2

func _ready() -> void:
	text = str(points)
	# Set target position to the upper right corner
	target_position = Vector2(get_viewport().size.x, 0)
	# Apply initial random thrust
	var angle = randf_range(0, 2 * PI)
	thrust_velocity = Vector2(cos(angle), sin(angle)) * initial_thrust
	set_process(true)

func _process(delta: float) -> void:
	# Apply thrust decay
	thrust_velocity = thrust_velocity.lerp(Vector2.ZERO, delta * thrust_decay)
	# Gradually increase speed towards the target
	var direction = (target_position - position).normalized()
	velocity += direction * move_speed * delta
	position += (velocity + thrust_velocity) * delta
	if position.distance_to(target_position) < 10.0:
		emit_signal("score_reached", points)
		queue_free()
