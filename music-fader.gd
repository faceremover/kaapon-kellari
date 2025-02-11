extends Node

@export var stream_players: Array[AudioStreamPlayer]
@export var fade_duration: float = 4.0

var is_fading: bool = false
var fade_time: float = 0.0
var fade_from: int = 0
var fade_to: int = 0
var current_stream: int = 0
var base_volumes: Array[float] = []
var global_pitch: float = 1.0
var global_pitch_target := 1.0

func _ready():
	if !stream_players.is_empty():
		# Store original volumes for each player
		for player in stream_players:
			if player:
				base_volumes.append(player.volume_db)
				player.play()
				player.volume_db = -80.0
		stream_players[0].volume_db = base_volumes[0]

func _process(delta):
	for player in stream_players:
		if player:
			player.pitch_scale = global_pitch

	global_pitch = lerp(global_pitch, global_pitch_target, delta * 1.0)

	if !is_fading or stream_players.is_empty(): return
	
	fade_time = min(fade_time + delta, fade_duration)
	_update_volumes()
	
	if fade_time >= fade_duration:
		is_fading = false

func set_global_pitch(pitch : float, instant : bool = false):
	global_pitch_target = pitch
	if instant:
		global_pitch = pitch

func fade_to_stream(stream_number: int):
	if stream_number >= stream_players.size() or stream_number == current_stream: return
	
	fade_from = current_stream
	fade_to = stream_number
	current_stream = stream_number
	fade_time = 0.0
	is_fading = true

func _update_volumes():
	var t = fade_time / fade_duration
	for i in stream_players.size():
		var vol = -80.0
		if i == fade_to:
			vol = linear_to_db(t) + base_volumes[i]
		elif i == fade_from:
			vol = linear_to_db(1.0 - t) + base_volumes[i]
		stream_players[i].volume_db = vol

