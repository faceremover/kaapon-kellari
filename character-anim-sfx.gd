extends Node2D

@export var sprite: AnimatedSprite2D
@export var jumpAudio: AudioStreamPlayer2D
@export var landAudio: AudioStreamPlayer2D
@export var runAudio: AudioStreamPlayer2D

var previous_animation: String = ""

func _ready():
    if sprite:
        sprite.frame_changed.connect(_on_frame_changed)
        sprite.animation_changed.connect(_on_animation_changed)

func _on_animation_changed():
    match sprite.animation:
        "jump":
            jumpAudio.play()
        "land":
            landAudio.play()
        "idle":
            if previous_animation == "run":
                runAudio.play()
    
    previous_animation = sprite.animation

func _on_frame_changed():
    if sprite.animation == "run" and sprite.frame == 1:
        runAudio.play()