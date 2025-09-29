extends CanvasLayer

@onready var ammo_label: Label = %Ammo
@onready var lifebar: ProgressBar = %LifeBar
@onready var health_overlay: TextureRect = %HealthOverlay

# Cursor settings
@export var aiming_cursor: Texture2D = preload("res://Arts/Crosshairs 64/image0029.png")
@export var lerping_cursor: Texture2D = preload("res://Arts/Crosshairs 64/image0032.png")

var player: Player

func _ready():
	player = get_node("/root/World/Player")
	player.fired.connect(_on_player_fired)
	player.reload_started.connect(_on_player_reload_started)
	player.reload_finished.connect(_on_player_reload_finished)
	player.weapon_changed.connect(_on_player_weapon_changed)
	player.aim_state_changed.connect(_on_player_aim_state_changed)
	player.health_changed.connect(_on_player_health_changed)
	
	# Set initial cursor
	Input.set_custom_mouse_cursor(aiming_cursor, Input.CURSOR_ARROW, Vector2(32, 32))
	
	_update_ammo_display()
	_update_slots_display()
	_update_lifebar(player.health)
	_update_health_overlay(player.health)

func _on_player_fired():
	# Update ammo display when the player fires
	_update_ammo_display()

func _on_player_reload_started():
	# Update ammo display when the player starts reloading
	ammo_label.add_theme_color_override("font_color", Color.ORANGE)
	%Reloading.visible = true
	_update_ammo_display()

func _on_player_reload_finished():
	# Update ammo display when the player finishes reloading
	ammo_label.add_theme_color_override("font_color", Color.WHITE)
	%Reloading.visible = false
	_update_ammo_display()

func _update_ammo_display():
	var weapon = player.slots[player.current_weapon_slot]
	if weapon:
		ammo_label.text = "%d / %d" % [weapon.current_ammo, player.get_current_weapon_ammo()]
	else:
		ammo_label.text = ""

func _on_player_weapon_changed(_new_weapon: Weapon) -> void:
	# Update ammo display when the player changes weapon
	_update_ammo_display()
	_update_slots_display()

func _update_slots_display() -> void:
	# Update the weapon slots selection highlight
	for slot: TextureRect in %Slots.get_children():
		if slot.get_index() == player.current_weapon_slot:
			slot.texture = preload("res://Resources/ui_slot_selected.tres")
			slot.get_node("Selected").visible = true
		else:
			slot.texture = preload("res://Resources/ui_slot.tres")
			slot.get_node("Selected").visible = false

	# Update the weapon icons in the slots
	for slot: TextureRect in %Slots.get_children():
		var weapon = player.slots[slot.get_index()]
		var slot_texture: TextureRect = slot.get_node("WeaponTexture")
		if weapon:
			slot_texture.texture = weapon.sprite
		else:
			slot_texture.texture = null

func _on_player_aim_state_changed(is_lerping: bool) -> void:
	# Update cursor based on aiming state
	if is_lerping:
		Input.set_custom_mouse_cursor(lerping_cursor, Input.CURSOR_ARROW, Vector2(32, 32))

	else:
		Input.set_custom_mouse_cursor(aiming_cursor, Input.CURSOR_ARROW, Vector2(32, 32))


func _on_player_health_changed(new_health: int) -> void:
	_update_lifebar(new_health)
	_update_health_overlay(new_health)

func _update_lifebar(new_health: int) -> void:
	lifebar.value = new_health
	# Update lifebar when the player's health changes
	lifebar.value = new_health
	if new_health <= 30:
		lifebar.add_theme_color_override("fg_color", Color.RED)
	else:
		lifebar.add_theme_color_override("fg_color", Color.GREEN)
	
	# Hide lifebar if health is full
	if new_health == lifebar.max_value:
		lifebar.visible = false
	else:
		lifebar.visible = true

func _update_health_overlay(new_health: int) -> void:
	# Calculate health percentage (0.0 to 1.0)
	var health_percentage = float(new_health) / float(player.max_health)
	
	# Calculate red overlay intensity with more dramatic scaling below 50%
	var red_alpha = 0.0
	
	if health_percentage > 0.5:
		# Above 50% health: very subtle red (0 to 0.1 alpha)
		red_alpha = (1.0 - health_percentage) * 0.2
	else:
		# Below 50% health: more dramatic red scaling (0.1 to 0.7 alpha)
		var low_health_factor = (0.5 - health_percentage) / 0.5 # 0.0 to 1.0 as health goes from 50% to 0%
		red_alpha = 0.1 + (low_health_factor * low_health_factor * 0.6) # Quadratic curve for more drama
	
	# Apply the red overlay with calculated alpha using modulate for TextureRect
	health_overlay.modulate = Color(1, 0, 0, red_alpha)
