extends AudioStreamPlayer2D

@export var start_pitch: float = 1.0
@export var end_pitch: float = 2.0
@export var acceleration_time: float = 1.0

var is_accelerating: bool = false
var current_time: float = 0.0
var going_up: bool = true

func _ready():
    pitch_scale = start_pitch
    start_acceleration()

func _process(delta):
    if is_accelerating:
        current_time += delta if going_up else -delta
        current_time = clamp(current_time, 0, acceleration_time)
        
        # Calculate new pitch using linear interpolation
        pitch_scale = lerp(start_pitch, end_pitch, current_time / acceleration_time)
        
        # Switch direction at endpoints to create continuous cycle
        if current_time >= acceleration_time or current_time <= 0:
            going_up = !going_up

func start_acceleration():
    is_accelerating = true
    
func stop_acceleration():
    is_accelerating = false
    current_time = 0.0
    pitch_scale = start_pitch