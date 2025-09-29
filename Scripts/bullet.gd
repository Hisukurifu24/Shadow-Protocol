extends Projectile

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
