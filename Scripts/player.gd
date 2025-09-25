extends CharacterBody2D

@export var speed: float = 300.0
@export var sprint_multiplier: float = 1.5

const BULLET := preload("res://scenes/Bullet.tscn")
@onready var muzzle: Node2D = $Muzzle if has_node("Muzzle") else self
@onready var feet_sprite: AnimatedSprite2D = $FeetSprite
@onready var body_sprite: AnimatedSprite2D = $BodySprite

@export var fire_rate: float = 8.0 # bullets per second
@export var rotation_speed: float = 5.0 # rotation speed multiplier
@export var shoot_animation_duration: float = 0.3 # duration of shoot animation in seconds
@export var aim_tolerance: float = 0.1 # how close rotation needs to be to mouse direction (in radians)

# Ammo and reload system
@export var max_magazine_size: int = 30 # bullets per magazine
@export var total_ammo: int = 150 # total spare ammo
var current_ammo: int = 30 # current bullets in magazine
var _is_reloading: bool = false

var _cooldown := 0.0
var _is_shooting := false
var _shoot_timer := 0.0

var _is_sprinting := false

func _ready() -> void:
	# Initialize ammo
	current_ammo = max_magazine_size
	
	# Connect animation finished signal
	body_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Handle shoot animation timer
	if _is_shooting:
		_shoot_timer -= delta
		if _shoot_timer <= 0.0:
			_is_shooting = false

	# Get input direction
	var input_direction = Vector2()
	
	# Check for WASD input
	if Input.is_action_pressed("moveLeft"):
		input_direction.x -= 1
	if Input.is_action_pressed("moveRight"):
		input_direction.x += 1
	if Input.is_action_pressed("moveUp"):
		input_direction.y -= 1
	if Input.is_action_pressed("moveDown"):
		input_direction.y += 1
	
	if Input.is_action_pressed("sprint"):
		_is_sprinting = true
	else:
		_is_sprinting = false
	
	
	if input_direction.length() > 0:
		# Calculate if player is strafing (moving perpendicular to facing direction)
		var facing_direction = Vector2.RIGHT.rotated(rotation)
		var dot_product = input_direction.dot(facing_direction)
		var cross_product = input_direction.cross(facing_direction)
		
		# Check if movement is more perpendicular than forward/backward (dot product close to 0)
		var is_strafing = abs(dot_product) < 0.7 and abs(cross_product) > 0.3
		
		if is_strafing:
			# Determine strafe direction based on cross product sign
			if cross_product > 0:
				feet_sprite.play("strafe_left")
			else:
				feet_sprite.play("strafe_right")
		elif _is_sprinting:
			feet_sprite.play("sprint")
		else:
			feet_sprite.play("walk")

		if not body_sprite.is_playing():
			body_sprite.play("move")
		# Normalize diagonal movement
		input_direction = input_direction.normalized()
		velocity = input_direction * speed
		velocity *= sprint_multiplier if _is_sprinting else 1.0
	else:
		feet_sprite.play("idle")
		if not body_sprite.is_playing():
			body_sprite.play("idle")
		velocity = Vector2.ZERO
	

	# Rotate player towards mouse position smoothly
	var mouse_position = get_global_mouse_position()
	var direction_to_mouse = (mouse_position - global_position).normalized()
	var target_angle = direction_to_mouse.angle()
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

	# Move the character
	move_and_slide()

	# Handle reload input
	if Input.is_action_just_pressed("reload") and not _is_reloading and current_ammo < max_magazine_size and total_ammo > 0:
		_start_reload()

	# Handle shooting
	_cooldown = max(0.0, _cooldown - delta)
	if Input.is_action_pressed("shoot") and _cooldown == 0.0 and not _is_reloading:
		if current_ammo > 0:
			_is_shooting = true
			_shoot_timer = shoot_animation_duration
			body_sprite.play("shoot")
			shoot()
			_cooldown = 1.0 / fire_rate
			current_ammo -= 1
			# Debug: Print ammo status when shooting
			if current_ammo % 5 == 0 or current_ammo <= 5: # Print every 5 shots or when low
				print("Ammo: " + str(current_ammo) + "/" + str(max_magazine_size) + " (Total: " + str(total_ammo) + ")")
		elif total_ammo > 0:
			# Auto-reload when trying to shoot with empty magazine
			_start_reload()

func shoot() -> void:
	var b := BULLET.instantiate()
	var target := get_global_mouse_position()
	var direction_to_mouse := (target - muzzle.global_position).normalized()
	var target_angle := direction_to_mouse.angle()
	
	# Check if player is properly aimed at the mouse
	var angle_diff: float = abs(angle_difference(rotation, target_angle))
	
	var bullet_direction: Vector2
	if angle_diff <= aim_tolerance:
		# Player is properly aimed - shoot towards mouse
		bullet_direction = direction_to_mouse
	else:
		# Player not fully rotated - shoot in current facing direction
		bullet_direction = Vector2.RIGHT.rotated(rotation)
	
	b.global_position = muzzle.global_position
	b.direction = bullet_direction
	b.rotation = bullet_direction.angle()
	get_tree().current_scene.add_child(b)

func _start_reload() -> void:
	if _is_reloading or total_ammo <= 0:
		return
	
	_is_reloading = true
	body_sprite.play("reload")
	print("Reloading... - Current: " + str(current_ammo) + "/" + str(max_magazine_size) + " Total: " + str(total_ammo))

func _finish_reload() -> void:
	_is_reloading = false
	
	# Calculate how many bullets to reload
	var bullets_needed = max_magazine_size - current_ammo
	var bullets_to_reload = min(bullets_needed, total_ammo)
	
	# Update ammo counts
	current_ammo += bullets_to_reload
	total_ammo -= bullets_to_reload
	
	print("Reload complete! Ammo: " + str(current_ammo) + "/" + str(max_magazine_size) + " (Total: " + str(total_ammo) + ")")

func _on_animation_finished() -> void:
	# Check if the finished animation was "reload"
	if body_sprite.animation == "reload" and _is_reloading:
		_finish_reload()

func get_ammo_info() -> Dictionary:
	return {
		"current_ammo": current_ammo,
		"max_magazine": max_magazine_size,
		"total_ammo": total_ammo,
		"is_reloading": _is_reloading
	}