extends Node

var score := 0
var score_label
var highscore := 0
var save = ConfigFile.new()

func _ready() -> void:

    if get_tree().get_first_node_in_group("ScoreLabel"):
        score_label = get_tree().get_first_node_in_group("ScoreLabel")

    save.load_encrypted_pass("user://savegame.save", "peenar")

    score = save.get_value("scores", "current-score", 0)
    highscore = save.get_value("scores", "high-score", 0)

    pass

func save_game() -> void:
    save.set_value("scores", "current-score", score)
    save.set_value("scores", "high-score", highscore)
    save.save_encrypted_pass("user://savegame.save", "peenar")
    pass

func _exit_tree() -> void:
    save_game()
    pass

func add_score(points: int) -> void:
    score += points
    if score_label:
        score_label.add_score(points)
    save_game()
    pass

func remove_score(points: int) -> void:
    score -= points
    if score_label:
        score_label.remove_score(points)
    save_game()
    pass

func halve_score() -> void:
    score = int(score / 2.0)
    if score_label:
        score_label.halve_score()
    save_game()
    pass

func reset_score() -> void:
    score = 0
    if score_label:
        score_label.reset_score()
    save_game()
    pass