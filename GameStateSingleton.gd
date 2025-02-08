extends Node

var score := 0
var score_label

func _ready() -> void:

    if get_tree().get_first_node_in_group("ScoreLabel"):
        score_label = get_tree().get_first_node_in_group("ScoreLabel")



    pass

func add_score(points: int) -> void:
    score += points
    if score_label:
        score_label.add_score(points)
    pass

func remove_score(points: int) -> void:
    score -= points
    if score_label:
        score_label.remove_score(points)
    pass

func halve_score() -> void:
    score = int(score / 2.0)
    if score_label:
        score_label.halve_score()
    pass

func reset_score() -> void:
    score = 0
    if score_label:
        score_label.reset_score()
    pass