extends Node2D

@export var target_path: NodePath
@export var snap_grid_size: int = 2
@export var updates_per_second: int = 5

var time_accumulator = 0.0

func _ready():
	snap_to_grid()

func _process(delta):
	time_accumulator += delta
	if time_accumulator >= 1.0 / updates_per_second:
		time_accumulator = 0.0
		snap_to_grid()

func snap_to_grid():
	if target_path:
		var target_node = get_node(target_path)
		if target_node and target_node is Node2D:
			var pos = target_node.position
			var snapped_pos = Vector2(round(pos.x / snap_grid_size) * snap_grid_size, round(pos.y / snap_grid_size) * snap_grid_size)
			if position != snapped_pos:
				position = snapped_pos
