extends Control

@onready var title_label = %Title
@onready var scores_container = %ScoresContainer
@onready var back_button = %BackButton
@onready var clear_scores_button = %ClearScoresButton

var scores = []

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	clear_scores_button.pressed.connect(_on_clear_scores_pressed)
	load_and_display_scores()

func load_and_display_scores():
	scores = []
	var file = FileAccess.open("user://highscores.json", FileAccess.READ)
	if file:
		if file.get_length() > 0:
			var content = file.get_as_text()
			var json = JSON.new()
			var parse_result = json.parse(content)
			if parse_result == OK:
				scores = json.data
			else:
				print("Error parsing highscores JSON")
		file.close()
	
	display_scores()

func display_scores():
	# Clear existing score labels
	for child in scores_container.get_children():
		child.queue_free()
	
	if scores.is_empty():
		var no_scores_label = Label.new()
		no_scores_label.text = "No high scores yet!"
		no_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_scores_label.add_theme_font_size_override("font_size", 32)
		scores_container.add_child(no_scores_label)
		return
	
	# Display scores
	for i in range(min(scores.size(), 10)):
		var score_entry = scores[i]
		var rank_label = Label.new()
		rank_label.text = "%d. %s - %d" % [i + 1, score_entry["name"], score_entry["score"]]
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.add_theme_font_size_override("font_size", 20)
		
		# Highlight top 3 scores with different colors
		if i == 0:
			rank_label.add_theme_color_override("font_color", Color.GOLD)
		elif i == 1:
			rank_label.add_theme_color_override("font_color", Color.SILVER)
		elif i == 2:
			rank_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2)) # Bronze
		else:
			rank_label.add_theme_color_override("font_color", Color.WHITE)
		
		scores_container.add_child(rank_label)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_clear_scores_pressed():
	# Show confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Are you sure you want to clear all high scores?"
	dialog.title = "Clear High Scores"
	
	# Add a cancel button
	dialog.add_cancel_button("Cancel")
	
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(_on_clear_confirmed)
	dialog.tree_exited.connect(func(): dialog.queue_free())

func _on_clear_confirmed():
	var file = FileAccess.open("user://highscores.json", FileAccess.WRITE)
	if file:
		file.store_string("[]")
		file.close()
	scores = []
	display_scores()
