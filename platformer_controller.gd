extends CharacterBody2D

# Action states enum
enum ACTION {
    NONE,
    IDLE,
    RUNNING,
    JUMPING,
    FALLING,
    LANDING
}

@export var move_speed := 1000.0
@export var jump_force := 500.0
@export var acceleration := 15.0
@export var deceleration := 10.0
@export var gravity := 980.0
@export var input_left := "move_left"
@export var input_right := "move_right"
@export var input_jump := "jump"
@export var step_height := 9
@export var coyote_time := 0.04
@export var jump_buffer_time := 0.1
@export var anim: AnimatedSprite2D
@export var camera: Node2D
@export var jumpAudio: AudioStreamPlayer2D
@export var landAudio: AudioStreamPlayer2D
@export var runAudio: AudioStreamPlayer2D
@export var land_volume_multiplier := 2.0  # new variable to adjust landing volume
@export var mid_air_friction := 0.6  # Controls horizontal movement in air (0-1)

var coyote_time_counter := 0.0
var jump_buffer_counter := 0.0
var current_speed := 0.0
var was_on_floor := false
var is_landing := false
var previous_animation: String = ""

func _ready() -> void:
    anim.connect("animation_finished", self._on_animation_finished)
    if anim:
        anim.frame_changed.connect(_on_frame_changed)


func _on_animation_finished() -> void:
    if anim.animation == "land":
        is_landing = false
    elif anim.animation == "run" and runAudio:
        runAudio.play()

func _on_frame_changed() -> void:
    if anim.animation == "run" and anim.frame == 1 and runAudio:
        runAudio.play()

func _physics_process(delta: float) -> void:
    # -- horizontal movement --
    var input_direction = Input.get_axis(input_left, input_right)
    var target_speed = input_direction * move_speed
    
    var friction = acceleration if abs(target_speed) > abs(current_speed) else deceleration
    if not is_on_floor():
        friction *= mid_air_friction
    current_speed = lerp(current_speed, target_speed, friction * delta)
    velocity.x = current_speed
    
    # -- jump preparation --
    var is_on_floor_now = is_on_floor()
    if is_on_floor_now:
        coyote_time_counter = coyote_time
    else:
        coyote_time_counter -= delta

    if Input.is_action_just_pressed(input_jump):
        jump_buffer_counter = jump_buffer_time

    # -- jump execution --
    if (is_on_floor_now or coyote_time_counter > 0) and jump_buffer_counter > 0:
        velocity.y = -jump_force
        current_speed = lerp(current_speed, target_speed, 18 * delta)
        coyote_time_counter = 0
        jump_buffer_counter = 0
        if jumpAudio:
            jumpAudio.play()

    # -- gravity and movement --
    jump_buffer_counter -= delta
    velocity.y += gravity * delta
    move_and_slide()

    # -- wall collision --
    if is_on_wall() and not is_on_floor_now:
        current_speed = 0

    # -- step assistance --
    if is_on_floor_now and input_direction != 0:
        var dir = sign(input_direction)
        if test_move(global_transform, Vector2(dir, 0)):
            for i in range(1, step_height + 1):
                var test_pos = global_transform.translated(Vector2(0, -i))
                if not test_move(test_pos, Vector2(dir, 0)):
                    global_position.y -= i
                    global_position.x += dir
                    break

    # -- pixel snapping --
    if is_on_floor_now and input_direction == 0:
        global_position.x = round(global_position.x)
        global_position.y = round(global_position.y)

    # -- animation selection --
    var new_animation = ""
    if is_on_floor_now and not was_on_floor:
        new_animation = "land"
        anim.speed_scale = 1.0
        is_landing = true
        if landAudio:
            landAudio.play()
    elif not is_on_floor_now and not is_landing:
        new_animation = "jump"
        anim.speed_scale = 1.0
    elif abs(velocity.x) > 10 and not is_landing:
        new_animation = "run"
        var normalized_speed = abs(velocity.x) / move_speed
        var speed_factor = pow(0.1 + normalized_speed, 1.4)
        anim.speed_scale = clamp(speed_factor, 0, 1)
    elif not is_landing:
        new_animation = "idle"
        anim.speed_scale = 1.0

    # -- run sound --
    if runAudio and previous_animation == "run" and new_animation == "idle" and anim.frame == 0:
        runAudio.play()
    
    # -- animation update --
    previous_animation = new_animation
    anim.play(new_animation)

    # -- sprite flipping --
    if input_direction < 0:
        anim.scale.x = -1
    elif input_direction > 0:
        anim.scale.x = 1

    was_on_floor = is_on_floor_now

    # -- camera follow --
    if camera:
        var target_position = global_position + Vector2(velocity.x * 0.85, velocity.y * 0.85)
        camera.global_position = lerp(camera.global_position, target_position, 0.06)