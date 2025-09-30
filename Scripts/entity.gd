extends CharacterBody2D
class_name Entity

signal health_changed(new_health: int)

@export var max_health: int = 100
var _health: float
var health: float:
	get:
		return _health
	set(value):
		var new_health = clamp(value, 0, max_health)
		if _health != new_health:
			_health = new_health
			health_changed.emit(int(_health))
var _is_dead: bool = false

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health -= amount
	modulate = Color(1, 0, 0) # Flash red on hit
	
	if health <= 0 and not _is_dead:
		_is_dead = true
		die()
		return
	
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1) # Reset color

func die() -> void:
	# Placeholder for death logic
	print(name + " has died.")
	queue_free()
	pass
