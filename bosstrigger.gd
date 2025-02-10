extends Area2D

@onready var boss_gate = $"../BossGate"
@onready var boss = $"../Boss"
@onready var sprite = $trapcollectible
@onready var collectsfx = $collect

func _on_body_entered(body:Node2D) -> void:
	if body.is_in_group("Player") && !boss.boss_active && sprite.visible:
		boss.start()
		boss_gate.toggle_boss_gate()
		sprite.hide()
		collectsfx.play()
		GameStateSingleton.add_score(250)

	pass # Replace with function body.

func _ready():
	GameStateSingleton.game_state_changed.connect(_on_game_state_changed)
	pass

func _on_game_state_changed(_active : bool) -> void:
	sprite.show()
	pass
