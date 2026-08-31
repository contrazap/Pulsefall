extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal died(enemy: Node)

@export_range(1.0, 1000.0, 1.0) var movement_speed: float = 135.0
@export_range(1, 10000, 1) var maximum_health: int = 30
@export_range(1, 1000, 1) var contact_damage: int = 12
@export_range(1.0, 256.0, 1.0) var contact_range: float = 38.0
@export_range(1.0, 256.0, 1.0) var enemy_separation_radius: float = 48.0
@export_range(0.0, 1000.0, 1.0) var enemy_separation_strength: float = 115.0
@export_range(1.0, 256.0, 1.0) var player_separation_radius: float = 46.0
@export_range(0.0, 1000.0, 1.0) var player_separation_strength: float = 190.0

var target: Node2D
var current_health: int
var _is_dead: bool = false


func _ready() -> void:
	current_health = maximum_health


func _physics_process(_delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return
	refresh_chase_velocity()
	move_and_slide()
	_try_contact_damage()


func set_target(next_target: Node2D) -> void:
	target = next_target


func refresh_chase_velocity() -> void:
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	velocity = calculate_chase_velocity(target.global_position) + calculate_separation_velocity()
	velocity = velocity.limit_length(movement_speed + maxf(enemy_separation_strength, player_separation_strength))


func calculate_chase_velocity(target_position: Vector2) -> Vector2:
	var direction := global_position.direction_to(target_position)
	return direction * movement_speed


func calculate_separation_velocity() -> Vector2:
	var separation := Vector2.ZERO
	for candidate: Node in get_tree().get_nodes_in_group(&"normal_enemies"):
		if candidate == self or not candidate is Node2D:
			continue
		var other := candidate as Node2D
		var offset := global_position - other.global_position
		var distance := offset.length()
		if distance >= enemy_separation_radius:
			continue
		var direction := offset / distance if distance > 0.001 else _stable_separation_direction(other)
		separation += direction * enemy_separation_strength * (1.0 - distance / enemy_separation_radius)

	if is_instance_valid(target):
		var player_offset := global_position - target.global_position
		var player_distance := player_offset.length()
		if player_distance < player_separation_radius:
			var player_direction := player_offset / player_distance if player_distance > 0.001 else _stable_separation_direction(target)
			separation += player_direction * player_separation_strength * (1.0 - player_distance / player_separation_radius)
	return separation


func take_damage(amount: int) -> bool:
	if amount <= 0 or _is_dead:
		return false
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, maximum_health)
	if current_health == 0:
		_is_dead = true
		remove_from_group(&"normal_enemies")
		died.emit(self)
		queue_free()
	return true


func is_alive() -> bool:
	return not _is_dead


func _try_contact_damage() -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	if global_position.distance_to(target.global_position) <= contact_range:
		target.call("take_damage", contact_damage)


func _stable_separation_direction(other: Node) -> Vector2:
	var self_id := get_instance_id()
	var other_id := other.get_instance_id()
	var lower_id := mini(self_id, other_id)
	var higher_id := maxi(self_id, other_id)
	var angle := float(posmod(lower_id * 31 + higher_id * 17, 360)) * TAU / 360.0
	var pair_direction := Vector2.RIGHT.rotated(angle)
	return pair_direction if self_id < other_id else -pair_direction
