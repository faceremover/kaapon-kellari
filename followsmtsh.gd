extends Node2D

@export var target_path: NodePath
@export var follow_speed_x: float = 5.0
@export var follow_speed_y: float = 5.0

var target: Node2D

func _ready() -> void:
    if target_path:
        target = get_node(target_path) as Node2D

func _process(delta: float) -> void:
    if target:
        var new_position = position
        new_position.x = position.x + (target.position.x - position.x) * follow_speed_x * delta
        new_position.y = position.y + (target.position.y - position.y) * follow_speed_y * delta
        
        position = new_position