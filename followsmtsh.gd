extends Node2D

# Target node to follow
@export var target_path: NodePath
# Speed of interpolation
@export var follow_speed: float = 5.0

# Internal reference to the target node
var target: Node2D

func _ready() -> void:
    if target_path:
        target = get_node(target_path) as Node2D

func _process(delta: float) -> void:
    if target:
        # Interpolate position
        position = position.lerp(target.position, follow_speed * delta)
        
        # Interpolate rotation
        rotation = lerp_angle(rotation, target.rotation, follow_speed * delta)