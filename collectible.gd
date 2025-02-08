extends Area2D

@export var score_value:int = 10
@export_file("*.png") var possible_textures: Array[String] = []

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var collect_sound : AudioStreamPlayer2D = $collect
@onready var sprite : Sprite2D = $Sprite2D

var collected = false
var collect_anim_finished = false

func _ready() -> void:

	if possible_textures.size() > 0:
		var texture_index = randi() % possible_textures.size()
		sprite.texture = load(possible_textures[texture_index])

	pass

func _on_body_entered(body:Node2D) -> void:
	if body.is_in_group("Player") && !collected:
		GameStateSingleton.add_score(score_value)
		animation_player.play("collect")
		collected = true
		collect_sound.play()

	pass # Replace with function body.

func _process(delta: float) -> void:

	if collect_anim_finished && collected && !collect_sound.playing:
		queue_free()

	pass

func _on_animation_player_animation_finished(anim_name:StringName) -> void:
	if collected:
		collect_anim_finished = true
	pass # Replace with function body.
