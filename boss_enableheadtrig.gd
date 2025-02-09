extends Area2D

@onready var boss = $"../Boss"



func _on_body_entered(body:Node2D) -> void:
	if body.is_in_group("Player") && boss.boss_active:
		boss.boss_can_be_hit = true
		

	pass # Replace with function body.
