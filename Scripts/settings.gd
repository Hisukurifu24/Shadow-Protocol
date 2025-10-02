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
const MUSIC_BUS = 1
const SFX_BUS = 2

# Settings data (now references the autoload)
# Direct access to SettingsManager via get_node
var settings_file_path = "user://settings.save"

func _ready():
	# Settings are already loaded by SettingsManager autoload
	setup_ui()
	connect_signals()
	# No need to call apply_settings() here as it's already done by SettingsManager

func setup_resolution_options():
	# Get the current display size
	var screen_size = DisplayServer.screen_get_size()
	var max_width = screen_size.x
	var max_height = screen_size.y
	
	# Define common aspect ratios and their resolutions
	var resolutions = []
	
	# 16:9 aspect ratio resolutions
	var resolutions_16_9 = [
		Vector2i(3840, 2160), # 4K
		Vector2i(2560, 1440), # 1440p
		Vector2i(1920, 1080), # 1080p
		Vector2i(1600, 900), # 900p
		Vector2i(1366, 768), # 768p
		Vector2i(1280, 720), # 720p
		Vector2i(1024, 576), # 576p
		Vector2i(854, 480) # 480p
	]
	
	# 16:10 aspect ratio resolutions
	var resolutions_16_10 = [
		Vector2i(2560, 1600), # WQXGA
		Vector2i(1920, 1200), # WUXGA
		Vector2i(1680, 1050), # WSXGA+
		Vector2i(1440, 900), # WXGA+
		Vector2i(1280, 800) # WXGA
	]
	
	# 4:3 aspect ratio resolutions
	var resolutions_4_3 = [
		Vector2i(1600, 1200), # UXGA
		Vector2i(1280, 960), # SXGA-
		Vector2i(1024, 768), # XGA
		Vector2i(800, 600) # SVGA
	]
	
	# 21:9 aspect ratio resolutions (ultrawide)
	var resolutions_21_9 = [
		Vector2i(5120, 2160), # 5K ultrawide
		Vector2i(3840, 1600), # 4K ultrawide
		Vector2i(3440, 1440), # UWQHD
		Vector2i(2560, 1080), # UW-UXGA
		Vector2i(2560, 1200), # UWXGA
		Vector2i(1920, 800), # UWVGA
		Vector2i(1680, 720) # UWVGA-
	]
	
	# Combine all resolutions
	resolutions.append_array(resolutions_16_9)
	resolutions.append_array(resolutions_16_10)
	resolutions.append_array(resolutions_4_3)
	resolutions.append_array(resolutions_21_9)
	
	# Filter resolutions that fit within the display
	var valid_resolutions = []
	for resolution in resolutions:
		if resolution.x <= max_width and resolution.y <= max_height:
			valid_resolutions.append(resolution)
	
	# Remove duplicates and sort by area (largest first)
	var unique_resolutions = {}
	for resolution in valid_resolutions:
		var key = str(resolution.x) + "x" + str(resolution.y)
		unique_resolutions[key] = resolution
	
	# Convert back to array and sort by area (width * height)
	var sorted_resolutions = []
	for key in unique_resolutions:
		sorted_resolutions.append(unique_resolutions[key])
	
	# Sort by area in descending order (largest first)
	sorted_resolutions.sort_custom(func(a, b): return (a.x * a.y) > (b.x * b.y))
	
	# Add resolutions to the option button
	resolution_option.clear()
	for resolution in sorted_resolutions:
		var resolution_text = str(resolution.x) + "x" + str(resolution.y)
		resolution_option.add_item(resolution_text)
	
	# If no valid resolutions found (edge case), add the current screen resolution
	if resolution_option.get_item_count() == 0:
		var fallback_resolution = str(max_width) + "x" + str(max_height)
		resolution_option.add_item(fallback_resolution)

func setup_ui():
	# Setup resolution options dynamically
	setup_resolution_options()
	
	# Setup quality options
	quality_option.add_item("Low")
	quality_option.add_item("Medium")
	quality_option.add_item("High")
	quality_option.add_item("Ultra")
	
	# Set initial values
	master_volume_slider.value = SettingsManagerNode.get_setting("master_volume")
	sfx_volume_slider.value = SettingsManagerNode.get_setting("sfx_volume")
	music_volume_slider.value = SettingsManagerNode.get_setting("music_volume")
	fullscreen_button.button_pressed = SettingsManagerNode.get_setting("fullscreen")
	vsync_button.button_pressed = SettingsManagerNode.get_setting("vsync")
	
	# Set resolution
	var resolution_index = resolution_option.get_item_count() - 1
	for i in range(resolution_option.get_item_count()):
		if resolution_option.get_item_text(i) == SettingsManagerNode.get_setting("resolution"):
			resolution_index = i
			break
	resolution_option.selected = resolution_index
	
	# Set quality
	var quality_index = 2 # Default to High
	for i in range(quality_option.get_item_count()):
		if quality_option.get_item_text(i) == SettingsManagerNode.get_setting("quality"):
			quality_index = i
			break
	quality_option.selected = quality_index
	
	update_volume_labels()
	update_resolution_state()
	setup_popup_themes()

func update_resolution_state():
	# Disable resolution dropdown when in fullscreen
	resolution_option.disabled = SettingsManagerNode.get_setting("fullscreen")
	
	if SettingsManagerNode.get_setting("fullscreen"):
		# Show the screen's native resolution when in fullscreen
		var screen_size = DisplayServer.screen_get_size()
		var native_resolution = str(screen_size.x) + "x" + str(screen_size.y)
		
		# Check if native resolution exists in the list
		var found = false
		for i in range(resolution_option.get_item_count()):
			if resolution_option.get_item_text(i) == native_resolution:
				resolution_option.selected = i
				found = true
				break
		
		# If not found, temporarily add it at the top (it should be the largest)
		if not found:
			resolution_option.add_item(native_resolution, 0)
			resolution_option.selected = 0

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
	SettingsManagerNode.set_setting("master_volume", value)
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(value))
	update_volume_labels()
	# Play slider sound feedback
	UiAudioManager.play_slider_change()

func _on_sfx_volume_changed(value: float):
	SettingsManagerNode.set_setting("sfx_volume", value)
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(value))
	update_volume_labels()
	# Play slider sound feedback
	UiAudioManager.play_slider_change()

func _on_music_volume_changed(value: float):
	SettingsManagerNode.set_setting("music_volume", value)
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(value))
	update_volume_labels()
	# Play slider sound feedback
	UiAudioManager.play_slider_change()

func _on_fullscreen_toggled(pressed: bool):
	SettingsManagerNode.set_setting("fullscreen", pressed)
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Rebuild resolution options when exiting fullscreen to remove temporary entries
		setup_resolution_options()
		# Restore the saved resolution when exiting fullscreen
		var resolution_parts = SettingsManagerNode.get_setting("resolution").split("x")
		var width = int(resolution_parts[0])
		var height = int(resolution_parts[1])
		DisplayServer.window_set_size(Vector2i(width, height))
		# Center the window when exiting fullscreen
		var screen_size = DisplayServer.screen_get_size()
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position((screen_size - window_size) / 2)
		
		# Update the selection to match the current resolution
		for i in range(resolution_option.get_item_count()):
			if resolution_option.get_item_text(i) == SettingsManagerNode.get_setting("resolution"):
				resolution_option.selected = i
				break
	
	update_resolution_state()

func _on_vsync_toggled(pressed: bool):
	SettingsManagerNode.set_setting("vsync", pressed)
	if pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_resolution_selected(index: int):
	# Only apply resolution changes in windowed mode
	if SettingsManagerNode.get_setting("fullscreen"):
		return
	
	var resolution_text = resolution_option.get_item_text(index)
	SettingsManagerNode.set_setting("resolution", resolution_text)
	
	var resolution_parts = resolution_text.split("x")
	var width = int(resolution_parts[0])
	var height = int(resolution_parts[1])
	
	# In windowed mode, change the window size
	DisplayServer.window_set_size(Vector2i(width, height))
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen_size - window_size) / 2)

func _on_quality_selected(index: int):
	SettingsManagerNode.set_setting("quality", quality_option.get_item_text(index))
	apply_quality_settings()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_reset_pressed():
	reset_to_defaults()

func update_volume_labels():
	master_volume_label.text = "Master: " + str(int(SettingsManagerNode.get_setting("master_volume") * 100)) + "%"
	sfx_volume_label.text = "SFX: " + str(int(SettingsManagerNode.get_setting("sfx_volume") * 100)) + "%"
	music_volume_label.text = "Music: " + str(int(SettingsManagerNode.get_setting("music_volume") * 100)) + "%"

func apply_settings():
	# Apply audio settings
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(SettingsManagerNode.get_setting("master_volume")))
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(SettingsManagerNode.get_setting("sfx_volume")))
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(SettingsManagerNode.get_setting("music_volume")))
	
	# Apply display settings
	if SettingsManagerNode.get_setting("fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Apply resolution only in windowed mode
		var resolution_parts = SettingsManagerNode.get_setting("resolution").split("x")
		var width = int(resolution_parts[0])
		var height = int(resolution_parts[1])
		DisplayServer.window_set_size(Vector2i(width, height))
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Center the window
		var screen_size = DisplayServer.screen_get_size()
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position((screen_size - window_size) / 2)
	
	if SettingsManagerNode.get_setting("vsync"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	apply_quality_settings()

func apply_quality_settings():
	match SettingsManagerNode.get_setting("quality"):
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

func reset_to_defaults():
	SettingsManagerNode.reset_to_defaults()
	setup_ui()
	apply_settings()
