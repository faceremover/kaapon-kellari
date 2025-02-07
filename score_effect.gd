extends Label

@export_group("Shake Settings")
@export_range(0, 20) var shake_intensity := 7.0  # Default shake amount
@export_range(0, 20) var shake_decay := 5.0  # How fast shake dies down
@export_range(0.01, 0.2) var offset_interval := 0.05  # How often to update shake
@export_range(1, 50) var offset_interpolation := 20.0  # How smooth the shake is
@export_range(1, 3) var pop_scale := 1.5  # How much the text "pops" when showing

var tween_effect: Tween = null
var default_effect_pos: Vector2
var default_effect_scale: Vector2
var current_shake_intensity := 0.0
var offset_accumulator := 0.0
var current_offset := Vector2.ZERO
var target_offset := Vector2.ZERO

func _ready() -> void:
	# Initialize default properties
	default_effect_pos = position
	default_effect_scale = scale
	set_process(true)

func _process(delta: float) -> void:
	current_shake_intensity = lerp(current_shake_intensity, 0.0, delta * shake_decay)
	scale = scale.lerp(default_effect_scale, delta * shake_decay)
	
	offset_accumulator += delta
	if offset_accumulator >= offset_interval:
		offset_accumulator = 0.0
		target_offset = Vector2(
			randf_range(-current_shake_intensity, current_shake_intensity),
			randf_range(-current_shake_intensity, current_shake_intensity)
		)
	current_offset = current_offset.lerp(target_offset, delta * offset_interpolation)
	position = default_effect_pos + current_offset

func show_effect(effect: String, is_positive: bool, fade_duration: float) -> void:
	if tween_effect:
		tween_effect.kill()
		tween_effect = null
		text = ""
		modulate = Color(1, 1, 1, 1)
		scale = default_effect_scale
		position = default_effect_pos
	
	text = effect
	modulate = Color(0.5, 1, 0.5, 1) if is_positive else Color(1, 0.5, 0.5, 1)
	current_shake_intensity = shake_intensity
	scale = default_effect_scale * pop_scale
	tween_effect = create_tween().set_parallel()
	var scale_duration: float = fade_duration / 2.0
	tween_effect.tween_property(self, "scale", Vector2(1.0, 1.0), scale_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_effect.tween_property(self, "modulate:a", 0.0, fade_duration)
	
	await tween_effect.finished
	tween_effect = null
	text = ""
	modulate = Color(1, 1, 1, 1)
	scale = default_effect_scale
	position = default_effect_pos
