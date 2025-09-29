extends Control

@onready var title_label = %Title

var blink_timer: Timer
var base_outline_color: Color
var neon_green_outline: Color = Color(0.0, 0.9, 0.3, 0.8) # More visible neon green outline
var radioactive_green_outline: Color = Color(0.15, 0.95, 0.0, 0.7) # Brighter yellow-green outline
var dark_green_outline: Color = Color(0.0, 0.5, 0.15, 0.6) # More noticeable green outline

func _ready():
	setup_radioactive_blink()

func setup_radioactive_blink():
	# Store the original outline color
	base_outline_color = title_label.label_settings.outline_color
	
	# Create a timer for random blinking
	blink_timer = Timer.new()
	add_child(blink_timer)
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	
	# Start the blinking cycle
	start_random_blink()

func start_random_blink():
	# Random interval between 0.8 and 2.5 seconds (balanced frequency)
	var random_interval = randf_range(0.8, 2.5)
	blink_timer.wait_time = random_interval
	blink_timer.start()

func _on_blink_timer_timeout():
	# Create a random blink effect (balanced variety)
	var blink_type = randi() % 5 # Better balance of effects
	
	match blink_type:
		0:
			# Quick single blink
			quick_blink()
		1:
			# Double blink
			double_blink()
		2:
			# Sustained glow
			sustained_glow()
		3:
			# Brief flicker
			brief_flicker()
		4:
			# No effect (skip this cycle for some variety)
			pass
	
	# Schedule next blink
	start_random_blink()

func quick_blink():
	# Quick, noticeable flash
	change_outline_color(neon_green_outline)
	await get_tree().create_timer(0.06).timeout # Slightly longer for visibility
	change_outline_color(base_outline_color)

func double_blink():
	# Two quick flashes with good visibility
	change_outline_color(radioactive_green_outline)
	await get_tree().create_timer(0.07).timeout
	change_outline_color(base_outline_color)
	await get_tree().create_timer(0.10).timeout
	change_outline_color(neon_green_outline)
	await get_tree().create_timer(0.07).timeout
	change_outline_color(base_outline_color)

func sustained_glow():
	# Balanced glow with good visibility
	var tween = create_tween()
	tween.tween_method(change_outline_color, base_outline_color, dark_green_outline, 0.3)
	tween.tween_method(change_outline_color, dark_green_outline, neon_green_outline, 0.25)
	tween.tween_method(change_outline_color, neon_green_outline, base_outline_color, 0.4)

func brief_flicker():
	# Short controlled flicker
	for i in range(3):
		var flicker_colors = [neon_green_outline, radioactive_green_outline]
		change_outline_color(flicker_colors[randi() % flicker_colors.size()])
		await get_tree().create_timer(0.04).timeout
		change_outline_color(base_outline_color)
		await get_tree().create_timer(0.02).timeout
	change_outline_color(base_outline_color)

func change_outline_color(color: Color):
	# Update outline color with balanced intensity
	title_label.label_settings.outline_color = color
	if color != base_outline_color:
		# Noticeable but not excessive outline size increase
		title_label.label_settings.outline_size = 7 # Sweet spot between 5 and 8
	else:
		# Reset to original outline size
		title_label.label_settings.outline_size = 5
