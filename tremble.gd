extends Node2D

# Customizable properties
@export var max_angle: float = 5.0 # Maximum rotation angle in degrees
@export var speed: float = 2.0 # Speed of the trembling
@export var shake_amount: float = 5.0 # Maximum shake amount in pixels

var original_position: Vector2
var time_passed: float = 0.0

func _ready():
    original_position = position

func _process(delta):
    time_passed += delta * speed
    # Calculate rotation using sine wave
    rotation_degrees = max_angle * sin(time_passed)
    # Calculate position shake
    position.x = original_position.x + shake_amount * sin(time_passed * 1.9)
    position.y = original_position.y + shake_amount * cos(time_passed * 2.53)