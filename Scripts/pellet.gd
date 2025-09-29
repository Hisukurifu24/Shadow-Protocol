extends Area2D

@export var speed: float = 900.0
@export var lifetime: float = 1.5
@export var spread_angle: float = 0.1 # Random spread in radians (about 5.7 degrees)
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	
	# Add random spread to the direction
	var random_angle = randf_range(-spread_angle, spread_angle)
	direction = direction.rotated(random_angle)
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(_body: Node) -> void:
	# TODO: apply damage if the body supports it
	queue_free()