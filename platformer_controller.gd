extends CharacterBody2D

# Action states enum - used as a reference, helps with code clarity
enum ACTION { NONE, IDLE, RUNNING, JUMPING, FALLING, LANDING }

# Export variables with hints for better tuning
@export_range(0, 2000) var move_speed := 1000.0
@export_range(0, 500) var jump_height := 150.0  # Maximum jump height in pixels
@export_range(0, 50) var acceleration := 15.0
@export_range(0, 50) var deceleration := 10.0
@export_range(0, 2000) var gravity := 980.0
@export var input_left := "move_left"
@export var input_right := "move_right"
@export var input_jump := "jump"
@export_range(0, 20) var step_height := 9
@export_range(0, 0.2) var coyote_time := 0.04
@export_range(0, 0.2) var jump_buffer_time := 0.1
@export var anim: AnimatedSprite2D
@export var camera: Node2D
@export var jumpAudio: AudioStreamPlayer2D
@export var landAudio: AudioStreamPlayer2D
@export var runAudio: AudioStreamPlayer2D
@export_range(0, 5) var land_volume_multiplier := 2.0
@export_range(0, 1) var mid_air_friction := 0.6
@export var wall_bounce_audio: AudioStreamPlayer2D  # Add wall bounce sound

# Momentum settings
@export_range(0, 1000) var max_momentum_bonus := 400.0  # Maximum additional speed from momentum
@export_range(0, 5) var momentum_build_time := 1.2      # Time at max speed before momentum builds

# Camera follow settings
@export_range(0, 1) var camera_smoothing := 0.05
@export_range(0, 2) var camera_prediction_h := 0.85  # Horizontal prediction
@export_range(0, 2) var camera_prediction_v := 0.5   # Vertical prediction (usually lower)
@export_range(0, 300) var max_camera_offset := 160.0 # Max distance camera can move from player
var smoothed_velocity := Vector2.ZERO

# Cached values for better performance
var coyote_time_counter := 0.0
var jump_buffer_counter := 0.0
var current_speed := 0.0
var was_on_floor := false
var is_landing := false
var previous_animation := ""
var cached_transform: Transform2D
var move_transform: Transform2D

# Add these variables for calculated jump properties
var jump_velocity: float

# Add to cached values section
var run_build_timer := 0.0

func _ready() -> void:
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
		anim.frame_changed.connect(_on_frame_changed)
	cached_transform = global_transform
	move_transform = Transform2D()
	
	# Calculate jump velocity from height and gravity (v = √(2gh))
	jump_velocity = sqrt(2.0 * gravity * jump_height)

func _on_animation_finished() -> void:
	if anim.animation == "land":
		is_landing = false
	elif anim.animation == "run" && runAudio && !runAudio.playing:
		runAudio.play()

func _on_frame_changed() -> void:
	if anim.animation == "run" && anim.frame == 1 && runAudio && !runAudio.playing:
		runAudio.play()

func _physics_process(delta: float) -> void:
	# Update cached_transform to the current global_transform for proper stepping
	cached_transform = global_transform  
	var is_on_floor_now := is_on_floor()
	var input_direction := Input.get_axis(input_left, input_right)
	
	_handle_movement(delta, input_direction, is_on_floor_now)
	_handle_jump(delta, is_on_floor_now)
	_handle_step_assist(input_direction, is_on_floor_now)
	_handle_animation(input_direction, is_on_floor_now)
	_update_camera(delta)  # Pass delta to camera update
	
	was_on_floor = is_on_floor_now
	move_and_slide()

func _handle_movement(delta: float, input_direction: float, is_on_floor_now: bool) -> void:
	var speed_sign = sign(current_speed)
	var input_sign = sign(input_direction)
	
	# Only reset momentum when on the ground
	if is_on_floor_now:
		if speed_sign != 0 and input_sign != 0 and speed_sign != input_sign:
			run_build_timer = 0.0
			current_speed *= 0.6  # Quick slowdown when turning
		elif input_direction != 0 and speed_sign == input_sign:
			run_build_timer += delta
		else:
			run_build_timer = 0.0
	# If airborne, keep momentum unchanged.
	
	var ramp = clamp(run_build_timer / momentum_build_time, 0.0, 1.0)
	var desired_speed = input_direction * (move_speed + max_momentum_bonus * ramp)
	
	# More aggressive deceleration when turning on ground
	var accel_amount := acceleration
	if abs(desired_speed) < abs(current_speed) or (is_on_floor_now and speed_sign != 0 and input_sign != 0 and speed_sign != input_sign):
		accel_amount = deceleration * 1.5
	if !is_on_floor_now:
		accel_amount *= mid_air_friction
	
	var raw_speed = move_toward(current_speed, desired_speed, accel_amount * move_speed * delta)
	current_speed = lerp(current_speed, raw_speed, 0.25)
	
	# Combined collision logic
	if is_on_wall():
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var can_step = false
			for j in range(1, step_height + 1):
				var step_up := Vector2(0, -j)
				var step_dir := Vector2(speed_sign, 0)
				# Try stepping up
				if !test_move(transform, step_up) and !test_move(transform.translated(step_up), step_dir):
					can_step = true
					break

			if can_step:
				desired_speed *= 0.6
				current_speed *= 0.6
			else:
				# Bounce or stop
				if abs(current_speed) >= move_speed - 5:
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
		velocity.y = -jump_velocity  # Use calculated jump_velocity instead of jump_force
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
	
	# Test horizontal movement first
	if test_move(transform, movement):
		# If blocked, try stepping up
		for i in range(1, step_height + 1):
			var step_up := Vector2(0, -i)
			
			if !test_move(transform, step_up) && !test_move(transform.translated(step_up), movement):
				# We found a valid step height, apply it
				move_and_collide(step_up)
				move_and_collide(movement)
				break

func _handle_animation(input_direction: float, is_on_floor_now: bool) -> void:
	if !anim:
		return
		
	var new_animation := ""
	var movement_speed: float = abs(current_speed)
	var MIN_MOVE_THRESHOLD := 27.0  # Minimum speed to consider as "moving"
	
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
		# Scale animation speed with momentum
		var total_speed = movement_speed
		anim.speed_scale = clamp(pow(0.1 + total_speed / (move_speed + max_momentum_bonus), 1.4), 0.0, 1.0)
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
		
	# Smooth out velocity for prediction
	smoothed_velocity = smoothed_velocity.lerp(velocity, 10.0 * delta)
	
	# Calculate predicted position with separate horizontal/vertical factors
	var prediction := Vector2(
		smoothed_velocity.x * camera_prediction_h,
		smoothed_velocity.y * camera_prediction_v
	)
	
	# Clamp the prediction to max offset
	if prediction.length() > max_camera_offset:
		prediction = prediction.normalized() * max_camera_offset
	
	var target_position := global_position + prediction
	
	# Add slight camera shake based on bonus speed
	var base_speed = move_speed
	if abs(current_speed) > base_speed:
		var bonus = (abs(current_speed) - base_speed) / max_momentum_bonus
		var shake_magnitude = bonus * 50.0  # tweak factor for desired shake intensity
		var bonus_shake := Vector2(
			randf_range(-shake_magnitude, shake_magnitude),
			randf_range(-shake_magnitude, shake_magnitude)
		)
		target_position += bonus_shake
	
	# Framerate-independent lerp
	camera.global_position = camera.global_position.lerp(
		target_position, 
		1.0 - exp(-camera_smoothing * 90.0 * delta)
	)
