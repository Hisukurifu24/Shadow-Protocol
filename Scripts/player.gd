extends CharacterBody2D

# Animation state enums
enum PlayerState {
	IDLE,
	WALKING,
	SPRINTING,
	STRAFING_LEFT,
	STRAFING_RIGHT
}

enum BodyState {
	IDLE,
	MOVING,
	SHOOTING,
	RELOADING
}

@export var speed: float = 300.0
@export var sprint_multiplier: float = 1.5

@onready var muzzle: Node2D = $Muzzle
@onready var feet_sprite: AnimatedSprite2D = $FeetSprite
@onready var body_sprite: AnimatedSprite2D = $BodySprite

## rotation speed multiplier
@export var rotation_speed: float = 5.0
## how close rotation needs to snap to mouse direction (in radians)
@export var aim_tolerance: float = 0.1

# Ammo and reload system
var _is_reloading: bool = false

var inventory: Dictionary = {
	"pistol_ammo": 0,
	"rifle_ammo": 0,
	"shotgun_ammo": 0
	# TODO: Add more items like medkits, grenades, etc. 
}
var slots: Array[Weapon] = [null, null, null] # Three weapon slots
var current_weapon_slot: int = 0

var _cooldown := 0.0
var _is_shooting := false
var _shoot_timer := 0.0

var _is_sprinting := false

# Animation state tracking
var current_player_state: PlayerState = PlayerState.IDLE
var current_body_state: BodyState = BodyState.IDLE
var previous_player_state: PlayerState = PlayerState.IDLE
var previous_body_state: BodyState = BodyState.IDLE

func _ready() -> void:
	# DEBUG
	# Give player some starting ammo and a rifle
	slots[0] = load("res://Resources/Weapons/BaseRifle.tres")
	equip_weapon(0)
	inventory["rifle_ammo"] = 90
	
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
		# Normalize diagonal movement
		input_direction = input_direction.normalized()
		velocity = input_direction * speed
		velocity *= sprint_multiplier if _is_sprinting else 1.0
	else:
		velocity = Vector2.ZERO
	

	# Rotate player towards mouse position smoothly
	var mouse_position = get_global_mouse_position()
	var direction_to_mouse = (mouse_position - global_position).normalized()
	var target_angle = direction_to_mouse.angle()
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

	# Move the character
	move_and_slide()

	# Update animation states
	_update_player_states()
	_update_animations()

	# Handle reload input
	if Input.is_action_just_pressed("reload") and not _is_reloading and slots[current_weapon_slot] != null and get_current_weapon_ammo() > 0:
		_start_reload()

	# Handle shooting
	_cooldown = max(0.0, _cooldown - delta)
	if Input.is_action_pressed("shoot") and _cooldown == 0.0 and not _is_reloading:
		if slots[current_weapon_slot].current_ammo > 0:
			_is_shooting = true
			var frame_count = body_sprite.sprite_frames.get_frame_count("shoot")
			var animation_speed = body_sprite.sprite_frames.get_animation_speed("shoot")
			_shoot_timer = frame_count / animation_speed
			shoot()
			_cooldown = 1.0 / slots[current_weapon_slot].fire_rate
			slots[current_weapon_slot].current_ammo -= 1
			# Debug: Print ammo status when shooting
			if slots[current_weapon_slot].current_ammo % 5 == 0 or slots[current_weapon_slot].current_ammo <= 5: # Print every 5 shots or when low
				print("Ammo: " + str(slots[current_weapon_slot].current_ammo) + "/" + str(slots[current_weapon_slot].magazine_size) + " (Total: " + str(get_current_weapon_ammo()) + ")")
		elif get_current_weapon_ammo() > 0:
			# Auto-reload when trying to shoot with empty magazine
			_start_reload()

## Shoot 1 bullet
func shoot() -> void:
	var b := slots[current_weapon_slot].bullet_scene.instantiate()
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
	if _is_reloading or get_current_weapon_ammo() <= 0:
		return
	
	_is_reloading = true
	print("Reloading... - Current: " + str(slots[current_weapon_slot].current_ammo) + "/" + str(slots[current_weapon_slot].magazine_size) + " Total: " + str(get_current_weapon_ammo()) + ")")

func _finish_reload() -> void:
	_is_reloading = false
	
	# Calculate how many bullets to reload
	var bullets_needed = slots[current_weapon_slot].magazine_size - slots[current_weapon_slot].current_ammo
	var bullets_to_reload = min(bullets_needed, get_current_weapon_ammo())
	
	# Update ammo counts
	slots[current_weapon_slot].current_ammo += bullets_to_reload
	set_current_weapon_ammo(get_current_weapon_ammo() - bullets_to_reload)

	print("Reload complete! Ammo: " + str(slots[current_weapon_slot].current_ammo) + "/" + str(slots[current_weapon_slot].magazine_size) + " (Total: " + str(get_current_weapon_ammo()) + ")")

func _on_animation_finished() -> void:
	# Check if the finished animation was "reload"
	if body_sprite.animation == "reload" and _is_reloading:
		_finish_reload()

func _update_player_states() -> void:
	# Determine body state (higher priority)
	if _is_reloading:
		current_body_state = BodyState.RELOADING
	elif _is_shooting:
		current_body_state = BodyState.SHOOTING
	elif velocity.length() > 0:
		current_body_state = BodyState.MOVING
	else:
		current_body_state = BodyState.IDLE
	
	# Determine player/feet state
	if velocity.length() == 0:
		current_player_state = PlayerState.IDLE
	else:
		var facing_direction = Vector2.RIGHT.rotated(rotation)
		var dot_product = velocity.normalized().dot(facing_direction)
		var cross_product = velocity.normalized().cross(facing_direction)
		var is_strafing = abs(dot_product) < 0.7 and abs(cross_product) > 0.3
		
		if is_strafing:
			current_player_state = PlayerState.STRAFING_LEFT if cross_product > 0 else PlayerState.STRAFING_RIGHT
		elif _is_sprinting:
			current_player_state = PlayerState.SPRINTING
		else:
			current_player_state = PlayerState.WALKING

func _update_animations() -> void:
	# Update body animations only when state changes
	if current_body_state != previous_body_state:
		match current_body_state:
			BodyState.IDLE:
				body_sprite.play("idle")
			BodyState.MOVING:
				body_sprite.play("move")
			BodyState.SHOOTING:
				body_sprite.play("shoot")
			BodyState.RELOADING:
				body_sprite.play("reload")
		
		previous_body_state = current_body_state
	
	# Update feet animations only when state changes
	if current_player_state != previous_player_state:
		match current_player_state:
			PlayerState.IDLE:
				feet_sprite.play("idle")
			PlayerState.WALKING:
				feet_sprite.play("walk")
			PlayerState.SPRINTING:
				feet_sprite.play("sprint")
			PlayerState.STRAFING_LEFT:
				feet_sprite.play("strafe_left")
			PlayerState.STRAFING_RIGHT:
				feet_sprite.play("strafe_right")
		
		previous_player_state = current_player_state


func get_current_weapon_ammo() -> int:
	var weapon_type = _get_weapon_type_string(slots[current_weapon_slot].type)
	return inventory[weapon_type + "_ammo"]

func set_current_weapon_ammo(amount: int) -> void:
	var weapon_type = _get_weapon_type_string(slots[current_weapon_slot].type)
	inventory[weapon_type + "_ammo"] = amount

func _get_weapon_type_string(weapon_type: Weapon.WeaponType) -> String:
	match weapon_type:
		Weapon.WeaponType.PISTOL:
			return "pistol"
		Weapon.WeaponType.RIFLE:
			return "rifle"
		Weapon.WeaponType.SHOTGUN:
			return "shotgun"
		_:
			return "pistol" # fallback

func equip_weapon(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slots.size():
		return
	if slots[slot_index] == null:
		return
	
	current_weapon_slot = slot_index
	body_sprite.sprite_frames = load("res://Resources/Sprite Frames/" + _get_weapon_type_string(slots[current_weapon_slot].type) + ".tres")
