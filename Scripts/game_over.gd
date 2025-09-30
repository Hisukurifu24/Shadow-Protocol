extends Control

@onready var score_label: Label = $ScoreLabel
@onready var name_input: LineEdit = $NameInput
@onready var save_score_button: Button = $SaveScoreButton
@onready var skip_button: Button = $SkipButton

func _ready():
	score_label.text = "Your Score: %d" % GameManagerNode.score
	save_score_button.pressed.connect(_on_save_score_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

func _on_save_score_pressed():
	var player_name = name_input.text.strip_edges()
	if player_name == "":
		player_name = "Anonymous"
	var score_entry = {"name": player_name, "score": GameManagerNode.score}
	var file = FileAccess.open("user://highscores.json", FileAccess.WRITE_READ)
	var scores = []
	if file.get_length() > 0:
		var content = file.get_as_text()
		scores = JSON.parse_string(content).result
	scores.append(score_entry)
	scores.sort_custom(func(a, b):
		return b["score"] - a["score"]
	)
	if scores.size() > 10:
		scores = scores.slice(0, 10)
	file.store_string(JSON.stringify(scores, "\t"))
	file.close()
	get_tree().change_scene_to_file("res://Scenes/highscores.tscn")

func _on_skip_pressed():
	get_tree().change_scene_to_file("res://Scenes/highscores.tscn")