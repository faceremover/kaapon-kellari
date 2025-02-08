extends Node2D

@export var stream_player_1: AudioStreamPlayer2D
@export var stream_player_2: AudioStreamPlayer2D
@export var fade_duration: float = 4.0 # seconds
@export var current_stream: int = 1:
	set = _set_current_stream
@export var auto_switch: bool = false

var is_fading: bool = false
var fade_time: float = 0.0

func _ready():
	if !stream_player_1 or !stream_player_2:
		push_error("Music fader: Stream players not properly assigned!")
		return
		
	stream_player_1.play()
	stream_player_2.play()
	update_volumes()

func _process(delta):
	if !stream_player_1 or !stream_player_2 or !is_fading:
		return
		
	fade_time += delta
	if fade_time >= fade_duration:
		fade_time = fade_duration
		is_fading = false
		if auto_switch:
			fade_to_stream(3 - current_stream)  # Toggle between 1 and 2
	
	var t = fade_time / fade_duration
	if current_stream == 1:
		stream_player_1.volume_db = linear_to_db(t)
		stream_player_2.volume_db = linear_to_db(1 - t)
	else:
		stream_player_1.volume_db = linear_to_db(1 - t)
		stream_player_2.volume_db = linear_to_db(t)

func fade_to_stream(stream_number: int):
	if stream_number == current_stream or is_fading:
		return
	current_stream = stream_number
	fade_time = 0.0
	is_fading = true

func update_volumes():
	if !stream_player_1 or !stream_player_2:
		return
		
	if current_stream == 1:
		stream_player_1.volume_db = 0
		stream_player_2.volume_db = -80
	else:
		stream_player_1.volume_db = -80
		stream_player_2.volume_db = 0

func _set_current_stream(value: int):
	current_stream = value
	fade_to_stream(value)

func _on_area_2d_game_state_changed(new_state:bool):
	# Toggle between streams when button is pressed
	if new_state == true:
		fade_to_stream(1)
	else:
		fade_to_stream(2)
	#debug
	print("Current stream: ", current_stream)
