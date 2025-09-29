extends Projectile


@export var spread_angle: float = 0.1 # Random spread in radians (about 5.7 degrees)

func _ready() -> void:
	super._ready()
	# Add random spread to the direction
	var random_angle = randf_range(-spread_angle, spread_angle)
	direction = direction.rotated(random_angle)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
