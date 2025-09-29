extends Area2D
class_name Projectile

@export var speed: float = 900.0
@export var lifetime: float = 1.5
var damage: int = 10
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	monitoring = true
	
	body_entered.connect(_on_body_entered)

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Zombie:
		(body as Zombie).take_damage(damage)
	queue_free()