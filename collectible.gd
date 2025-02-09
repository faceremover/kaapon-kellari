extends Area2D

@export var score_value:int = 10
@export_file("*.png") var possible_textures: Array[String] = []

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var collect_sound : AudioStreamPlayer2D = $collect
@onready var sprite : Sprite2D = $Sprite2D
@onready var light : PointLight2D = $PointLight2D
@onready var particles : GPUParticles2D = $GPUParticles2D

var collected = false
var collect_anim_finished = false
var initial_light_energy : float

func _ready() -> void:

	if possible_textures.size() > 0:
		var texture_index = randi() % possible_textures.size()
		sprite.texture = load(possible_textures[texture_index])
	
	initial_light_energy = light.energy

func _on_body_entered(body:Node2D) -> void:
	if body.is_in_group("Player") && !collected:
		collected = true
		animation_player.play("collect")
		collect_sound.play()
		flash()
		await get_tree().create_timer(0.4).timeout
		GameStateSingleton.add_score(score_value)

func flash() -> void:
	particles.restart()
	light.energy = 1.0
	var tween = create_tween()
	tween.tween_property(light, "energy", 0.0, 0.4)

func _process(_delta: float) -> void:
	if collect_anim_finished && collected && !collect_sound.playing:
		queue_free()

func _on_animation_player_animation_finished(_anim_name:StringName) -> void:
	if collected:
		collect_anim_finished = true
