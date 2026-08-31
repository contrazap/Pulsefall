extends SceneTree

const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const DISTANT_CAMERA_POSITION := Vector2(4200.0, -3100.0)


func _initialize() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	var failures: Array[String] = []
	_verify_enemy_scene(failures)
	_verify_spawn_geometry(failures)
	await _verify_main_integration_and_cap(failures)

	if failures.is_empty():
		print("F02 verification passed: reusable enemy chase, off-screen spawning, and population cap are configured.")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	quit(1)


func _verify_enemy_scene(failures: Array[String]) -> void:
	var packed_scene := load("res://scenes/enemy.tscn") as PackedScene
	if packed_scene == null:
		failures.append("The reusable enemy scene could not be loaded.")
		return

	var enemy := packed_scene.instantiate() as CharacterBody2D
	if enemy == null:
		failures.append("The enemy scene root is not a CharacterBody2D.")
		return

	var movement_speed := enemy.get("movement_speed") as float
	var body := enemy.get_node_or_null("Body") as Polygon2D
	var collision_shape := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if movement_speed <= 0.0:
		failures.append("Enemy movement speed is not a positive centralized value.")
	if not enemy.is_in_group(&"normal_enemies"):
		failures.append("The reusable enemy is not in the normal-enemy group.")
	if body == null or body.polygon.size() < 3:
		failures.append("The enemy lacks a readable geometric body.")
	if collision_shape == null or collision_shape.shape == null:
		failures.append("The enemy lacks a collision shape for later combat integration.")

	enemy.global_position = Vector2(20.0, 30.0)
	var target_position := Vector2(220.0, 30.0)
	var chase_velocity := enemy.call("calculate_chase_velocity", target_position) as Vector2
	if not chase_velocity.normalized().is_equal_approx(Vector2.RIGHT):
		failures.append("The enemy does not calculate a direct chase direction.")
	if not is_equal_approx(chase_velocity.length(), movement_speed):
		failures.append("Enemy chase velocity does not use its configured speed.")

	enemy.call("set_target", null)
	enemy.call("refresh_chase_velocity")
	if not enemy.velocity.is_zero_approx():
		failures.append("The enemy does not stop safely when its target is absent.")
	enemy.free()


func _verify_spawn_geometry(failures: Array[String]) -> void:
	var spawner_script := load("res://scripts/enemy_spawner.gd") as Script
	if spawner_script == null:
		failures.append("The enemy spawner script could not be loaded.")
		return

	var spawner := spawner_script.new() as Node
	var spawn_interval := spawner.get("spawn_interval") as float
	var offscreen_margin := spawner.get("offscreen_margin") as float
	var maximum_active_enemies := spawner.get("maximum_active_enemies") as int
	if spawn_interval <= 0.0 or offscreen_margin <= 0.0 or maximum_active_enemies <= 0:
		failures.append("Spawner interval, margin, and cap are not valid centralized values.")

	for camera_position: Vector2 in [Vector2.ZERO, DISTANT_CAMERA_POSITION]:
		for side: int in range(4):
			var spawn_position := spawner.call(
				"calculate_spawn_position",
				camera_position,
				VIEWPORT_SIZE,
				Vector2.ONE,
				side,
				0.5
			) as Vector2
			var is_beyond_margin := spawner.call(
				"is_position_beyond_spawn_margin",
				spawn_position,
				camera_position,
				VIEWPORT_SIZE,
				Vector2.ONE
			) as bool
			if not is_beyond_margin:
				failures.append("Spawn side %d is not beyond the configured camera margin." % side)
			if spawn_position.is_equal_approx(camera_position):
				failures.append("A generated spawn position overlaps the player/camera center.")
	spawner.free()


func _verify_main_integration_and_cap(failures: Array[String]) -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		failures.append("The main scene could not be loaded.")
		return

	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame
	var player := main.get_node_or_null("World/Player") as CharacterBody2D
	var camera := main.get_node_or_null("World/Player/Camera2D") as Camera2D
	var enemy_container := main.get_node_or_null("World/Enemies")
	var spawner := main.get_node_or_null("World/EnemySpawner")
	var spawn_timer := main.get_node_or_null("World/EnemySpawner/SpawnTimer") as Timer
	if player == null or camera == null:
		failures.append("F01 player or following camera is missing from the main scene.")
	if enemy_container == null or spawner == null:
		failures.append("The dedicated enemy container or spawner is missing from the main world.")
		main.free()
		return
	if spawn_timer == null or spawn_timer.is_stopped():
		failures.append("The enemy spawner does not run from its configured timer.")

	spawner.set("maximum_active_enemies", 3)
	for attempt: int in range(7):
		spawner.call("spawn_enemy")
	var active_count := spawner.call("get_active_enemy_count") as int
	if active_count != 3:
		failures.append("The enemy population cap was not enforced; expected 3 and found %d." % active_count)
	if enemy_container.get_child_count() != 3:
		failures.append("Spawn attempts at the cap accumulated extra enemy nodes.")

	for child: Node in enemy_container.get_children():
		if child.get("target") != player:
			failures.append("A spawned enemy was not assigned the player target.")
			break
		var spawn_position := (child as Node2D).global_position
		var valid_position := spawner.call(
			"is_position_beyond_spawn_margin",
			spawn_position,
			camera.get_screen_center_position(),
			camera.get_viewport_rect().size,
			camera.zoom
		) as bool
		if not valid_position:
			failures.append("A runtime enemy was not spawned beyond the current camera view.")
			break

	if main.get_node_or_null("World/ArenaGrid") == null or main.get_node_or_null("HUD/Layout") == null:
		failures.append("F00/F01 arena or HUD integration was not retained.")
	main.free()
