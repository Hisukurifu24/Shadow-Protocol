extends Control

# Settings UI References
@onready var master_volume_slider = %MasterVolumeSlider
@onready var master_volume_label = %MasterVolumeLabel
@onready var sfx_volume_slider = %SFXVolumeSlider
@onready var sfx_volume_label = %SFXVolumeLabel
@onready var music_volume_slider = %MusicVolumeSlider
@onready var music_volume_label = %MusicVolumeLabel
@onready var fullscreen_button = %FullscreenButton
@onready var vsync_button = %VsyncButton
@onready var resolution_option = %ResolutionOption
@onready var quality_option = %QualityOption
@onready var back_button = %BackButton
@onready var reset_button = %ResetButton

# Audio bus indices
const MASTER_BUS = 0
const SFX_BUS = 1
const MUSIC_BUS = 2

# Settings data
var settings_data = {
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"music_volume": 1.0,
	"fullscreen": false,
	"vsync": true,
	"resolution": "1920x1080",
	"quality": "High"
}

var settings_file_path = "user://settings.save"

func _ready():
	load_settings()
	setup_ui()
	connect_signals()
	apply_settings()

func setup_ui():
	# Setup resolution options
	resolution_option.add_item("1920x1080")
	resolution_option.add_item("1600x900")
	resolution_option.add_item("1366x768")
	resolution_option.add_item("1280x720")
	resolution_option.add_item("1024x768")
	
	# Setup quality options
	quality_option.add_item("Low")
	quality_option.add_item("Medium")
	quality_option.add_item("High")
	quality_option.add_item("Ultra")
	
	# Set initial values
	master_volume_slider.value = settings_data.master_volume
	sfx_volume_slider.value = settings_data.sfx_volume
	music_volume_slider.value = settings_data.music_volume
	fullscreen_button.button_pressed = settings_data.fullscreen
	vsync_button.button_pressed = settings_data.vsync
	
	# Set resolution
	var resolution_index = resolution_option.get_item_count() - 1
	for i in range(resolution_option.get_item_count()):
		if resolution_option.get_item_text(i) == settings_data.resolution:
			resolution_index = i
			break
	resolution_option.selected = resolution_index
	
	# Set quality
	var quality_index = 2 # Default to High
	for i in range(quality_option.get_item_count()):
		if quality_option.get_item_text(i) == settings_data.quality:
			quality_index = i
			break
	quality_option.selected = quality_index
	
	update_volume_labels()
	setup_popup_themes()

func setup_popup_themes():
	# Style the popup menus for OptionButtons
	style_option_button_popup(resolution_option)
	style_option_button_popup(quality_option)

func style_option_button_popup(option_button: OptionButton):
	var popup = option_button.get_popup()
	
	# Create blood red theme for popup panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.03, 0.03, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.7, 0.15, 0.15, 1)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.shadow_color = Color(0.1, 0, 0, 0.8)
	panel_style.shadow_size = 8
	
	# Create hover style for menu items
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.4, 0.08, 0.08, 0.9)
	hover_style.border_width_left = 1
	hover_style.border_width_top = 1
	hover_style.border_width_right = 1
	hover_style.border_width_bottom = 1
	hover_style.border_color = Color(0.6, 0.12, 0.12, 1)
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_right = 4
	hover_style.corner_radius_bottom_left = 4
	
	# Create pressed style for menu items
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.5, 0.1, 0.1, 1)
	pressed_style.border_width_left = 1
	pressed_style.border_width_top = 1
	pressed_style.border_width_right = 1
	pressed_style.border_width_bottom = 1
	pressed_style.border_color = Color(0.7, 0.15, 0.15, 1)
	pressed_style.corner_radius_top_left = 4
	pressed_style.corner_radius_top_right = 4
	pressed_style.corner_radius_bottom_right = 4
	pressed_style.corner_radius_bottom_left = 4
	
	# Apply styles to popup
	popup.add_theme_stylebox_override("panel", panel_style)
	popup.add_theme_stylebox_override("hover", hover_style)
	popup.add_theme_stylebox_override("pressed", pressed_style)
	popup.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	popup.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	popup.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	popup.add_theme_font_override("font", load("res://Arts/Font/28 Days Later.ttf"))
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_constant_override("item_separation", 5)

func connect_signals():
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	fullscreen_button.toggled.connect(_on_fullscreen_toggled)
	vsync_button.toggled.connect(_on_vsync_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)
	quality_option.item_selected.connect(_on_quality_selected)
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

func _on_master_volume_changed(value: float):
	settings_data.master_volume = value
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(value))
	update_volume_labels()
	save_settings()

func _on_sfx_volume_changed(value: float):
	settings_data.sfx_volume = value
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(value))
	update_volume_labels()
	save_settings()

func _on_music_volume_changed(value: float):
	settings_data.music_volume = value
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(value))
	update_volume_labels()
	save_settings()

func _on_fullscreen_toggled(pressed: bool):
	settings_data.fullscreen = pressed
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func _on_vsync_toggled(pressed: bool):
	settings_data.vsync = pressed
	if pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	save_settings()

func _on_resolution_selected(index: int):
	var resolution_text = resolution_option.get_item_text(index)
	settings_data.resolution = resolution_text
	
	var resolution_parts = resolution_text.split("x")
	var width = int(resolution_parts[0])
	var height = int(resolution_parts[1])
	
	DisplayServer.window_set_size(Vector2i(width, height))
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen_size - window_size) / 2)
	
	save_settings()

func _on_quality_selected(index: int):
	settings_data.quality = quality_option.get_item_text(index)
	apply_quality_settings()
	save_settings()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_reset_pressed():
	reset_to_defaults()

func update_volume_labels():
	master_volume_label.text = "Master: " + str(int(settings_data.master_volume * 100)) + "%"
	sfx_volume_label.text = "SFX: " + str(int(settings_data.sfx_volume * 100)) + "%"
	music_volume_label.text = "Music: " + str(int(settings_data.music_volume * 100)) + "%"

func apply_settings():
	# Apply audio settings
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(settings_data.master_volume))
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(settings_data.sfx_volume))
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(settings_data.music_volume))
	
	# Apply display settings
	if settings_data.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if settings_data.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	apply_quality_settings()

func apply_quality_settings():
	match settings_data.quality:
		"Low":
			# Apply low quality settings
			pass
		"Medium":
			# Apply medium quality settings
			pass
		"High":
			# Apply high quality settings
			pass
		"Ultra":
			# Apply ultra quality settings
			pass

func save_settings():
	var file = FileAccess.open(settings_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings_data))
		file.close()

func load_settings():
	if FileAccess.file_exists(settings_file_path):
		var file = FileAccess.open(settings_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var loaded_data = json.data
				for key in loaded_data:
					if settings_data.has(key):
						settings_data[key] = loaded_data[key]

func reset_to_defaults():
	settings_data = {
		"master_volume": 1.0,
		"sfx_volume": 1.0,
		"music_volume": 1.0,
		"fullscreen": false,
		"vsync": true,
		"resolution": "1920x1080",
		"quality": "High"
	}
	setup_ui()
	apply_settings()
	save_settings()
