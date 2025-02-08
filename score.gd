extends Label

@export_range(1, 20) var score_smoothing := 10.0
@export var effect_label: Label
@export var score_sound: AudioStreamPlayer2D
@export var score_sound2down: AudioStreamPlayer2D

var game_active := false
var current_score := 0
var displayed_score := 0.0
var default_effect_pos: Vector2
var default_effect_scale: Vector2

func _ready() -> void:
	displayed_score = float(current_score)
	text = "0"
	if effect_label:
		default_effect_pos = effect_label.position
		default_effect_scale = effect_label.scale
	set_process(false)  # Only enable process when score changes

func add_score(points: int) -> void:
	if not game_active:  # Fixed condition
		return
	if score_sound and points > 0:  # Play sound only for positive scores
		score_sound.play()
	
	current_score += points
	if effect_label:
		var score_text = ("+" if points > 0 else "") + str(points)
		effect_label.show_effect(score_text, points >= 0, 0.4)
	set_process(true)

func halve_score() -> void:
	if not game_active:  # Add safety check
		return
	current_score = int(current_score / 2.0)
	if effect_label:
		effect_label.show_effect("-50%", false, 0.4)
	if score_sound:  # Play sound for penalty
		score_sound2down.play()
	set_process(true)

func reset_score() -> void:
	current_score = 0
	displayed_score = 0.0
	text = "0"
	set_process(false)

func set_game_active(active: bool) -> void:
	game_active = active

func _process(delta: float) -> void:
	var target := float(current_score)
	if abs(displayed_score - target) < 0.1:
		displayed_score = target
		text = str(current_score)
		set_process(false)
		return
	var old_displayed_score := displayed_score
	displayed_score = move_toward(displayed_score, target, 
								score_smoothing * delta * max(1.0, abs(displayed_score - target)))
	if int(displayed_score) > int(old_displayed_score):
		score_sound.play()
	elif int(displayed_score) < int(old_displayed_score):
		score_sound2down.play()

	text = str(int(round(displayed_score)))
