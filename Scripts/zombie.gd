extends Entity
class_name Zombie


var speed: float = 100.0
var player: Player
var attack_cooldown: float = 1.5 # Time between attacks in seconds
var attack_timer: float = 0.0 # Timer to track cooldown
var _is_attacking: bool = false
var attack_range: float = 50.0

@onready var sprite = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	player = get_node("/root/World/Player")
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	var direction_to_player = (player.global_position - global_position).normalized()
	
	# Rotate zombie to face the player
	var target_rotation = direction_to_player.angle()
	rotation = lerp_angle(rotation, target_rotation, 5.0 * delta)
	
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# If currently attacking, don't change state until attack is finished
	if _is_attacking:
		velocity = Vector2.ZERO
		return
	
	if distance_to_player > attack_range:
		# Move towards the player
		velocity = direction_to_player * speed
		sprite.play("move")
	else:
		velocity = Vector2.ZERO
		# Attack only if cooldown has elapsed and not already attacking
		if attack_timer <= 0:
			_attack()
			attack_timer = attack_cooldown # Reset the cooldown timer
		else:
			sprite.play("idle") # Play idle animation when not attacking and not on cooldown
	
	move_and_slide()

func _on_animation_finished() -> void:
	if sprite.animation == "attack":
		_is_attacking = false

func _on_frame_changed() -> void:
	# Apply damage at a specific frame of the attack animation
	if sprite.animation == "attack" and sprite.frame == 5:
		player.take_damage(10)

func _attack() -> void:
	# Attack logic with cooldown handled in _physics_process
	sprite.play("attack")
	_is_attacking = true
