extends Node

signal submit_name(name: String)

@onready var asktext: Label = $CanvasLayer/Control/asktext
@onready var lineedit : LineEdit = $CanvasLayer/Control/LineEdit
@onready var submitBTN : Button = $CanvasLayer/Control/submitBT
@onready var errorText : Label = $CanvasLayer/Control/errortext

func _ready() -> void:

	lineedit.grab_click_focus()

	pass



func _on_submit_bt_pressed() -> void:
	
	if lineedit.text.strip_edges() == "" or lineedit.text == "Insert name...":
		errorText.text = "Please enter a name."
	else:
		submitBTN.disabled = true
		var does_exist = false
		if FileAccess.file_exists("user://tournament_data.csv"):
			does_exist = true
		var csvFile := FileAccess.open("user://tournament_data.csv", FileAccess.READ_WRITE)
		if csvFile == null:
			csvFile = FileAccess.open("user://tournament_data.csv", FileAccess.WRITE)
		if !does_exist:
			csvFile.store_csv_line(["Name", "Score"])
		csvFile.seek_end()
		csvFile.store_csv_line([lineedit.text, str(GameStateSingleton.score)])
		csvFile.close()
		lineedit.text = ""
		emit_signal("submit_name", lineedit.text)
	pass # Replace with function body.
