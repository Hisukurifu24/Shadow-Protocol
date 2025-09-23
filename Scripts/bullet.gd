extends Area2D

@export var speed: float = 900.0
@export var lifetime: float = 1.5
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	# TODO: apply damage if the body supports it
	queue_free()