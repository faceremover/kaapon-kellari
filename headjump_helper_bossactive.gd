extends Sprite2D

@export var boss_path : NodePath
@export var label_path : NodePath

@export_multiline var active_text : String = "Boss Active"
@export_multiline var inactive_text : String = "Boss Inactive"

var boss
var label

func _ready() -> void:
	boss = get_node(boss_path)
	label = get_node(label_path)
	pass

func _process(delta: float) -> void:
	if !boss || !label:
		printerr("headjump_helper_bossactive.gd: Missing boss or label node")
		return

	if boss.boss_active:
		label.text = active_text
	else:
		label.text = inactive_text
	pass

