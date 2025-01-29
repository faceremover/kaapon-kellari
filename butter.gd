extends Node2D

@export var target1: Node2D
@export_range(0.0, 1.0) var weight: float = 0.5

func _process(_delta):
	if target1:
		var canvas = get_canvas_transform()
		var viewport_center = -canvas.origin + get_viewport_rect().size / 2
		var global_target_position = target1.get_global_position()
		position = global_target_position.lerp(viewport_center, weight)
