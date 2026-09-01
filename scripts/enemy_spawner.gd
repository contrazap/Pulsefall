extends Node

signal enemy_spawned(enemy: Node2D)

const NORMAL_ENEMY_GROUP: StringName = &"normal_enemies"

enum SpawnSide {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT,
}

@export var enemy_scene: PackedScene
@export_range(0.1, 60.0, 0.05) var spawn_interval: float = 0.85
@export_range(1.0, 1024.0, 1.0) var offscreen_margin: float = 96.0
@export_range(1, 500, 1) var maximum_active_enemies: int = 24
@export var target_path: NodePath
@export var camera_path: NodePath
@export var enemy_container_path: NodePath

var _target: Node2D
var _camera: Camera2D
var _enemy_container: Node
var _spawn_timer: Timer
var _spawning_enabled: bool = true


func _ready() -> void:
	_resolve_references()
	_spawn_timer = get_node_or_null("SpawnTimer") as Timer
	if _spawn_timer == null:
		push_error("EnemySpawner requires a SpawnTimer child.")
		return
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	set_spawning_enabled(true)


func spawn_enemy() -> Node2D:
	if not can_spawn_enemy():
		return null

	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		push_error("EnemySpawner's enemy_scene must instantiate a Node2D.")
		return null

	var spawn_position := calculate_spawn_position(
		_camera.get_screen_center_position(),
		_camera.get_viewport_rect().size,
		_camera.zoom
	)
	if _enemy_container is Node2D:
		enemy.position = (_enemy_container as Node2D).to_local(spawn_position)
	_enemy_container.add_child(enemy)
	if not _enemy_container is Node2D:
		enemy.global_position = spawn_position
	if enemy.has_method("set_target"):
		enemy.call("set_target", _target)
	enemy_spawned.emit(enemy)
	return enemy


func can_spawn_enemy() -> bool:
	return (
		_spawning_enabled
		and enemy_scene != null
		and is_instance_valid(_target)
		and is_instance_valid(_camera)
		and is_instance_valid(_enemy_container)
		and get_active_enemy_count() < maximum_active_enemies
	)


func set_spawning_enabled(enabled: bool) -> void:
	_spawning_enabled = enabled
	if _spawn_timer == null:
		return
	if _spawning_enabled:
		_spawn_timer.start(spawn_interval)
	else:
		_spawn_timer.stop()


func is_spawning_enabled() -> bool:
	return _spawning_enabled


func calculate_current_spawn_position(spawn_side: int = -1, edge_fraction: float = -1.0) -> Vector2:
	if not is_instance_valid(_camera):
		return Vector2.ZERO
	return calculate_spawn_position(
		_camera.get_screen_center_position(),
		_camera.get_viewport_rect().size,
		_camera.zoom,
		spawn_side,
		edge_fraction
	)


func get_active_enemy_count() -> int:
	if not is_instance_valid(_enemy_container):
		return 0

	var active_count := 0
	for child: Node in _enemy_container.get_children():
		if child.is_in_group(NORMAL_ENEMY_GROUP):
			active_count += 1
	return active_count


func calculate_visible_world_rect(
	camera_position: Vector2,
	viewport_size: Vector2,
	camera_zoom: Vector2 = Vector2.ONE
) -> Rect2:
	var safe_zoom := Vector2(
		maxf(absf(camera_zoom.x), 0.001),
		maxf(absf(camera_zoom.y), 0.001)
	)
	var world_size := viewport_size / safe_zoom
	return Rect2(camera_position - world_size * 0.5, world_size)


func calculate_spawn_position(
	camera_position: Vector2,
	viewport_size: Vector2,
	camera_zoom: Vector2 = Vector2.ONE,
	spawn_side: int = -1,
	edge_fraction: float = -1.0
) -> Vector2:
	var visible_rect := calculate_visible_world_rect(camera_position, viewport_size, camera_zoom)
	var selected_side := spawn_side
	if selected_side < SpawnSide.TOP or selected_side > SpawnSide.LEFT:
		selected_side = randi_range(SpawnSide.TOP, SpawnSide.LEFT)
	var fraction := clampf(edge_fraction, 0.0, 1.0) if edge_fraction >= 0.0 else randf()

	match selected_side:
		SpawnSide.TOP:
			return Vector2(
				lerpf(visible_rect.position.x, visible_rect.end.x, fraction),
				visible_rect.position.y - offscreen_margin
			)
		SpawnSide.RIGHT:
			return Vector2(
				visible_rect.end.x + offscreen_margin,
				lerpf(visible_rect.position.y, visible_rect.end.y, fraction)
			)
		SpawnSide.BOTTOM:
			return Vector2(
				lerpf(visible_rect.position.x, visible_rect.end.x, fraction),
				visible_rect.end.y + offscreen_margin
			)
		_:
			return Vector2(
				visible_rect.position.x - offscreen_margin,
				lerpf(visible_rect.position.y, visible_rect.end.y, fraction)
			)


func is_position_beyond_spawn_margin(
	position: Vector2,
	camera_position: Vector2,
	viewport_size: Vector2,
	camera_zoom: Vector2 = Vector2.ONE
) -> bool:
	var visible_rect := calculate_visible_world_rect(camera_position, viewport_size, camera_zoom)
	return (
		position.x <= visible_rect.position.x - offscreen_margin
		or position.x >= visible_rect.end.x + offscreen_margin
		or position.y <= visible_rect.position.y - offscreen_margin
		or position.y >= visible_rect.end.y + offscreen_margin
	)


func _resolve_references() -> void:
	_target = get_node_or_null(target_path) as Node2D
	_camera = get_node_or_null(camera_path) as Camera2D
	_enemy_container = get_node_or_null(enemy_container_path)


func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
