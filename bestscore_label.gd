extends Label

func _process(delta: float) -> void:

	text = "Best Score: " + str(GameStateSingleton.highscore)

	pass
