extends SceneTree

const EXPECTED_BINDINGS: Dictionary = {
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
}


func _initialize() -> void:
	var failures: Array[String] = []
	_verify_project_settings(failures)
	_verify_input_actions(failures)
	_verify_main_scene(failures)

	if failures.is_empty():
		print("F00 verification passed: project, input actions, and HUD shell are configured.")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	quit(1)


func _verify_project_settings(failures: Array[String]) -> void:
	if ProjectSettings.get_setting("application/run/main_scene") != "res://scenes/main.tscn":
		failures.append("The configured main scene is not res://scenes/main.tscn.")
	if ProjectSettings.get_setting("display/window/size/viewport_width") != 1280:
		failures.append("The viewport width is not 1280.")
	if ProjectSettings.get_setting("display/window/size/viewport_height") != 720:
		failures.append("The viewport height is not 720.")


func _verify_input_actions(failures: Array[String]) -> void:
	for action: StringName in EXPECTED_BINDINGS:
		if not InputMap.has_action(action):
			failures.append("Missing input action: %s." % action)
			continue

		for expected_key: Key in EXPECTED_BINDINGS[action]:
			var binding_found := false
			for event: InputEvent in InputMap.action_get_events(action):
				if event is InputEventKey and event.physical_keycode == expected_key:
					binding_found = true
					break
			if not binding_found:
				failures.append("Action %s is missing physical key %s." % [action, expected_key])


func _verify_main_scene(failures: Array[String]) -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		failures.append("The main scene could not be loaded.")
		return

	var main := packed_scene.instantiate()
	var background := main.get_node_or_null("ArenaBackground") as ColorRect
	var hud_layout := main.get_node_or_null("HUD/Layout") as Control
	var top_bar := main.get_node_or_null("HUD/Layout/TopBar") as Control
	var health := main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Health/Value") as Label
	var level := main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Level/Value") as Label
	var xp := main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/XP/Heading/Value") as Label

	if background == null or background.color.get_luminance() >= 0.1:
		failures.append("The main scene does not contain the expected dark background.")
	if hud_layout == null or hud_layout.anchor_right != 1.0 or hud_layout.anchor_bottom != 1.0:
		failures.append("The HUD layout is not anchored to the full viewport.")
	if top_bar == null or top_bar.anchor_right != 1.0:
		failures.append("The top HUD bar is not horizontally anchored to the viewport.")
	if health == null or health.text != "100 / 100":
		failures.append("The health placeholder is missing or incorrect.")
	if level == null or level.text != "1":
		failures.append("The level placeholder is missing or incorrect.")
	if xp == null or xp.text != "0 / 5":
		failures.append("The XP placeholder is missing or incorrect.")

	main.free()
