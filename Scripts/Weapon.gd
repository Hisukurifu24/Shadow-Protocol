extends Resource
class_name Weapon

@export
var name: String = "Pistol"
var damage: int = 10
var fire_rate: float = 5.0 # bullets per second
var reload_time: float = 1.5 # seconds to reload
var magazine_size: int = 12 # bullets per magazine
var ammo_type: AmmoType = AmmoType.PISTOL
var bullet_speed: float = 800.0 # speed of the bullet

enum AmmoType {
    PISTOL,
    RIFLE,
    SHOTGUN
}