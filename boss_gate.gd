extends StaticBody2D

@onready var anim_plr : AnimationPlayer = $AnimationPlayer
@onready var collision = $CollisionShape2D
@onready var boss = $"../Boss"

var closed = false

func _ready() -> void:
	collision.disabled = true
	GameStateSingleton.game_state_changed.connect(_on_game_state_change)
	pass

func toggle_boss_gate():
	closed = !closed

	if closed:
		anim_plr.play("gatedown")
	else:
		anim_plr.play_backwards("gatedown")

	collision.call_deferred("set_disabled", !closed)

	pass

func _process(delta: float) -> void:
	if boss.boss_defeated && closed:
		toggle_boss_gate()

	pass

func _on_game_state_change(active: bool) -> void:
	reset()
	pass

func reset():
	if closed:
		toggle_boss_gate()
	pass
