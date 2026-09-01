extends SceneTree

var _standalone_choices: Array[StringName] = []
var _standalone_levels: Array[int] = []
var _combat_choices: Array[StringName] = []
var _applied_choices: Array[StringName] = []
var _applied_counts: Array[int] = []
var _applied_levels: Array[int] = []


func _initialize() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	var failures: Array[String] = []
	await _verify_player_upgrade_formulas(failures)
	await _verify_choice_ui(failures)
	await _verify_main_queue_pause_selection_and_restart(failures)

	if failures.is_empty():
		print("F05 verification passed: paused upgrade choices, queued selections, Vitality, Haste, combat seam, and restart are configured.")
		quit(0)
		return

	paused = false
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _verify_player_upgrade_formulas(failures: Array[String]) -> void:
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	if player_scene == null:
		failures.append("The player scene could not be loaded for F05 formula verification.")
		return
	var player := player_scene.instantiate() as CharacterBody2D
	root.add_child(player)
	await process_frame

	var base_health: int = player.maximum_health
	var base_speed: float = player.movement_speed
	player.take_damage(30)
	player.clear_invulnerability()
	player.apply_vitality()
	if player.maximum_health != base_health + 20 or player.current_health != base_health - 10:
		failures.append("Vitality did not add exactly 20 maximum and current health after damage.")
	player.apply_vitality()
	if player.maximum_health != base_health + 40 or player.current_health != base_health + 10:
		failures.append("Repeated Vitality did not apply the same capped +20 health formula.")

	player.apply_haste()
	if not is_equal_approx(player.movement_speed, base_speed * 1.12):
		failures.append("Haste did not multiply current movement speed by exactly 1.12.")
	player.apply_haste()
	var expected_speed: float = base_speed * 1.12 * 1.12
	if not is_equal_approx(player.movement_speed, expected_speed):
		failures.append("Repeated Haste did not compound from the upgraded movement speed.")
	if not is_equal_approx(player.calculate_velocity(Vector2.RIGHT).length(), expected_speed):
		failures.append("The upgraded movement speed was not used immediately by calculate_velocity().")
	player.free()
	await process_frame


func _verify_choice_ui(failures: Array[String]) -> void:
	var ui_scene := load("res://scenes/upgrade_choice_ui.tscn") as PackedScene
	if ui_scene == null:
		failures.append("The upgrade choice UI scene could not be loaded.")
		return
	var ui := ui_scene.instantiate() as Control
	root.add_child(ui)
	ui.connect(&"choice_selected", Callable(self, "_record_standalone_choice"))
	await process_frame

	var choices := ui.call("get_choice_ids") as Array
	var choice_container := ui.get_node_or_null("Center/Panel/Margin/Content/Choices") as HBoxContainer
	if choices != [&"vitality", &"haste", &"combat"]:
		failures.append("The choice UI does not expose the three stable F05 identifiers in order.")
	if choice_container == null or choice_container.get_child_count() != 3:
		failures.append("The choice UI does not contain exactly three selectable choice buttons.")
	if ui.process_mode != Node.PROCESS_MODE_ALWAYS:
		failures.append("The choice UI is not configured to remain operable while the scene tree is paused.")

	var combat_metadata_before := ui.call("get_choice_metadata", &"combat") as Dictionary
	ui.call("show_choices", 2)
	if not ui.visible or ui.call("get_offered_level") != 2:
		failures.append("The choice UI did not open for its offered level.")
	for child: Node in choice_container.get_children():
		if not child is Button or (child as Button).disabled:
			failures.append("An upgrade choice is not an enabled mouse-selectable button while open.")
	var selected_once: bool = ui.call("select_choice", &"combat")
	var selected_twice: bool = ui.call("select_choice", &"combat")
	if not selected_once or selected_twice or _standalone_choices != [&"combat"] or _standalone_levels != [2]:
		failures.append("The choice UI did not guard one selection emission per open screen.")
	ui.call("hide_choices")
	ui.call("show_choices", 3)
	var combat_metadata_after := ui.call("get_choice_metadata", &"combat") as Dictionary
	if combat_metadata_before != combat_metadata_after:
		failures.append("The F05 combat offer metadata changed between openings.")
	ui.call("hide_choices")
	ui.free()
	await process_frame


func _verify_main_queue_pause_selection_and_restart(failures: Array[String]) -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	var projectile_scene := load("res://scenes/projectile.tscn") as PackedScene
	if packed_scene == null or projectile_scene == null:
		failures.append("The main or projectile scene could not be loaded for F05 integration verification.")
		return
	var main := packed_scene.instantiate()
	root.add_child(main)
	current_scene = main
	main.connect(&"combat_choice_selected", Callable(self, "_record_combat_choice"))
	main.connect(&"selection_applied", Callable(self, "_record_applied_choice"))
	await process_frame

	var player := main.get_node_or_null("World/Player") as CharacterBody2D
	var progression := main.get_node_or_null("RunProgression")
	var spawner := main.get_node_or_null("World/EnemySpawner")
	var spawn_timer := main.get_node_or_null("World/EnemySpawner/SpawnTimer") as Timer
	var fire_timer := main.get_node_or_null("World/Player/AutoWeapon/FireTimer") as Timer
	var enemies := main.get_node_or_null("World/Enemies")
	var projectiles := main.get_node_or_null("World/Projectiles")
	var coins := main.get_node_or_null("World/XPCoins")
	var choice_ui := main.get_node_or_null("HUD/UpgradeChoiceUI") as Control
	var health_label := main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Health/Value") as Label
	var defeat_overlay := main.get_node_or_null("HUD/DefeatOverlay") as Control
	if (
		player == null
		or progression == null
		or spawner == null
		or spawn_timer == null
		or fire_timer == null
		or enemies == null
		or projectiles == null
		or coins == null
		or choice_ui == null
		or health_label == null
		or defeat_overlay == null
	):
		failures.append("The main scene is missing an F05 integration node.")
		main.free()
		return
	spawn_timer.stop()
	fire_timer.stop()

	var paused_enemy := spawner.spawn_enemy() as Node2D
	var paused_projectile := projectile_scene.instantiate() as Area2D
	projectiles.add_child(paused_projectile)
	var paused_coin := main.create_xp_drop(player.global_position + Vector2(100.0, 0.0), 1) as Node2D
	var coin_position_before: Vector2 = paused_coin.global_position
	player.take_damage(30)
	player.clear_invulnerability()
	var base_maximum_health: int = player.maximum_health
	var base_speed: float = player.movement_speed

	progression.add_xp(5)
	if (
		not paused
		or not main.is_upgrade_choice_open()
		or main.get_pending_upgrade_count() != 1
		or not choice_ui.visible
		or choice_ui.call("get_offered_level") != 2
	):
		failures.append("The first level-up did not open exactly one paused level-2 choice.")
	if (
		player.can_process()
		or spawner.can_process()
		or paused_enemy.can_process()
		or paused_projectile.can_process()
		or paused_coin.can_process()
		or not choice_ui.can_process()
	):
		failures.append("Paused upgrade choice processing does not freeze gameplay while keeping the UI active.")
	await process_frame
	if not paused_coin.global_position.is_equal_approx(coin_position_before):
		failures.append("An XP coin moved while the upgrade choice paused the run.")

	if not choice_ui.call("select_choice", &"vitality"):
		failures.append("The Vitality button could not resolve the first pending choice.")
	if (
		paused
		or main.is_upgrade_choice_open()
		or main.get_pending_upgrade_count() != 0
		or main.get_applied_selection_count() != 1
		or player.maximum_health != base_maximum_health + 20
		or player.current_health != base_maximum_health - 10
		or health_label.text != "%d / %d" % [player.current_health, player.maximum_health]
	):
		failures.append("Vitality did not resolve once, resume play, and refresh health state immediately.")
	if choice_ui.call("select_choice", &"vitality"):
		failures.append("A closed choice screen accepted a duplicate Vitality selection.")

	progression.add_xp(9)
	if main.apply_upgrade_choice(&"vitality", 2):
		failures.append("A stale level-2 callback consumed the pending level-3 selection.")
	if main.get_pending_upgrade_count() != 1 or main.get_applied_selection_count() != 1:
		failures.append("Rejecting a stale callback changed the choice queue or selection count.")
	if not choice_ui.call("select_choice", &"haste"):
		failures.append("The Haste button could not resolve the second pending choice.")
	if not is_equal_approx(player.movement_speed, base_speed * 1.12):
		failures.append("Haste did not affect the live player's movement speed immediately.")
	if not is_equal_approx(player.calculate_velocity(Vector2.RIGHT).length(), player.movement_speed):
		failures.append("The live player did not use the upgraded Haste speed.")

	var projectile_damage_before: int = paused_projectile.damage
	var projectile_hits_before: int = paused_projectile.hit_allowance
	var fire_interval_before: float = fire_timer.wait_time
	progression.add_xp(62)
	if not paused or main.get_pending_upgrade_count() != 3 or choice_ui.call("get_offered_level") != 4:
		failures.append("A multi-threshold XP award did not queue three ordered paused choices.")
	if not choice_ui.call("select_choice", &"combat"):
		failures.append("The combat slot did not resolve through the shared choice flow.")
	if (
		_combat_choices != [&"combat"]
		or main.get_applied_selection_count() != 3
		or main.get_pending_upgrade_count() != 2
		or not paused
		or not choice_ui.visible
		or choice_ui.call("get_offered_level") != 5
	):
		failures.append("Combat selection did not emit its seam and advance to the next queued choice while paused.")
	if (
		paused_projectile.damage != projectile_damage_before
		or paused_projectile.hit_allowance != projectile_hits_before
		or not is_equal_approx(fire_timer.wait_time, fire_interval_before)
		or player.get_node_or_null("Nova") != null
	):
		failures.append("The F05 combat placeholder changed combat behavior before F06.")

	choice_ui.call("select_choice", &"vitality")
	if not paused or main.get_pending_upgrade_count() != 1 or choice_ui.call("get_offered_level") != 6:
		failures.append("The queued level-6 choice did not remain paused after resolving level 5.")
	choice_ui.call("select_choice", &"haste")
	if paused or main.get_pending_upgrade_count() != 0 or main.get_applied_selection_count() != 5 or choice_ui.visible:
		failures.append("The final queued choice did not resume play with exactly five applied selections.")
	if not is_equal_approx(player.movement_speed, base_speed * 1.12 * 1.12):
		failures.append("A repeated Haste selection did not compound on the live player.")
	progression.emit_signal(&"level_up", 7)
	if main.get_applied_selection_count() != 5 or main.get_pending_upgrade_count() != 0 or main.is_upgrade_choice_open():
		failures.append("The controller accepted more than the five finite upgrade selections.")
	if _applied_choices != [&"vitality", &"haste", &"combat", &"vitality", &"haste"]:
		failures.append("Applied choice signals did not preserve the resolved selection order.")
	if _applied_counts != [1, 2, 3, 4, 5] or _applied_levels != [2, 3, 4, 5, 6]:
		failures.append("Applied choice signals did not expose ordered levels and a reusable one-to-five count.")

	player.clear_invulnerability()
	player.take_damage(player.maximum_health)
	if not main.is_defeated() or not paused or not defeat_overlay.visible or choice_ui.visible:
		failures.append("Defeat did not remain readable and paused after completing upgrade selections.")
	main.restart_run()
	await process_frame
	await process_frame
	var restarted_main := current_scene
	if restarted_main == null or restarted_main == main:
		failures.append("F05 restart did not reload a new main scene instance.")
		return
	var restarted_player := restarted_main.get_node_or_null("World/Player") as CharacterBody2D
	var restarted_progression := restarted_main.get_node_or_null("RunProgression")
	var restarted_ui := restarted_main.get_node_or_null("HUD/UpgradeChoiceUI") as Control
	if (
		paused
		or restarted_player.maximum_health != base_maximum_health
		or not is_equal_approx(restarted_player.movement_speed, base_speed)
		or restarted_main.get_applied_selection_count() != 0
		or restarted_main.get_pending_upgrade_count() != 0
		or restarted_main.is_upgrade_choice_open()
		or restarted_ui.visible
		or restarted_progression.current_level != 1
		or restarted_progression.current_xp != 0
	):
		failures.append("Restart retained upgraded stats, choice state, pause, or progression.")
	if (
		restarted_main.get_node("World/Enemies").get_child_count() != 0
		or restarted_main.get_node("World/Projectiles").get_child_count() != 0
		or restarted_main.get_node("World/XPCoins").get_child_count() != 0
	):
		failures.append("Restart retained enemies, projectiles, or XP coins after F05.")


func _record_standalone_choice(choice_id: StringName, offered_level: int) -> void:
	_standalone_choices.append(choice_id)
	_standalone_levels.append(offered_level)


func _record_combat_choice(choice_id: StringName) -> void:
	_combat_choices.append(choice_id)


func _record_applied_choice(choice_id: StringName, count: int, level: int) -> void:
	_applied_choices.append(choice_id)
	_applied_counts.append(count)
	_applied_levels.append(level)
