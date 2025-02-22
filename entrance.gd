extends Node2D

@export_file("*.tscn") var next_scene: String = ""

var original_music_volume: float = 0.0
@onready var animation_player: AnimationPlayer = $CanvasLayer/Control/TextureRect/AnimationPlayer
@onready var video_stream_player: VideoStreamPlayer = $CanvasLayer/Control/VideoStreamPlayer
@onready var video_stream_player_anim: AnimationPlayer = $CanvasLayer/Control/VideoStreamPlayer/AnimationPlayer

var loading_scene = false

func _ready() -> void:

	var music_bus = AudioServer.get_bus_index("music")
	original_music_volume = AudioServer.get_bus_volume_db(music_bus)
	AudioServer.set_bus_volume_db(music_bus, -80.0)

	animation_player.animation_finished.connect(_on_animation_finished)

	for music_player in MusicFader.stream_players:
		music_player.stop()

	pass

func _process(delta: float) -> void:

	if loading_scene && ResourceLoader.load_threaded_get_status(next_scene) == ResourceLoader.THREAD_LOAD_LOADED:
		loading_scene = false
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(next_scene))

	pass

func _exit_tree() -> void:


	pass

func _on_animation_finished(anim_name: String) -> void:

	video_stream_player.play()
	video_stream_player.finished.connect(_on_video_finished)
	video_stream_player_anim.play("fadein")
	
	pass

func _on_video_finished() -> void:

	loading_scene = true

	for music_player in MusicFader.stream_players:
		music_player.play()

	ResourceLoader.load_threaded_request(next_scene)
	var music_bus = AudioServer.get_bus_index("music")
	AudioServer.set_bus_volume_db(music_bus, original_music_volume)

	pass
