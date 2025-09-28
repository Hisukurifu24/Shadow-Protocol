extends Resource
class_name Weapon

@export var name: String = "Pistol"
## Icon for the weapon
@export var sprite: Texture2D
## Type of the weapon
@export var type: WeaponType = WeaponType.PISTOL
## Damage per bullet, default is 10
@export var damage: int = 10
## Fire rate in bullets per second
@export var fire_rate: float = 10.0
## Reload time multiplier
@export var reload_time: float = 1.0
## Size of the magazine
@export var magazine_size: int = 12: set = set_magazine_size
## Current ammo in the magazine
var current_ammo: int
## Speed of the bullet
@export var bullet_speed: float = 800.0
## Scene for the bullet
@export var bullet_scene: PackedScene = preload("res://Scenes/Bullet.tscn")

func _init():
	current_ammo = magazine_size

func set_magazine_size(value: int):
	magazine_size = value
	current_ammo = magazine_size

enum WeaponType {
	PISTOL,
	RIFLE,
	SHOTGUN,
	MELEE
}
