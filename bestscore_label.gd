extends Label

func _process(_delta: float) -> void:

	text = "Best Score: " + str(GameStateSingleton.highscore)

	pass
