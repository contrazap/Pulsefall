extends Node

signal pickup_collected(pickup_type: StringName)

const TYPE_HEALTH: StringName = &"health"
const TYPE_MAGNET: StringName = &"magnet"
const TYPE_BOMB: StringName = &"bomb"
const PICKUP_TYPES: Array[StringName] = [TYPE_HEALTH, TYPE_MAGNET, TYPE_BOMB]

@export var decoration_scene: PackedScene
@export var pickup_scene: PackedScene
@export var target_path: NodePath
@export var decoration_container_path: NodePath
@export var pickup_container_path: NodePath
@export_range(1, 100, 1) var maximum_decorations: int = 28
@export_range(1.0, 5000.0, 1.0) var decoration_minimum_distance: float = 180.0
@export_range(1.0, 5000.0, 1.0) var decoration_maximum_distance: float = 850.0
@export_range(1.0, 10000.0, 1.0) var decoration_retention_distance: float = 1050.0
@export_range(1, 12, 1) var maximum_pickups: int = 3
@export_range(1.0, 5000.0, 1.0) var pickup_minimum_distance: float = 260.0
@export_range(1.0, 5000.0, 1.0) var pickup_maximum_distance: float = 700.0
@export_range(1.0, 10000.0, 1.0) var pickup_retention_distance: float = 950.0
@export_range(1.0, 256.0, 1.0) var pickup_collection_radius: float = 42.0
@export_range(0.1, 30.0, 0.1) var refresh_interval: float = 0.75
@export_range(0.1, 60.0, 0.1) var pickup_spawn_interval: float = 8.0

var _target: Node2D
var _decoration_container: Node2D
var _pickup_container: Node2D
var _refresh_timer: Timer
var _pickup_spawn_timer: Timer
var _rng := RandomNumberGenerator.new()
var _pickup_bag: Array[StringName] = []


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D
	_decoration_container = get_node_or_null(decoration_container_path) as Node2D
	_pickup_container = get_node_or_null(pickup_container_path) as Node2D
	_refresh_timer = get_node_or_null("RefreshTimer") as Timer
	_pickup_spawn_timer = get_node_or_null("PickupSpawnTimer") as Timer
	if (
		_target == null
		or _decoration_container == null
		or _pickup_container == null
		or _refresh_timer == null
		or _pickup_spawn_timer == null
		or decoration_scene == null
		or pickup_scene == null
	):
		push_error("WorldPopulation requires its player, containers, scenes, and timers.")
		return
	_rng.randomize()
	_refresh_timer.wait_time = refresh_interval
	_refresh_timer.timeout.connect(refresh_population)
	_refresh_timer.start()
	_pickup_spawn_timer.wait_time = pickup_spawn_interval
	_pickup_spawn_timer.timeout.connect(replenish_pickups)
	_pickup_spawn_timer.start()
	refresh_population()
	replenish_pickups()


func set_random_seed(value: int) -> void:
	_rng.seed = value
	_pickup_bag.clear()


func refresh_population() -> void:
	if not _has_living_target():
		return
	_refresh_decorations()
	_recycle_distant_pickups()


func replenish_pickups() -> void:
	if not _has_living_target():
		return
	while get_active_pickup_count() < maximum_pickups:
		if spawn_pickup() == null:
			break


func spawn_pickup(requested_type: StringName = &"") -> Node2D:
	if (
		not _has_living_target()
		or not is_instance_valid(_pickup_container)
		or get_active_pickup_count() >= maximum_pickups
	):
		return null
	var pickup := pickup_scene.instantiate() as Node2D
	if pickup == null:
		push_error("WorldPopulation's pickup_scene must instantiate a Node2D.")
		return null
	var resolved_type := requested_type if PICKUP_TYPES.has(requested_type) else _draw_pickup_type()
	_pickup_container.add_child(pickup)
	pickup.global_position = _random_position(pickup_minimum_distance, pickup_maximum_distance)
	pickup.call("configure", _target, resolved_type, pickup_collection_radius)
	pickup.connect(&"collected", Callable(self, "_on_pickup_collected"))
	return pickup


func get_active_decoration_count() -> int:
	return _active_child_count(_decoration_container)


func get_active_pickup_count() -> int:
	return _active_child_count(_pickup_container)


func _refresh_decorations() -> void:
	for child: Node in _decoration_container.get_children():
		if not child is Node2D or child.is_queued_for_deletion():
			continue
		var decoration := child as Node2D
		if decoration.global_position.distance_to(_target.global_position) > decoration_retention_distance:
			_configure_decoration(decoration)
	while get_active_decoration_count() < maximum_decorations:
		var decoration := decoration_scene.instantiate() as Node2D
		if decoration == null:
			push_error("WorldPopulation's decoration_scene must instantiate a Node2D.")
			return
		_decoration_container.add_child(decoration)
		_configure_decoration(decoration)


func _configure_decoration(decoration: Node2D) -> void:
	decoration.global_position = _random_position(decoration_minimum_distance, decoration_maximum_distance)
	decoration.call("configure", _rng.randi_range(0, 2), _rng.randf_range(0.0, TAU), _rng.randf_range(0.65, 1.25))


func _recycle_distant_pickups() -> void:
	for child: Node in _pickup_container.get_children():
		if not child is Node2D or child.is_queued_for_deletion():
			continue
		var pickup := child as Node2D
		if pickup.global_position.distance_to(_target.global_position) <= pickup_retention_distance:
			continue
		pickup.global_position = _random_position(pickup_minimum_distance, pickup_maximum_distance)
		pickup.call("configure", _target, _draw_pickup_type(), pickup_collection_radius)


func _random_position(minimum_distance: float, maximum_distance: float) -> Vector2:
	var safe_minimum := maxf(minimum_distance, 1.0)
	var safe_maximum := maxf(maximum_distance, safe_minimum)
	var angle := _rng.randf_range(0.0, TAU)
	var distance := sqrt(_rng.randf_range(safe_minimum * safe_minimum, safe_maximum * safe_maximum))
	return _target.global_position + Vector2.RIGHT.rotated(angle) * distance


func _draw_pickup_type() -> StringName:
	if _pickup_bag.is_empty():
		_pickup_bag.assign(PICKUP_TYPES)
	var bag_index := _rng.randi_range(0, _pickup_bag.size() - 1)
	var pickup_type: StringName = _pickup_bag[bag_index]
	_pickup_bag.remove_at(bag_index)
	return pickup_type


func _on_pickup_collected(pickup_type: StringName) -> void:
	pickup_collected.emit(pickup_type)


func _active_child_count(container: Node) -> int:
	if not is_instance_valid(container):
		return 0
	var count := 0
	for child: Node in container.get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			count += 1
	return count


func _has_living_target() -> bool:
	if not is_instance_valid(_target):
		return false
	if _target.has_method("is_alive") and not _target.call("is_alive"):
		return false
	return true
