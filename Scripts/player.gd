extends Entity
class_name Player

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
	MELEE_ATTACKING,
	RELOADING
}

# Signals for shooting and reloading
signal fired
signal reload_started
signal reload_finished

signal weapon_changed(new_weapon: Weapon)
signal aim_state_changed(is_lerping: bool)

@export var speed: float = 300.0
@export var sprint_multiplier: float = 1.5

# Health regeneration variables
@export var health_regen_delay: float = 5.0 # Time in seconds to wait before regenerating
@export var health_regen_rate: float = 2.0 # Health points per second to regenerate
var _time_since_last_hit: float = 0.0
var _is_regenerating: bool = false

@onready var muzzle: Node2D = $Muzzle
@onready var feet_sprite: AnimatedSprite2D = $FeetSprite
@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var melee_area: Area2D = %MeleeRange

@onready var gun_sfx: AudioStreamPlayer2D = %GunSFX
@onready var player_sfx: AudioStreamPlayer2D = %PlayerSFX
var footsteps

# Footstep variables
var footstep_timer: float = 0.0
var footstep_interval: float = 0.4 # Time between footsteps in seconds

## rotation speed multiplier
@export var rotation_speed: float = 10.0
## how close rotation needs to snap to mouse direction (in radians)
@export var aim_tolerance: float = 0.1

var _is_lerping_aim: bool = false
var _previous_lerp_state: bool = false

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
var _is_aiming_with_mouse: bool = true

var _is_melee_attacking: bool = false

# Cached analog stick input to avoid duplicate reads
var _cached_rotation_input: Vector2
var _rotation_input_frame: int = -1

# Animation state tracking
var current_player_state: PlayerState = PlayerState.IDLE
var current_body_state: BodyState = BodyState.IDLE
var previous_player_state: PlayerState = PlayerState.IDLE
var previous_body_state: BodyState = BodyState.IDLE

func _ready() -> void:
	# Call parent _ready to initialize health
	super._ready()
	
	# DEBUG
	# Give player some starting ammo and a rifle
	pick_up_weapon(load("res://Resources/Weapons/BaseRifle.tres"))
	pick_up_weapon(load("res://Resources/Weapons/BasePistol.tres"))
	pick_up_weapon(load("res://Resources/Weapons/Knife.tres"))
	pick_up_weapon(load("res://Resources/Weapons/BaseShotgun.tres"))
	inventory["rifle_ammo"] = 90
	inventory["pistol_ammo"] = 60
	inventory["shotgun_ammo"] = 32

	# Load a few footstep sounds
	footsteps = [
		load("res://Arts/Sounds/FreeSteps/Tiles/Steps_tiles-001.ogg"),
		load("res://Arts/Sounds/FreeSteps/Tiles/Steps_tiles-005.ogg"),
		load("res://Arts/Sounds/FreeSteps/Tiles/Steps_tiles-010.ogg"),
		load("res://Arts/Sounds/FreeSteps/Tiles/Steps_tiles-015.ogg")
	]

	
	# Connect animation finished signal
	body_sprite.animation_finished.connect(_on_animation_finished)
	body_sprite.frame_changed.connect(_on_body_frame_changed) ## Get analog stick input, cached per frame to avoid duplicate reads
func _get_rotation_input() -> Vector2:
	var current_frame = Engine.get_process_frames()
	if _rotation_input_frame != current_frame:
		_cached_rotation_input.x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		_cached_rotation_input.y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		_rotation_input_frame = current_frame
	return _cached_rotation_input

func _physics_process(delta: float) -> void:
	# Handle health regeneration
	_handle_health_regeneration(delta)
	
	# Handle shoot animation timer
	if _is_shooting:
		_shoot_timer -= delta
		if _shoot_timer <= 0.0:
			_is_shooting = false

	# Handle footstep timer
	footstep_timer -= delta

	# Get input direction
	var input_direction = Vector2()

	# Check for movement input
	if Input.is_action_pressed("moveLeft"):
		input_direction.x -= 1
	if Input.is_action_pressed("moveRight"):
		input_direction.x += 1
	if Input.is_action_pressed("moveUp"):
		input_direction.y -= 1
	if Input.is_action_pressed("moveDown"):
		input_direction.y += 1
	
	_is_sprinting = Input.is_action_pressed("sprint")
	# TODO: sprint last some seconds, then it goes on cooldown
	
	
	if input_direction.length() > 0:
		# Normalize diagonal movement
		input_direction = input_direction.normalized()
		velocity = input_direction * speed
		velocity *= sprint_multiplier if _is_sprinting else 1.0
		
		# Play footsteps while moving
		if footstep_timer <= 0.0:
			play_random_footstep()
			footstep_timer = footstep_interval
	else:
		velocity = Vector2.ZERO
	

	# Handle rotation input (right analog stick or mouse)
	var rotation_input = _get_rotation_input()
	var target_angle: float

	# Determine if aiming with mouse
	
	if Input.get_last_mouse_velocity().length() > 0.1:
		_is_aiming_with_mouse = true
	
	if rotation_input.length() > 0.1: # Deadzone for analog stick
		# Hide cursor:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		_is_aiming_with_mouse = false
		# Use right analog stick for rotation
		target_angle = rotation_input.angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
	elif _is_aiming_with_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		# Fall back to mouse rotation when no analog stick input
		var mouse_position = get_global_mouse_position()
		var direction_to_mouse = (mouse_position - global_position).normalized()
		target_angle = direction_to_mouse.angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
	
	var angle_diff = abs(angle_difference(rotation, target_angle))
	_is_lerping_aim = angle_diff > aim_tolerance

	# Emit signal when aim state changes
	if _is_lerping_aim != _previous_lerp_state:
		aim_state_changed.emit(_is_lerping_aim)
		_previous_lerp_state = _is_lerping_aim

	# Move the character
	move_and_slide()

	# Update animation states
	_update_player_states()
	_update_animations()

	# Handle reload input
	if Input.is_action_just_pressed("reload"):
		if not _is_reloading and not _is_melee_attacking and slots[current_weapon_slot] and get_current_weapon_ammo() > 0:
			_start_reload()
		elif _is_reloading and slots[current_weapon_slot] and slots[current_weapon_slot].type == Weapon.WeaponType.SHOTGUN:
			# Allow interrupting shotgun reload
			_interrupt_reload()

	# Handle shooting
	_cooldown = max(0.0, _cooldown - delta)
	if Input.is_action_pressed("shoot") and _cooldown == 0.0 and not _is_melee_attacking:
		# Check if we're reloading and have a shotgun - allow interrupting shotgun reload
		if _is_reloading and slots[current_weapon_slot] and slots[current_weapon_slot].type == Weapon.WeaponType.SHOTGUN:
			_interrupt_reload()
		
		if not _is_reloading:
			# Check if we are using a melee weapon
			if slots[current_weapon_slot] and slots[current_weapon_slot].type == Weapon.WeaponType.MELEE:
				_perform_melee_attack()
			# Check if we have a weapon equipped and ammo in the magazine
			elif slots[current_weapon_slot] and slots[current_weapon_slot].current_ammo > 0:
				_is_shooting = true
				var frame_count = body_sprite.sprite_frames.get_frame_count("shoot")
				var animation_speed = body_sprite.sprite_frames.get_animation_speed("shoot")
				_shoot_timer = frame_count / animation_speed
				shoot()
				_cooldown = 1.0 / slots[current_weapon_slot].fire_rate
				slots[current_weapon_slot].current_ammo -= 1
				fired.emit()
			elif get_current_weapon_ammo() > 0:
				# Auto-reload when trying to shoot with empty magazine
				_start_reload()

	## Handle weapon switching
	if Input.is_action_just_pressed("equip1"):
		equip_weapon(0)
	if Input.is_action_just_pressed("equip2"):
		equip_weapon(1)
	if Input.is_action_just_pressed("equip3"):
		equip_weapon(2)

	if Input.is_action_just_pressed("melee_attack"):
		# Cancel reload if currently reloading
		if _is_reloading:
			_interrupt_reload()
		_perform_melee_attack()

func _interrupt_reload() -> void:
	_is_reloading = false
	reload_finished.emit()

func _perform_melee_attack() -> void:
	_is_melee_attacking = true
	# Damage will be dealt in _on_body_frame_changed when animation reaches the right frame

## Shoot 1 bullet
func shoot() -> void:
	# Use cached rotation input to avoid duplicate reads
	var rotation_input = _get_rotation_input()
	var target_angle: float
	var aiming_direction: Vector2
	
	if rotation_input.length() > 0.1: # Using analog stick
		target_angle = rotation_input.angle()
		aiming_direction = rotation_input.normalized()
	else: # Fall back to mouse
		var target := get_global_mouse_position()
		aiming_direction = (target - muzzle.global_position).normalized()
		target_angle = aiming_direction.angle()
	
	# Check if player is properly aimed
	var angle_diff: float = abs(angle_difference(rotation, target_angle))
	
	var bullet_direction: Vector2
	if angle_diff <= aim_tolerance:
		# Player is properly aimed - shoot towards target direction
		bullet_direction = aiming_direction
	else:
		# Player not fully rotated - shoot in current facing direction
		bullet_direction = Vector2.RIGHT.rotated(rotation)
	

	if slots[current_weapon_slot].type == Weapon.WeaponType.SHOTGUN:
		var pellet_count = 10
		for i in range(pellet_count):
			var p := slots[current_weapon_slot].bullet_scene.instantiate()
			p.global_position = muzzle.global_position
			p.direction = bullet_direction
			p.rotation = bullet_direction.angle()
			p.damage = slots[current_weapon_slot].damage
			get_tree().current_scene.add_child(p)
	else:
		var b := slots[current_weapon_slot].bullet_scene.instantiate()

		b.global_position = muzzle.global_position
		b.direction = bullet_direction
		b.rotation = bullet_direction.angle()
		b.damage = slots[current_weapon_slot].damage
		get_tree().current_scene.add_child(b)
	
	# Play weapon-specific gun sound effect
	if slots[current_weapon_slot].fire_sound != null:
		gun_sfx.stream = slots[current_weapon_slot].fire_sound
		gun_sfx.play()

func _start_reload() -> void:
	if _is_reloading:
		return
	
	reload_started.emit()
	_is_reloading = true

func _finish_reload() -> void:
	var bullets_to_reload: int
	if slots[current_weapon_slot].type == Weapon.WeaponType.SHOTGUN:
		# Shotguns reload one shell at a time
		bullets_to_reload = min(1, get_current_weapon_ammo())
		
		# Update ammo counts
		slots[current_weapon_slot].current_ammo += bullets_to_reload
		set_current_weapon_ammo(get_current_weapon_ammo() - bullets_to_reload)
		
		# Check if we need to continue reloading (magazine not full and have ammo)
		var magazine_full = slots[current_weapon_slot].current_ammo >= slots[current_weapon_slot].magazine_size
		var has_ammo = get_current_weapon_ammo() > 0
		
		if not magazine_full and has_ammo:
			# Continue reloading - play reload animation again
			body_sprite.play("reload")
			reload_started.emit()
			return # Don't set _is_reloading to false or emit reload_finished yet
		else:
			# Magazine is full or no more ammo - finish reloading
			_is_reloading = false
			reload_finished.emit()
	else:
		# Calculate how many bullets to reload for non-shotgun weapons
		var bullets_needed = slots[current_weapon_slot].magazine_size - slots[current_weapon_slot].current_ammo
		bullets_to_reload = min(bullets_needed, get_current_weapon_ammo())
		
		# Update ammo counts
		slots[current_weapon_slot].current_ammo += bullets_to_reload
		set_current_weapon_ammo(get_current_weapon_ammo() - bullets_to_reload)
		
		# Finish reloading for non-shotgun weapons
		_is_reloading = false
		reload_finished.emit()

func _on_animation_finished() -> void:
	# Check if the finished animation was "reload"
	if body_sprite.animation == "reload" and _is_reloading:
		_finish_reload()
	if body_sprite.animation == "melee_attack" and _is_melee_attacking:
		_is_melee_attacking = false

func _on_body_frame_changed() -> void:
	# Apply melee damage at a specific frame of the melee attack animation
	if body_sprite.animation == "melee_attack" and body_sprite.frame == 10 and _is_melee_attacking:
		# Get damage value
		var damage = 0
		if slots[current_weapon_slot] != null and slots[current_weapon_slot].type == Weapon.WeaponType.MELEE:
			damage = slots[current_weapon_slot].damage
		else:
			# Default punch/unarmed damage if no melee weapon equipped
			damage = 25
		
		# Check for all bodies currently in the melee area and damage them
		var overlapping_bodies = melee_area.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body is Zombie:
				(body as Zombie).take_damage(damage)

func _update_player_states() -> void:
	# Determine body state (higher priority)
	if _is_reloading:
		current_body_state = BodyState.RELOADING
	elif _is_shooting:
		current_body_state = BodyState.SHOOTING
	elif _is_melee_attacking:
		current_body_state = BodyState.MELEE_ATTACKING
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
			BodyState.MELEE_ATTACKING:
				body_sprite.play("melee_attack")
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
	if slots[current_weapon_slot] == null:
		return 0
	var weapon_type = _get_weapon_type_string(slots[current_weapon_slot].type)
	return inventory[weapon_type + "_ammo"] if inventory.has(weapon_type + "_ammo") else 0

func set_current_weapon_ammo(amount: int) -> void:
	if slots[current_weapon_slot] == null:
		return
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
			return "knife" # fallback

func equip_weapon(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slots.size():
		push_error("Invalid weapon slot index: %d" % slot_index)
		return
	if _is_reloading:
		_interrupt_reload()

	current_weapon_slot = slot_index

	weapon_changed.emit(slots[current_weapon_slot])

	if slots[slot_index] == null:
		if inventory.has("knife"):
			body_sprite.sprite_frames = load("res://Resources/Sprite Frames/knife.tres")
		else:
			body_sprite.sprite_frames = load("res://Resources/Sprite Frames/flashlight.tres")
	else:
		body_sprite.sprite_frames = load("res://Resources/Sprite Frames/" + _get_weapon_type_string(slots[current_weapon_slot].type) + ".tres")

func pick_up_weapon(new_weapon: Weapon) -> bool:
	# Check for empty slot first
	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = new_weapon
			equip_weapon(i)
			return true

	# No empty slots - replace current weapon
	slots[current_weapon_slot] = new_weapon
	equip_weapon(current_weapon_slot)
	return true

# Override take_damage to reset regeneration timer
func take_damage(amount: int) -> void:
	super.take_damage(amount) # Call parent implementation
	_time_since_last_hit = 0.0 # Reset the timer
	_is_regenerating = false # Stop any current regeneration

# Handle health regeneration logic
func _handle_health_regeneration(delta: float) -> void:
	# Always increment time since last hit
	_time_since_last_hit += delta
	
	# Check if enough time has passed since last hit and we're not at full health
	if health < max_health and _time_since_last_hit >= health_regen_delay:
		if not _is_regenerating:
			_is_regenerating = true
			# You could add a visual indicator here that regeneration started
		
		# Regenerate health
		var health_to_add = health_regen_rate * delta
		health = min(health + health_to_add, max_health)
		
		# Stop regenerating when at full health
		if health >= max_health:
			_is_regenerating = false

# Play a random footstep sound
func play_random_footstep() -> void:
	if footsteps.size() > 0:
		var random_index = randi() % footsteps.size()
		player_sfx.stream = footsteps[random_index]
		player_sfx.play()
