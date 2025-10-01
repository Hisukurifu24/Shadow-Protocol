extends Node
class_name GameManager

var current_round: int = 0
var score: int = 0
var zombies_alive: int = 0
var zombies_to_spawn: int = 0
var zombies_spawned: int = 0
var zombie_scene: PackedScene = preload("res://Scenes/zombie.tscn")

var time_between_rounds: float = 5.0
var time_between_spawns: float = 1.0 # Time between each zombie spawn
var spawn_timer: Timer

signal zombie_died
signal round_started(new_round: int, zombies_alive: int)
signal round_ended()

func _ready():
	zombie_died.connect(_on_zombie_died)
	
	# Create and setup the spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = time_between_spawns
	spawn_timer.timeout.connect(_spawn_single_zombie)
	add_child(spawn_timer)

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
	zombies_spawned = 0
	zombies_alive = zombies_to_spawn
	
	# Start spawning zombies gradually
	round_started.emit(current_round, zombies_alive)
	_spawn_single_zombie() # Spawn the first zombie immediately
	
	# Start the timer for subsequent spawns if there are more zombies to spawn
	if zombies_to_spawn > 1:
		spawn_timer.start()

func _spawn_single_zombie():
	if zombies_spawned < zombies_to_spawn:
		var zombie_instance = zombie_scene.instantiate()

		# Scale zombie health with the round number
		zombie_instance.max_health += (current_round - 1) * 10
		zombie_instance.health = zombie_instance.max_health

		# Get player reference and position
		var player = get_node("/root/World/Player")
		var player_position = player.global_position if player else Vector2.ZERO
		
		# Spawn zombies at random positions within a 2000x2000 area centered around the player
		var spawn_position = player_position + Vector2(randf() * 2000 - 1000, randf() * 2000 - 1000)
		zombie_instance.global_position = spawn_position

		# Add the zombie to the scene tree
		get_node("/root/World").add_child(zombie_instance)
		
		zombies_spawned += 1
		
		# Stop the timer if all zombies have been spawned
		if zombies_spawned >= zombies_to_spawn:
			spawn_timer.stop()

func prepare_for_next_round():
	await get_tree().create_timer(time_between_rounds).timeout
	_start_next_round()
