extends SceneTree

const DEFAULT_VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const RESIZED_VIEWPORT_SIZE := Vector2(800.0, 450.0)


func _initialize() -> void:
	var failures: Array[String] = []
	_verify_movement_input(failures)
	_verify_player_scene(failures)
	_verify_main_scene(failures)
	_verify_bounded_grid(failures)

	if failures.is_empty():
		print("F01 verification passed: player movement, camera, HUD, and bounded repeating grid are configured.")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	quit(1)


func _verify_movement_input(failures: Array[String]) -> void:
	var directions: Dictionary[StringName, Vector2] = {
		&"move_up": Vector2.UP,
		&"move_down": Vector2.DOWN,
		&"move_left": Vector2.LEFT,
		&"move_right": Vector2.RIGHT,
	}
	for action: StringName in directions:
		Input.action_press(action)
		var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		Input.action_release(action)
		if not direction.is_equal_approx(directions[action]):
			failures.append("Input action %s does not produce the expected movement direction." % action)

	var released_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if not released_direction.is_zero_approx():
		failures.append("Releasing movement input does not return a zero direction.")

	Input.action_press(&"move_left")
	Input.action_press(&"move_right")
	var opposing_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	if not opposing_direction.is_zero_approx():
		failures.append("Opposing horizontal inputs do not cancel.")

	Input.action_press(&"move_up")
	Input.action_press(&"move_right")
	var diagonal_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	Input.action_release(&"move_up")
	Input.action_release(&"move_right")
	if not is_equal_approx(diagonal_direction.length(), 1.0):
		failures.append("Diagonal input is not normalized.")


func _verify_player_scene(failures: Array[String]) -> void:
	var packed_scene := load("res://scenes/player.tscn") as PackedScene
	if packed_scene == null:
		failures.append("The player scene could not be loaded.")
		return

	var player := packed_scene.instantiate() as CharacterBody2D
	if player == null:
		failures.append("The player scene root is not a CharacterBody2D.")
		return

	var movement_speed := player.get("movement_speed") as float
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	var body := player.get_node_or_null("Body") as Polygon2D
	if movement_speed <= 0.0:
		failures.append("Player movement speed is not a positive centralized value.")
	if camera == null or not camera.enabled:
		failures.append("The player does not have an enabled following Camera2D.")
	if body == null or body.polygon.size() < 3:
		failures.append("The player does not have a visible geometric body.")

	var axial_velocity := player.call("calculate_velocity", Vector2.RIGHT) as Vector2
	var diagonal_velocity := player.call("calculate_velocity", Vector2(1.0, 1.0)) as Vector2
	var stopped_velocity := player.call("calculate_velocity", Vector2.ZERO) as Vector2
	if not is_equal_approx(axial_velocity.length(), movement_speed):
		failures.append("Axial movement does not use the configured movement speed.")
	if not is_equal_approx(diagonal_velocity.length(), movement_speed):
		failures.append("Diagonal movement is not normalized to the configured movement speed.")
	if not stopped_velocity.is_zero_approx():
		failures.append("Zero input does not stop player movement.")

	player.free()


func _verify_main_scene(failures: Array[String]) -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		failures.append("The main scene could not be loaded.")
		return

	var main := packed_scene.instantiate()
	var player := main.get_node_or_null("World/Player") as CharacterBody2D
	var grid := main.get_node_or_null("World/ArenaGrid") as Node2D
	var hud := main.get_node_or_null("HUD") as CanvasLayer
	var hud_layout := main.get_node_or_null("HUD/Layout") as Control
	if player == null:
		failures.append("The reusable player is not instanced in the main world.")
	if grid == null or grid.get_script() == null:
		failures.append("The scripted repeating arena grid is missing from the main world.")
	if hud == null or hud_layout == null:
		failures.append("The F00 HUD is not retained in a viewport-fixed CanvasLayer.")
	main.free()


func _verify_bounded_grid(failures: Array[String]) -> void:
	var grid_script := load("res://scripts/arena_grid.gd") as Script
	if grid_script == null:
		failures.append("The arena grid script could not be loaded.")
		return

	var grid := grid_script.new() as Node2D
	var grid_spacing := grid.get("grid_spacing") as float
	var safety_margin := grid.get("safety_margin") as float
	if grid_spacing <= 0.0 or safety_margin < grid_spacing:
		failures.append("The arena grid lacks valid spacing or a sufficient safety margin.")

	var default_line_count := grid.call("get_draw_line_count", DEFAULT_VIEWPORT_SIZE) as int
	var resized_line_count := grid.call("get_draw_line_count", RESIZED_VIEWPORT_SIZE) as int
	if default_line_count <= 0 or resized_line_count <= 0:
		failures.append("The arena grid does not calculate bounded viewport coverage.")
	if grid.get_child_count() != 0:
		failures.append("The arena grid creates persistent tile nodes instead of bounded drawing.")

	var distant_position := Vector2(1000000.0, -1000000.0)
	var snapped_position := grid.call("calculate_grid_origin", distant_position) as Vector2
	if not is_equal_approx(fposmod(snapped_position.x, grid_spacing), 0.0):
		failures.append("The arena grid does not remain aligned after extended horizontal travel.")
	if not is_equal_approx(fposmod(snapped_position.y, grid_spacing), 0.0):
		failures.append("The arena grid does not remain aligned after extended vertical travel.")
	if grid.call("get_draw_line_count", DEFAULT_VIEWPORT_SIZE) as int != default_line_count:
		failures.append("Arena draw work changes with world travel instead of viewport size.")

	grid.free()
