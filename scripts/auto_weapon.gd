extends Node

@export var projectile_scene: PackedScene
@export_range(0.05, 60.0, 0.05) var fire_interval: float = 0.45
@export var projectile_container_path: NodePath = NodePath("../../Projectiles")
@export var target_group: StringName = &"combat_targets"
@export_range(0.0, 30.0, 0.5) var multishot_spread_degrees: float = 9.0

var _owner_body: Node2D
var _projectile_container: Node
var _fire_timer: Timer
var _multishot_rank: int = 0
var _piercing_rank: int = 0


func _ready() -> void:
	_owner_body = get_parent() as Node2D
	_projectile_container = get_node_or_null(projectile_container_path)
	_fire_timer = get_node_or_null("FireTimer") as Timer
	if _fire_timer == null:
		push_error("AutoWeapon requires a FireTimer child.")
		return
	_fire_timer.wait_time = fire_interval
	_fire_timer.timeout.connect(try_fire)
	_fire_timer.start()


func try_fire() -> Node2D:
	if projectile_scene == null or not is_instance_valid(_owner_body) or not is_instance_valid(_projectile_container):
		return null
	var target := find_nearest_target(_owner_body.global_position, get_tree().get_nodes_in_group(target_group))
	if target == null:
		return null
	var base_direction := _owner_body.global_position.direction_to(target.global_position)
	var first_projectile: Node2D
	for angle_offset: float in get_volley_angle_offsets():
		var projectile := projectile_scene.instantiate() as Node2D
		if projectile == null:
			push_error("AutoWeapon's projectile_scene must instantiate a Node2D.")
			continue
		_projectile_container.add_child(projectile)
		projectile.global_position = _owner_body.global_position
		projectile.call("configure", base_direction.rotated(deg_to_rad(angle_offset)), get_projectile_hit_allowance())
		if first_projectile == null:
			first_projectile = projectile
	return first_projectile


func set_combat_ranks(multishot_rank: int, piercing_rank: int) -> void:
	_multishot_rank = clampi(multishot_rank, 0, 2)
	_piercing_rank = clampi(piercing_rank, 0, 2)


func get_multishot_rank() -> int:
	return _multishot_rank


func get_piercing_rank() -> int:
	return _piercing_rank


func get_projectile_count() -> int:
	return 1 + _multishot_rank


func get_projectile_hit_allowance() -> int:
	return 1 + _piercing_rank


func get_volley_angle_offsets() -> Array[float]:
	var offsets: Array[float] = []
	var projectile_count := get_projectile_count()
	var first_offset := -multishot_spread_degrees * float(projectile_count - 1) * 0.5
	for index: int in range(projectile_count):
		offsets.append(first_offset + multishot_spread_degrees * float(index))
	return offsets


func find_nearest_target(origin: Vector2, candidates: Array[Node]) -> Node2D:
	var nearest: Node2D
	var nearest_distance_squared := INF
	for candidate: Node in candidates:
		if not candidate is Node2D or not is_instance_valid(candidate):
			continue
		if candidate.has_method("is_alive") and not candidate.call("is_alive"):
			continue
		var candidate_2d := candidate as Node2D
		var distance_squared := origin.distance_squared_to(candidate_2d.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = candidate_2d
			nearest_distance_squared = distance_squared
	return nearest
