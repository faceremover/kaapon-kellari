extends Label

@onready var anim_plr = $AnimationPlayer

func _ready() -> void:

    hide()

    pass

func show_effect():
    show()

    anim_plr.play("highscore")

    pass