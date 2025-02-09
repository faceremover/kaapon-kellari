extends Node2D

@export var spit_interval: float = 3.0

@onready var anim_plr = $AnimationPlayer
@onready var voice = $voice
@onready var spitloc = $spitloc

var voice_res_rise = preload("res://audio/sfx/boss/boss_rise.ogg")
var voice_res_spit = preload("res://audio/sfx/boss/boss_spit.ogg")
var voice_res_laugh = preload("res://audio/sfx/boss/boss_laugh.ogg")
var voice_res_hit = preload("res://audio/sfx/boss/boss_hit.ogg")
var voice_res_defeated = preload("res://audio/sfx/boss/boss_defeated.ogg")
var fireball_res = preload("res://bossfireball.tscn")

var boss_active = false
var player
var target_pos = Vector2.ZERO
var start_pos = Vector2.ZERO
var spit_counter = 0
var boss_defeated = false
var boss_can_be_hit = false

func _ready() -> void:
	
	GameStateSingleton.game_state_changed.connect(_on_game_state_changed)
	hide()
	start_pos = global_position
	
	pass

func start():
	anim_plr.play("rise")
	show()
	play_voice(voice_res_rise)
	pass

func play_voice(voice_res: AudioStream):
	voice.stream = voice_res
	voice.play()
	pass

func _on_animation_player_animation_finished(anim_name:StringName) -> void:
	if anim_name == "rise":
		boss_active = true
		player = get_tree().get_first_node_in_group("Player")
		target_pos = global_position
		play_voice(voice_res_laugh)
	pass # Replace with function body.

func _process(delta: float) -> void:
	if !boss_active || !player:
		return
	
	target_pos += (player.global_position - target_pos).normalized() * delta * 100

	if target_pos.y <= 400:
		target_pos.y = 400
	if target_pos.x >= 1050:
		target_pos.x = 1050

	global_position = lerp(global_position, target_pos, delta * 2)


	spit_counter += delta

	if spit_counter >= spit_interval:
		spit_counter = 0
		play_voice(voice_res_spit)
		var fireball = fireball_res.instantiate()
		get_tree().current_scene.add_child(fireball)
		fireball.global_position = spitloc.global_position
		fireball.direction = (player.global_position - spitloc.global_position).normalized()

	pass

func _on_game_state_changed(active: bool) -> void:
	reset()
	pass

func reset():
	print("RESET BOSS")
	global_position = start_pos
	hide()
	boss_defeated = false
	boss_active = false
	boss_can_be_hit = false
	pass


func _on_area_2d_body_entered(body:Node2D) -> void:
	if body.is_in_group("Player") && boss_can_be_hit && global_position.y <= 500 && boss_active && global_position.x >= 950:
		boss_active = false
		play_voice(voice_res_defeated)
		GameStateSingleton.add_score(250)
		boss_defeated = true
		hide()

		
	pass # Replace with function body.
