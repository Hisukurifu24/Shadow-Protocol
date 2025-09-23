extends CharacterBody2D

@export var speed: float = 300.0

const BULLET := preload("res://scenes/Bullet.tscn")
@onready var muzzle: Node2D = $Muzzle if has_node("Muzzle") else self
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

@export var fire_rate: float = 8.0 # bullets per second
var _cooldown := 0.0

func _physics_process(delta: float) -> void:
	# Get input direction
	var input_direction = Vector2()
	
	# Check for WASD input
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_direction.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_direction.y += 1
	
	# Normalize diagonal movement
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
		velocity = input_direction * speed
	else:
		velocity = Vector2.ZERO
	

	# Move the character
	move_and_slide()

	_cooldown = max(0.0, _cooldown - delta)
	if Input.is_action_pressed("shoot") and _cooldown == 0.0:
		shoot()
		_cooldown = 1.0 / fire_rate

func shoot() -> void:
	var b := BULLET.instantiate()
	var target := get_global_mouse_position()
	var direction_to_mouse := (target - muzzle.global_position).normalized()
	
	# Flip sprite based on shooting direction
	if sprite:
		sprite.flip_h = direction_to_mouse.x < 0
	
	# Add offset based on mouse direction (adjust offset_distance as needed)
	var offset_distance := 50 # pixels
	var spawn_offset := direction_to_mouse * offset_distance
	
	b.global_position = muzzle.global_position + spawn_offset
	b.direction = direction_to_mouse
	b.rotation = direction_to_mouse.angle()
	get_tree().current_scene.add_child(b)