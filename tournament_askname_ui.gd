extends Node

signal submit_name(name: String)

@onready var asktext: Label = $CanvasLayer/Control/asktext
@onready var lineedit : LineEdit = $CanvasLayer/Control/LineEdit
@onready var submitBTN : Button = $CanvasLayer/Control/submitBT
@onready var errorText : Label = $CanvasLayer/Control/errortext

func _ready() -> void:

	lineedit.grab_click_focus()

	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			emit_signal("submit_name", "")
	pass

func _on_submit_bt_pressed() -> void:
	var entered_name = lineedit.text.strip_edges().to_lower()
	var easter_eggs = {
		"": "PLEASE insert name!",
		"name": "Hilarious",
		"name...": "...",
		"kellari": "No it isn't",
		"kaapon kellari": "That's me actually",
		"ap": "bo what",
		"insert name": "No u",
		"insert name...": "No u",
		"submit": "Your parents must hate you",
		"error": "Here's your error",
		"pekka juice": "WHAT",
		"pekkamehu": "WHAT",
		"pekka mehu": "WHAT",
		"uwu": "owo",
		"owo": "uwu",
		"owu": "uwo",
		"uwo": "owu",
		"mauppi": "hello mappi 1 guy",
		"mauppi1": "hello mappi 1 guy",
		"skaa": "hello shaakejo guy",
		"skaahejo": "hello shaakejo guy",
		"aapo skyttä": "hello shaakejo guy",
		"geek": "no, i mean like, you playing the game"
	}
	
	if easter_eggs.has(entered_name):
		errorText.text = easter_eggs[entered_name]
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
		var lineIndex = 0
		while csvFile.get_position() < csvFile.get_length():
			var line = csvFile.get_csv_line()
			csvFile.seek(lineIndex)
			lineIndex += 1
			if line[0].strip_edges().to_lower() == entered_name:
				errorText.text = "Enter some other name!"
				submitBTN.disabled = false
				csvFile.close()
				return
		csvFile.store_csv_line([entered_name, str(GameStateSingleton.score)])
		csvFile.close()
		lineedit.text = ""
		emit_signal("submit_name", lineedit.text)
	pass # Replace with function body.
