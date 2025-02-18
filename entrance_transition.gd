extends Control

@onready var enter_video = $EnterVideo
@onready var exit_video = $ExitVideo
@onready var start_button = $StartButton
@onready var exit_button = $ExitButton

func _ready():
    start_button.connect("pressed", self, "_on_start_button_pressed")
    exit_button.connect("pressed", self, "_on_exit_button_pressed")
    enter_video.connect("finished", self, "_on_enter_video_finished")
    exit_video.connect("finished", self, "_on_exit_video_finished")

func _on_start_button_pressed():
    start_button.disabled = true
    exit_button.disabled = true
    enter_video.visible = true
    enter_video.play()

func _on_exit_button_pressed():
    start_button.disabled = true
    exit_button.disabled = true
    exit_video.visible = true
    exit_video.play()

func _on_enter_video_finished():
    enter_video.visible = false
    hide()
    get_tree().paused = false

func _on_exit_video_finished():
    get_tree().quit()
