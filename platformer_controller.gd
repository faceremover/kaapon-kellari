extends CharacterBody2D

@export var move_speed := 1000.0
@export var jump_force := 500.0
@export var friction := 10.0
@export var gravity := 980.0
@export var input_left := "move_left"
@export var input_right := "move_right"
@export var input_jump := "jump"
@export var step_height := 9
@export var anim: AnimatedSprite2D
@export var coyote_time := 0.04
@export var jump_buffer_time := 0.1
@export var camera: Node2D  # Exported Node2D variable

var coyote_time_counter := 0.0
var jump_buffer_counter := 0.0
var current_speed := 0.0
var was_on_floor := false  # Track the previous frame's ground state
var is_landing := false  # Track if the "land" animation is playing

func _ready() -> void:
    anim.connect("animation_finished", self._on_animation_finished)

func _on_animation_finished() -> void:
    if anim.animation == "land":
        is_landing = false

func _physics_process(delta: float) -> void:
    var input_direction = Input.get_axis(input_left, input_right)
    var target_speed = input_direction * move_speed
    
    current_speed = lerp(current_speed, target_speed, friction * delta)
    velocity.x = current_speed
    
    var is_on_floor_now = is_on_floor()  # Current frame's ground state
    
    if is_on_floor_now:
        coyote_time_counter = coyote_time
    else:
        coyote_time_counter -= delta
    
    if Input.is_action_just_pressed(input_jump):
        jump_buffer_counter = jump_buffer_time
    
    if (is_on_floor_now or coyote_time_counter > 0) and jump_buffer_counter > 0:
        velocity.y = -jump_force
        coyote_time_counter = 0
        jump_buffer_counter = 0
    
    jump_buffer_counter -= delta
    velocity.y += gravity * delta
    move_and_slide()

    if is_on_wall() and not is_on_floor_now: 
        current_speed = 0
        # who wants juice?
        # juice = 0
    
    # Check for step height only when there is input
    if is_on_floor_now and input_direction != 0:
        var dir = sign(input_direction)
        if test_move(global_transform, Vector2(dir, 0)):
            for i in range(1, step_height + 1):
                var test_pos = global_transform.translated(Vector2(0, -i))
                if not test_move(test_pos, Vector2(dir, 0)):
                    global_position.y -= i
                    global_position.x += dir
                    break

    # Play "land" animation if character just landed
    if is_on_floor_now and not was_on_floor:
        anim.play("land")
        is_landing = true
        anim.speed_scale = 1.0
    elif not is_on_floor_now and not is_landing:
        anim.play("jump")
        anim.speed_scale = 1.0
    elif abs(velocity.x) > 10 and not is_landing:
        anim.play("run")
        # Apply reversed cubic easing curve to animation speed
        var normalized_speed = abs(velocity.x) / move_speed
        var speed_factor = pow(0.1 + normalized_speed, 1.4)  # cubic easing
        anim.speed_scale = clamp(speed_factor, 0, 1)
    elif not is_landing:
        anim.play("idle")
        anim.speed_scale = 1.0
    
    if input_direction < 0:
        anim.scale.x = -1
    elif input_direction > 0:
        anim.scale.x = 1
    
    was_on_floor = is_on_floor_now  # Update the previous frame's ground state

    # Smoothly update the camera position
    if camera:
        var target_position = global_position + Vector2(velocity.x * .8, velocity.y * 0.8)
        camera.global_position = lerp(camera.global_position, target_position, 0.06)