extends Camera2D

@export var target: Node2D
@export var look_ahead_distance: float = 100.0
@export var camera_smoothing_speed: float = 5.0

func _process(delta):
    if target:
        var velocity = target.get("velocity") # Assuming the target has a 'velocity' property
        if velocity.length() > 0:
            var future_position = target.global_position + velocity.normalized() * look_ahead_distance
            global_position = global_position.lerp(future_position, delta * camera_smoothing_speed)