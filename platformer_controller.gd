extends CharacterBody2D  # Changed from Node to CharacterBody2D for proper platformer functionality

@export var move_speed := 1000.0
@export var jump_force := 500.0
@export var friction := 10.0
@export var input_left := "move_left"
@export var input_right := "move_right"
@export var input_jump := "jump"
@export var anim: AnimatedSprite2D

func _physics_process(delta: float) -> void:
    
    # Horizontal movement
    var input_direction = Input.get_axis(input_left, input_right)
    velocity.x = input_direction * move_speed
    
    # Apply friction (simplified)
    if is_on_floor():
        velocity.x *= 0.9  # Smooth deceleration when on floor
    
    # Jumping
    if Input.is_action_just_pressed(input_jump) and is_on_floor():
        velocity.y = -jump_force
    
    # Gravity (added)
    velocity.y += 980 * delta  # Standard gravity
    
    # Update velocity
    move_and_slide()
    
    # Update animations
    if not is_on_floor():
        anim.play("jump")
    elif abs(velocity.x) > 10:
        anim.play("run")
    else:
        anim.play("idle")
    
    # Flip sprite when moving left
    if input_direction < 0:
        anim.scale.x = -1
    elif input_direction > 0:
        anim.scale.x = 1