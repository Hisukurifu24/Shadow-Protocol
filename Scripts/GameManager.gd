extends Node
class_name GameManager

var current_round: int = 0
var score: int = 0
var zombies_alive: int = 0
var zombies_to_spawn: int = 0
var zombie_scene: PackedScene = preload("res://Scenes/Zombie.tscn")

var time_between_rounds: float = 5.0

signal zombie_died
signal round_started(new_round: int, zombies_alive: int)
signal round_ended()

func _ready():
	zombie_died.connect(_on_zombie_died)

	# Update UI at the start
	round_ended.emit()


func _on_zombie_died():
	zombies_alive -= 1
	score += 10
	if zombies_alive == 0:
		round_ended.emit()
		prepare_for_next_round()

	
func _start_next_round():
	current_round += 1
	zombies_to_spawn = (int)(pow(2, current_round))
	zombies_alive = zombies_to_spawn
	for i in range(zombies_to_spawn):
		var zombie_instance = zombie_scene.instantiate()

		# Scale zombie health with the round number
		zombie_instance.max_health += (current_round - 1) * 10
		zombie_instance.health = zombie_instance.max_health

		# Spawn zombies at random positions within a 2000x2000 area centered around (0,0)
		var spawn_position = Vector2(randf() * 2000 - 1000, randf() * 2000 - 1000)
		zombie_instance.global_position = spawn_position

		# Add the zombie to the scene tree
		get_node("/root/World").add_child(zombie_instance)
	round_started.emit(current_round, zombies_alive)

func prepare_for_next_round():
	await get_tree().create_timer(time_between_rounds).timeout
	_start_next_round()
