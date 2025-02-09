extends Area2D

@export var lifetime: float = 16.0

var direction = Vector2.UP

var counter = 0

func _ready() -> void:

	GameStateSingleton.game_state_changed.connect(_on_game_state_changed)

	pass

func _on_game_state_changed(active: bool) -> void:
	if !active:
		queue_free()

func _on_body_entered(body:Node2D) -> void:
	if body.is_in_group("Player"):
		if GameStateSingleton.score >= 100:
			GameStateSingleton.remove_score(15)
			queue_free()
	pass # Replace with function body.

func _process(delta: float) -> void:

	global_position += direction * delta * 35

	counter += delta

	if counter >= lifetime:
		queue_free()

	pass