extends Node2D

signal collected(xp_value: int)

@export_range(1, 10000, 1) var xp_value: int = 1
@export_range(1.0, 1024.0, 1.0) var attraction_radius: float = 150.0
@export_range(1.0, 256.0, 1.0) var collection_radius: float = 28.0
@export_range(1.0, 2000.0, 1.0) var movement_speed: float = 420.0

var target: Node2D
var _collected: bool = false
var _magnetized: bool = false


func _physics_process(delta: float) -> void:
	if _collected or not _has_valid_target():
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= collection_radius:
		collect()
		return
	if distance > attraction_radius and not _magnetized:
		return
	var travel_distance := minf(movement_speed * delta, distance)
	global_position += global_position.direction_to(target.global_position) * travel_distance
	if global_position.distance_to(target.global_position) <= collection_radius:
		collect()


func configure(next_target: Node2D, value: int = 1) -> void:
	target = next_target
	xp_value = maxi(value, 1)
	_magnetized = false


func add_xp_value(amount: int) -> void:
	if amount > 0 and not _collected:
		xp_value += amount


func activate_magnet() -> bool:
	if _collected or _magnetized or not _has_valid_target():
		return false
	_magnetized = true
	return true


func collect() -> bool:
	if _collected or xp_value <= 0:
		return false
	_collected = true
	collected.emit(xp_value)
	queue_free()
	return true


func is_collected() -> bool:
	return _collected


func is_magnetized() -> bool:
	return _magnetized


func _has_valid_target() -> bool:
	if not is_instance_valid(target):
		return false
	if target.has_method("is_alive") and not target.call("is_alive"):
		return false
	return true
