extends Node

# Audio bus indices
const MASTER_BUS = 0
const SFX_BUS = 1
const MUSIC_BUS = 2

# Settings data with defaults
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
	# Load and apply settings when the game starts
	load_settings()
	apply_settings()

func get_setting(key: String):
	return settings_data.get(key)

func set_setting(key: String, value):
	if settings_data.has(key):
		settings_data[key] = value
		save_settings()

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
			else:
				print("Error parsing settings JSON: ", json.error_string)
	else:
		# No settings file exists, create one with defaults
		save_settings()

func save_settings():
	var file = FileAccess.open(settings_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings_data))
		file.close()
	else:
		print("Error: Could not open settings file for writing")

func apply_settings():
	# Apply audio settings
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(settings_data.master_volume))
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(settings_data.sfx_volume))
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(settings_data.music_volume))
	
	# Apply display settings
	if settings_data.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Apply resolution only in windowed mode
		var resolution_parts = settings_data.resolution.split("x")
		if resolution_parts.size() == 2:
			var width = int(resolution_parts[0])
			var height = int(resolution_parts[1])
			DisplayServer.window_set_size(Vector2i(width, height))
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			# Center the window
			call_deferred("center_window") # Defer to ensure window is properly sized first
	
	# Apply vsync
	if settings_data.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	apply_quality_settings()

func center_window():
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen_size - window_size) / 2)

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

func reset_to_defaults():
	# Determine a good default resolution based on display size
	var screen_size = DisplayServer.screen_get_size()
	var default_resolution = "1920x1080" # Fallback
	
	# Choose a reasonable default based on screen size
	if screen_size.x >= 3840 and screen_size.y >= 2160:
		default_resolution = "2560x1440" # For 4K displays, use 1440p as default
	elif screen_size.x >= 2560 and screen_size.y >= 1440:
		default_resolution = "1920x1080" # For 1440p+ displays, use 1080p as default
	elif screen_size.x >= 1920 and screen_size.y >= 1080:
		default_resolution = "1920x1080" # For 1080p+ displays, use 1080p
	elif screen_size.x >= 1366 and screen_size.y >= 768:
		default_resolution = "1366x768" # For smaller displays
	else:
		default_resolution = str(screen_size.x) + "x" + str(screen_size.y) # Use native resolution
	
	settings_data = {
		"master_volume": 1.0,
		"sfx_volume": 1.0,
		"music_volume": 1.0,
		"fullscreen": false,
		"vsync": true,
		"resolution": default_resolution,
		"quality": "High"
	}
	
	apply_settings()
	save_settings()