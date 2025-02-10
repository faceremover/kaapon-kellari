extends CharacterBody2D

# Action states enum - used as a reference, helps with code clarity
enum ACTION { NONE, IDLE, RUNNING, JUMPING, FALLING, LANDING }

# Group 1: Movement 1
@export_category("Movement")
@export_range(0, 2000) var move_speed := 1000.0
@export_range(0, 50) var acceleration := 15.0
@export_range(0, 50) var deceleration := 10.0
@export_range(0, 500) var jump_height := 150.0
@export_range(0, 2000) var gravity := 980.0
@export var input_left := "move_left"
@export var input_right := "move_right"
@export var input_jump := "jump"

# Group 2: Movement 2
@export_category("+Movement")
@export_range(0, 1) var mid_air_friction := 0.6
@export_range(0, 20) var step_height := 9
@export_range(0, 0.2) var jump_buffer_time := 0.1
@export_range(0, 0.2) var coyote_time := 0.04

# Group 3: Movement SFX
@export_category("Movement SFX")
@export var runAudio: AudioStreamPlayer2D
@export var jumpAudio: AudioStreamPlayer2D
@export var landAudio: AudioStreamPlayer2D
@export var wall_bounce_audio: AudioStreamPlayer2D
@export_range(0, 5) var land_volume_multiplier := 2.0

# Group 4: Visual
@export_category("Visual")
@export var anim: AnimatedSprite2D
@export var camera: Node2D
@export_range(0, 1) var camera_smoothing := 0.3
@export_range(0, 2) var camera_prediction_h := 0.85
@export_range(0, 2) var camera_prediction_v := 0.5
@export_range(0, 300) var max_camera_offset := 160.0

# Group 5: Momentum
@export_category("Momentum")
@export_range(0, 5) var momentum_build_time := 1.2
@export_range(0, 1000) var max_momentum_bonus := 400.0

# Group 6: Hyper
@export_category("Hyper")
@export var smoke_particles: GPUParticles2D
@export_range(0.5, 1.0) var smoke_threshold := 0.7
@export_range(1, 50) var min_smoke_amount := 5
@export_range(10, 100) var max_smoke_amount := 30
@export_range(0.1, 1.0) var min_smoke_ratio := 0.3
@export_range(1.0, 3.0) var max_smoke_ratio := 1.5
@export var hyper_particles: GPUParticles2D
@export var hyper_explosion_particles: GPUParticles2D
@export var hyper_ignition_audio: AudioStreamPlayer2D
@export var hyper_audio: AudioStreamPlayer2D
# Added hyper_light export for the light in hyper mode
@export var hyper_light: Light2D
@export var hyper_scale_light: Light2D  # New light that will scale during hyper mode

var smoothed_velocity := Vector2.ZERO
var camera_target_pos := Vector2.ZERO 

var coyote_time_counter := 0.0
var jump_buffer_counter := 0.0
var current_speed := 0.0
var was_on_floor := false
var is_landing := false
var previous_animation := ""
var cached_transform: Transform2D
var move_transform: Transform2D

var jump_velocity: float

var run_build_timer := 0.0
var is_hyper_mode := false
var was_hyper_mode := false

var is_smoking := false
var was_smoking := false

var hyper_duration := 0.0
var score_timer := 0.0

func _ready() -> void:
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
		anim.frame_changed.connect(_on_frame_changed)
	cached_transform = global_transform
	move_transform = Transform2D()
	
	jump_velocity = sqrt(2.0 * gravity * jump_height)
	
	# Disable hyper-related effects at start
	if smoke_particles:
		smoke_particles.emitting = false
	if hyper_particles:
		hyper_particles.emitting = false
	if hyper_explosion_particles:
		hyper_explosion_particles.emitting = false
	if hyper_audio:
		hyper_audio.stop()
	if hyper_light:
		hyper_light.energy = 0.0
	if hyper_scale_light:
		hyper_scale_light.texture_scale = 1.0
		hyper_scale_light.height = 30.0  # Normal height
	
	if hyper_audio:
		hyper_audio.volume_db = -80
		hyper_audio.play()

func _on_animation_finished() -> void:
	if anim.animation == "land":
		is_landing = false
	elif anim.animation == "run" && runAudio && !runAudio.playing:
		runAudio.play()

func _on_frame_changed() -> void:
	if anim.animation == "run" && anim.frame == 1 && runAudio && !runAudio.playing:
		runAudio.play()

func _physics_process(delta: float) -> void:
	cached_transform = global_transform  
	var is_on_floor_now := is_on_floor()
	var input_direction := Input.get_axis(input_left, input_right)
	
	_handle_movement(delta, input_direction, is_on_floor_now)
	_handle_jump(delta, is_on_floor_now)
	_handle_step_assist(input_direction, is_on_floor_now)
	_handle_animation(input_direction, is_on_floor_now)
	_handle_hyper_mode()
	_update_camera(delta)
	
	was_on_floor = is_on_floor_now
	move_and_slide()

func _handle_movement(delta: float, input_direction: float, is_on_floor_now: bool) -> void:
	var speed_sign = sign(current_speed)
	var input_sign = sign(input_direction)
	
	if is_on_floor_now:
		if speed_sign != 0 and input_sign != 0 and speed_sign != input_sign:
			run_build_timer = 0.0
			current_speed *= 0.6
		elif input_direction != 0 and speed_sign == input_sign:
			run_build_timer += delta
		else:
			run_build_timer = 0.0
	
	var ramp = clamp(run_build_timer / momentum_build_time, 0.0, 1.0)
	var desired_speed = input_direction * (move_speed + max_momentum_bonus * ramp)
	
	var accel_amount := acceleration
	if abs(desired_speed) < abs(current_speed) or (is_on_floor_now and speed_sign != 0 and input_sign != 0 and speed_sign != input_sign):
		accel_amount = deceleration * 1.5
	if !is_on_floor_now:
		accel_amount *= mid_air_friction
	
	var raw_speed = move_toward(current_speed, desired_speed, accel_amount * move_speed * delta)
	current_speed = lerp(current_speed, raw_speed, 0.25)
	
	if is_on_wall():
		for i in range(get_slide_collision_count()):
			var can_step = false
			for j in range(1, step_height + 1):
				var step_up := Vector2(0, -j)
				var step_dir := Vector2(speed_sign, 0)
				if !test_move(transform, step_up) and !test_move(transform.translated(step_up), step_dir):
					can_step = true
					break

			if can_step:
				desired_speed *= 0.6
				current_speed *= 0.6
			else:
				# Bounce or stop
				if abs(current_speed) >= move_speed + max_momentum_bonus * 0.1:
					current_speed *= -0.6
					desired_speed = current_speed
					if wall_bounce_audio:
						wall_bounce_audio.play()
				else:
					current_speed = 0.0
					desired_speed = 0.0
			break

	velocity.x = current_speed
	velocity.y += gravity * delta

func _handle_jump(delta: float, is_on_floor_now: bool) -> void:
	if is_on_floor_now:
		coyote_time_counter = coyote_time
	else:
		coyote_time_counter -= delta
		
	if Input.is_action_just_pressed(input_jump):
		jump_buffer_counter = jump_buffer_time
	
	if (is_on_floor_now || coyote_time_counter > 0.0) && jump_buffer_counter > 0.0:
		velocity.y = -jump_velocity
		coyote_time_counter = 0.0
		jump_buffer_counter = 0.0
		if jumpAudio:
			jumpAudio.play()
	
	jump_buffer_counter -= delta

func _handle_step_assist(input_direction: float, is_on_floor_now: bool) -> void:
	if !is_on_floor_now || input_direction == 0.0:
		return
		
	var dir: float = sign(input_direction)
	var movement := Vector2(dir, 0)
	
	if test_move(transform, movement):
		for i in range(1, step_height + 1):
			var step_up := Vector2(0, -i)
			
			if !test_move(transform, step_up) && !test_move(transform.translated(step_up), movement):
				move_and_collide(step_up)
				move_and_collide(movement)
				break

func _handle_animation(input_direction: float, is_on_floor_now: bool) -> void:
	if !anim:
		return
		
	var new_animation := ""
	var movement_speed: float = abs(current_speed)
	var MIN_MOVE_THRESHOLD := 27.0
	
	if is_on_floor_now && !was_on_floor:
		new_animation = "land"
		anim.speed_scale = 1.0
		is_landing = true
		if landAudio:
			landAudio.play()
	elif !is_on_floor_now && !is_landing:
		new_animation = "jump"
		anim.speed_scale = 1.0
	elif movement_speed > MIN_MOVE_THRESHOLD && !is_landing:
		new_animation = "run"
		var total_speed = movement_speed
		anim.speed_scale = clamp(pow(0.1 + total_speed / (move_speed + max_momentum_bonus), 1.3), 0.0, 1.0)
	elif !is_landing:
		new_animation = "idle"
		anim.speed_scale = 1.0
	
	if runAudio && previous_animation == "run" && new_animation == "idle" && anim.frame == 0:
		runAudio.play()
	
	previous_animation = new_animation
	anim.play(new_animation)
	
	if input_direction != 0:
		anim.scale.x = sign(input_direction)

func _update_camera(delta: float) -> void:
	if !camera:
		return
	
	smoothed_velocity = smoothed_velocity.lerp(velocity, 10.0 * delta)
	
	var prediction := Vector2(
		smoothed_velocity.x * camera_prediction_h,
		smoothed_velocity.y * camera_prediction_v
	)
	
	if prediction.length() > max_camera_offset:
		prediction = prediction.normalized() * max_camera_offset
	
	camera_target_pos = global_position + prediction
	
	camera.global_position = camera.global_position.lerp(
		camera_target_pos, 
		1.0 - exp(-camera_smoothing * 5.0 * delta)
	)
	
	var max_possible_speed = move_speed + max_momentum_bonus
	var current_speed_ratio = abs(current_speed) / max_possible_speed
	
	if current_speed_ratio >= smoke_threshold:
		var shake_intensity = inverse_lerp(smoke_threshold, 0.95, current_speed_ratio)
		var shake_magnitude = 3.0 * shake_intensity # Max 3px shake
		camera.global_position += Vector2(
			randf_range(-shake_magnitude, shake_magnitude),
			randf_range(-shake_magnitude, shake_magnitude)
		)

func _handle_hyper_mode() -> void:
	var max_possible_speed = move_speed + max_momentum_bonus
	var current_speed_ratio = abs(current_speed) / max_possible_speed
	
	is_smoking = current_speed_ratio >= smoke_threshold
	is_hyper_mode = current_speed_ratio >= 0.95
	
	# Track hyper duration and score
	if is_hyper_mode:
		hyper_duration += get_physics_process_delta_time()
		if hyper_duration >= 1.0:  # After 1 second of continuous hyper
			score_timer += get_physics_process_delta_time()
			if score_timer >= 0.3:  # Add score every 0.3 seconds
				GameStateSingleton.add_score(1)
				score_timer = 0.0
	else:
		hyper_duration = 0.0
		score_timer = 0.0
	
	if smoke_particles:
		if is_smoking:
			smoke_particles.emitting = true
			var smoke_intensity = inverse_lerp(smoke_threshold, 0.95, current_speed_ratio)
			smoke_particles.amount_ratio = lerp(min_smoke_ratio, max_smoke_ratio, smoke_intensity)
		else:
			smoke_particles.emitting = false
	
	if is_hyper_mode != was_hyper_mode:
		if is_hyper_mode:
			if hyper_particles:
				hyper_particles.emitting = true
			if hyper_explosion_particles:
				hyper_explosion_particles.restart()
			if hyper_ignition_audio:
				hyper_ignition_audio.play()
		else:
			if hyper_particles:
				hyper_particles.emitting = false
	
	if hyper_audio:
		var volume_intensity = 0.0
		if current_speed_ratio >= smoke_threshold:
			volume_intensity = inverse_lerp(smoke_threshold, 0.95, current_speed_ratio)
		hyper_audio.volume_db = linear_to_db(volume_intensity) + 3
	
	# Toggle hyper_light on hyper mode state change
	if hyper_light and is_hyper_mode != was_hyper_mode:
		if is_hyper_mode:
			hyper_light.energy = 1.0
		else:
			hyper_light.energy = 0.0
			
	# Add scaling and height effect for the second light
	if hyper_scale_light:
		var scale_target = 1.0
		var height_target = 30.0  # Normal height
		if current_speed_ratio >= smoke_threshold:
			var t = inverse_lerp(smoke_threshold, 0.95, current_speed_ratio)
			scale_target = lerp(1.0, 1.5, t)
			height_target = lerp(30.0, 18.0, t)  # Lerp from normal to hyper height
		hyper_scale_light.texture_scale = lerp(hyper_scale_light.texture_scale, scale_target, 0.1)
		hyper_scale_light.height = lerp(hyper_scale_light.height, height_target, 0.1)
	
	was_smoking = is_smoking
	was_hyper_mode = is_hyper_mode
