extends Area2D

@export var countdown_duration: float = 5.0
@export var timer_label: Label
@export var player: CharacterBody2D
@export var score: Label
@export var camera: Camera2D
@export var start_sound: AudioStreamPlayer2D
@export var alert_sound: AudioStreamPlayer2D
@export var finish_sound: AudioStreamPlayer2D
@export var timeout_sound: AudioStreamPlayer2D

signal game_state_changed(new_state: bool)
signal time_updated(time_text: String)

var game_active := false
var alert_active := false
var flash_time := 0.0
var cool_reset_active := false
var last_second := -1
var shake_offset := Vector2.ZERO
var base_timer_position := Vector2.ZERO
var original_camera_speed := 1.0
var timer: Timer
var start_collectible_locs: Array = []
var player_base_volume: float = 0.0

var collectible_ref := preload("res://collectible.tscn")

func _ready():
	# Ensure monitoring is enabled before setting up
	monitoring = true
	monitorable = true

	var start_collectibles = get_tree().get_nodes_in_group("Collectible")
	for collectible in start_collectibles:
		start_collectible_locs.append(collectible.global_position)

	# Create and configure the timer.
	timer = Timer.new()
	timer.wait_time = countdown_duration
	timer.one_shot = true
	timer.autostart = false
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(timer)
	
	# Use deferred connections for area signals
	connect("body_exited", Callable(self, "_on_body_exited"), CONNECT_DEFERRED)
	connect("body_entered", Callable(self, "_on_body_entered"), CONNECT_DEFERRED)
	
	# Connect the time_updated signal to update timer_label text.
	if timer_label:
		connect("time_updated", Callable(timer_label, "set_text"))
		base_timer_position = timer_label.position
	
	# When player spawns in area: timer is at 0 (hidden) and score is visible.
	game_active = false
	emit_signal("game_state_changed", game_active)
	if timer_label:
		timer_label.visible = false
	if score:
		score.set_game_active(game_active)
		GameStateSingleton.reset_score()
	if camera:
		original_camera_speed = camera.position_smoothing_speed
	if alert_sound:
		player_base_volume = alert_sound.volume_db

func _process(_delta: float) -> void:
	if timer and not timer.is_stopped() and timer_label:
		var time_remaining = timer.time_left
		var current_second = int(time_remaining)
		var time_text = "%d:%02d" % [int(time_remaining / 60), int(time_remaining) % 60]
		emit_signal("time_updated", time_text)
		
		 # Handle special effects near start
		if time_remaining >= countdown_duration - 0.5:
			_apply_camera_shake(time_remaining)
		# Alert phase
		elif time_remaining <= 15.0:
			_handle_alert(time_remaining, current_second)
		else:
			_reset_display()

func _apply_camera_shake(time_remaining: float) -> void:
	var elapsed = countdown_duration - time_remaining
	var shake_intensity = 10.0 * (0.5 - elapsed)
	if camera:
		camera.position_smoothing_speed = 100.0 * (0.5 - elapsed) + original_camera_speed
	shake_offset = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
	if camera:
		camera.offset = Vector2(
			randf_range(-shake_intensity * .7, shake_intensity * .7),
			randf_range(-shake_intensity * .7, shake_intensity * .7)
		)
	timer_label.position = base_timer_position + shake_offset

func _handle_alert(time_remaining: float, current_second: int) -> void:
	if camera:
		var alert_intensity = (15.0 - time_remaining) / 15.0
		camera.position_smoothing_speed = 15.0 * alert_intensity + original_camera_speed
	if not alert_active:
		alert_active = true
	
	if current_second != last_second and alert_sound:
		alert_sound.play()
		# Start at -10db and scale to player_base_volume using a reversed exponential curve
		var volume_scale = (15.0 - time_remaining) / 15.0
		volume_scale = 1 - pow(1 - volume_scale, 2)  # Apply reversed exponential curve
		alert_sound.volume_db = -10.0 + (volume_scale * (10.0 + player_base_volume))
		last_second = current_second
		var red_intensity = (15.0 - time_remaining) / 15.0
		timer_label.modulate = Color(1.0, 1.0 - red_intensity, 1.0 - red_intensity)
		var flash_timer = get_tree().create_timer(0.1)
		flash_timer.connect("timeout", Callable(self, "_reset_timer_color"))
	
	var shake_intensity = (15.0 - time_remaining) * 0.15
	shake_offset = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
	if camera:
		camera.offset = Vector2(
			randf_range(-shake_intensity * .9, shake_intensity * .9),
			randf_range(-shake_intensity * .9, shake_intensity * .9)
		)
	timer_label.position = base_timer_position + shake_offset

func _reset_display() -> void:
	timer_label.position = base_timer_position
	if camera:
		camera.offset = Vector2.ZERO
		camera.position_smoothing_speed = original_camera_speed

func _reset_timer_color() -> void:
	if timer_label:
		timer_label.modulate = Color.WHITE

func _reset_camera() -> void:
	if camera:
		camera.offset = Vector2.ZERO
		camera.position_smoothing_speed = original_camera_speed

func _on_body_exited(body: CharacterBody2D) -> void:
	if body == player:
		# Defer the state changes
		call_deferred("_handle_body_exit")

func _handle_body_exit() -> void:
	cancel_cool_reset()
	game_active = true
	alert_active = false
	last_second = -1
	flash_time = 0
	if start_sound:
		start_sound.play()
	
	emit_signal("game_state_changed", game_active)
	if score:
		score.set_game_active(game_active)
		GameStateSingleton.reset_score()
	timer.start()
	if timer_label:
		timer_label.visible = true

func _on_timer_timeout() -> void:
	if timeout_sound:
		timeout_sound.play()
	alert_active = false
	if timer_label:
		timer_label.modulate = Color.WHITE
		timer_label.position = base_timer_position
	_reset_camera()
	if score:
		GameStateSingleton.halve_score()
	if player:
		player.global_position = Vector2.ZERO
	if timer_label:
		timer_label.visible = false

func _on_body_entered(body: Node) -> void:
	if body == player:
		# Defer the state changes
		call_deferred("_handle_body_enter")

func _handle_body_enter() -> void:
	alert_active = false
	_reset_camera()
	
	var all_collectibles = get_tree().get_nodes_in_group("Collectible")
	for collectible in all_collectibles:
		collectible.queue_free()
	
	# Defer collectible creation to the next frame
	call_deferred("_spawn_collectibles")
	
	if timer and not timer.is_stopped():
		_cool_reset_sequence()
	else:
		game_active = false
		emit_signal("game_state_changed", game_active)
		if score:
			score.set_game_active(game_active)
		timer.stop()
		if timer_label:
			timer_label.visible = false

func _spawn_collectibles() -> void:
	for collectible_pos in start_collectible_locs:
		var collectible = collectible_ref.instantiate()
		collectible.global_position = collectible_pos
		get_tree().current_scene.add_child(collectible)

func _cool_reset_sequence() -> void:
	var seconds_remaining = int(timer.time_left)
	timer.stop()
	if finish_sound:
		finish_sound.play()
	game_active = false
	emit_signal("game_state_changed", game_active)
	if score:
		score.set_game_active(true)
	await async_cool_reset(seconds_remaining)
	if !cool_reset_active:
		return
	if score:
		score.set_game_active(false)
	if timer_label:
		timer_label.visible = false

func cancel_cool_reset() -> void:
	cool_reset_active = false
	if timer_label:
		timer_label.visible = false

func async_cool_reset(seconds_remaining: int) -> void:
	cool_reset_active = true
	const TOTAL_DURATION := 1.3
	var total_points = seconds_remaining
	var delay = TOTAL_DURATION / total_points if total_points > 0 else TOTAL_DURATION
	for i in range(total_points):
		if !cool_reset_active:
			break
		if score:
			GameStateSingleton.add_score(1)
		if timer_label and is_instance_valid(timer_label):
			var points_left = total_points - i - 1
			var time_left = int(ceil(float(points_left)))
			timer_label.text = "%d:%02d" % [int(time_left / 60.0), time_left % 60]
		await get_tree().create_timer(delay).timeout
