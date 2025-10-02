extends Node

# UI Audio Manager - Singleton for handling all UI sound effects
# Add this to AutoLoad in Project Settings as "UIAudioManager"

# Audio player for UI sounds
var ui_audio_player: AudioStreamPlayer

# UI Sound library
var ui_sounds = {
	"button_hover": load("res://Arts/Sounds/UI/Cursor - 3.ogg"),
	"button_click": load("res://Arts/Sounds/UI/Select - 2.ogg"),
	"error": load("res://Arts/Sounds/UI/Error - 1.ogg"),
	"slider_change": load("res://Arts/Sounds/UI/Cursor - 1.ogg"), # Soft cursor sound for sliders
}

func _ready():
	# Create audio player for UI sounds
	ui_audio_player = AudioStreamPlayer.new()
	ui_audio_player.bus = "SFX" # Use the SFX bus
	add_child(ui_audio_player)

	# Connect to the tree's node_added signal to detect when new scenes are loaded
	get_tree().node_added.connect(_on_node_added)
	
	# Connect buttons in the initial scene
	call_deferred("_on_scene_changed")

func _on_node_added(node: Node):
	# Check if the added node is the current scene (main scene)
	if node == get_tree().current_scene:
		call_deferred("_on_scene_changed")

func _on_scene_changed():
	# Connect all buttons in the new scene to play click and hover sounds
	var buttons = get_tree().get_nodes_in_group("ui_buttons")
	print("UIAudioManager: Found %d buttons in the scene." % buttons.size())
	
	# Connect signals for each button
	for button in buttons:
		if button is Button:
			# Connect hover sound (mouse_entered)
			if not button.mouse_entered.is_connected(play_button_hover):
				button.mouse_entered.connect(play_button_hover)
			
			# Connect click sound (pressed)
			if not button.pressed.is_connected(play_button_click):
				button.pressed.connect(play_button_click)
	
	
func play_ui_sound(sound_name: String, volume_db: float = 0.0):
	if not ui_sounds.has(sound_name):
		print("Warning: UI sound '%s' not found!" % sound_name)
		return
	
	var sound_resource = ui_sounds[sound_name]
	if sound_resource == null:
		print("Warning: UI sound '%s' is null!" % sound_name)
		return
	
	# Stop current sound if playing
	if ui_audio_player.playing:
		ui_audio_player.stop()
	
	# Set up and play the sound
	ui_audio_player.stream = sound_resource
	ui_audio_player.volume_db = volume_db
	ui_audio_player.play()

# Convenience methods for common UI sounds
func play_button_hover():
	play_ui_sound("button_hover", -5.0) # Slightly quieter for hover

func play_button_click():
	play_ui_sound("button_click")

func play_button_disabled():
	play_ui_sound("button_disabled", -3.0)

func play_menu_open():
	play_ui_sound("menu_open")

func play_menu_close():
	play_ui_sound("menu_close")

func play_notification():
	play_ui_sound("notification")

func play_error():
	play_ui_sound("error")

func play_success():
	play_ui_sound("success")

func play_tab_switch():
	play_ui_sound("tab_switch", -2.0)

func play_slider_change():
	play_ui_sound("slider_change", -8.0) # Very quiet for slider feedback
