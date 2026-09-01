extends SceneTree

var _observed_level_ups: Array[int] = []
var _observed_collections: Array[int] = []


func _initialize() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	var failures: Array[String] = []
	await _verify_progression(failures)
	await _verify_xp_coin(failures)
	await _verify_main_integration_cap_pause_and_restart(failures)

	if failures.is_empty():
		print("F04 verification passed: bounded XP drops, collection, five-level progression, HUD, pause, and restart are configured.")
		quit(0)
		return

	paused = false
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _verify_progression(failures: Array[String]) -> void:
	var progression_script := load("res://scripts/run_progression.gd") as Script
	if progression_script == null:
		failures.append("The run progression script could not be loaded.")
		return
	var progression := progression_script.new() as Node
	root.add_child(progression)
	progression.level_up.connect(_record_level_up)
	_observed_level_ups.clear()

	if progression.get_thresholds() != [10, 20, 32, 48, 70]:
		failures.append("Run progression does not expose exactly the five required XP thresholds.")
	if progression.current_level != 1 or progression.current_xp != 0 or progression.get_required_xp() != 10:
		failures.append("Run progression does not start at level 1 with 0 / 10 XP.")
	if progression.add_xp(65) != 3:
		failures.append("One XP award did not cross every eligible threshold.")
	if progression.current_level != 4 or progression.current_xp != 3 or progression.get_required_xp() != 48:
		failures.append("Threshold carry-over was not preserved after a multi-level XP award.")
	if _observed_level_ups != [2, 3, 4]:
		failures.append("Multi-level XP did not emit one ordered event per crossed threshold.")

	progression.add_xp(115)
	if not progression.completed or progression.current_level != 6 or progression.current_xp != 0:
		failures.append("Progression did not stop in a clear completed level-6 state after threshold five.")
	if progression.get_required_xp() != 0 or _observed_level_ups != [2, 3, 4, 5, 6]:
		failures.append("Completion did not consume exactly five thresholds and five level-up events.")
	if progression.add_xp(999) != 0 or progression.current_level != 6 or _observed_level_ups.size() != 5:
		failures.append("XP after completion created additional progress or a sixth level-up event.")

	progression.reset_progression()
	if progression.current_level != 1 or progression.current_xp != 0 or progression.completed:
		failures.append("Progression reset did not restore a clean finite run.")
	progression.free()


func _verify_xp_coin(failures: Array[String]) -> void:
	var coin_scene := load("res://scenes/xp_coin.tscn") as PackedScene
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	if coin_scene == null or player_scene == null:
		failures.append("The XP coin or player scene could not be loaded for focused verification.")
		return
	var player := player_scene.instantiate() as CharacterBody2D
	var coin := coin_scene.instantiate() as Node2D
	root.add_child(player)
	root.add_child(coin)
	player.global_position = Vector2.ZERO
	coin.global_position = Vector2(100.0, 0.0)
	coin.configure(player, 3)
	_observed_collections.clear()
	coin.collected.connect(_record_collection)
	await process_frame

	if coin.xp_value != 3 or coin.attraction_radius <= 0.0 or coin.collection_radius <= 0.0 or coin.movement_speed <= 0.0:
		failures.append("The XP coin lacks positive centralized value, attraction, collection, or speed tuning.")
	if not is_equal_approx(coin.attraction_radius, 150.0):
		failures.append("XP coins do not preserve the short-range 150-unit attraction tuning.")
	if coin.get_node_or_null("Body") == null:
		failures.append("The XP coin does not have a visible repository-native geometric body.")
	var distance_before: float = coin.global_position.distance_to(player.global_position)
	coin._physics_process(0.1)
	var distance_after: float = coin.global_position.distance_to(player.global_position)
	if distance_after >= distance_before:
		failures.append("A coin inside its attraction radius did not move toward the living player.")
	coin.global_position = Vector2(coin.attraction_radius + 20.0, 0.0)
	var outside_position: Vector2 = coin.global_position
	coin._physics_process(0.1)
	if not coin.global_position.is_equal_approx(outside_position):
		failures.append("A coin moved while outside its centralized attraction radius.")

	coin.global_position = player.global_position
	if not coin.collect() or coin.collect():
		failures.append("XP coin collection is not idempotent.")
	if _observed_collections != [3] or not coin.is_queued_for_deletion():
		failures.append("XP coin collection did not award its full value exactly once and remove the coin.")
	player.free()
	await process_frame


func _verify_main_integration_cap_pause_and_restart(failures: Array[String]) -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		failures.append("The main scene could not be loaded for F04 integration verification.")
		return
	var main := packed_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	var player := main.get_node_or_null("World/Player") as CharacterBody2D
	var enemies := main.get_node_or_null("World/Enemies")
	var projectiles := main.get_node_or_null("World/Projectiles")
	var coins := main.get_node_or_null("World/XPCoins")
	var spawner := main.get_node_or_null("World/EnemySpawner")
	var progression := main.get_node_or_null("RunProgression")
	var spawn_timer := main.get_node_or_null("World/EnemySpawner/SpawnTimer") as Timer
	var fire_timer := main.get_node_or_null("World/Player/AutoWeapon/FireTimer") as Timer
	var level_label := main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Level/Value") as Label
	var xp_label := main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/XP/Heading/Value") as Label
	var xp_bar := main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/XP/Bar") as ProgressBar
	if (
		player == null
		or enemies == null
		or projectiles == null
		or coins == null
		or spawner == null
		or progression == null
		or level_label == null
		or xp_label == null
		or xp_bar == null
	):
		failures.append("The main scene is missing an F04 progression, coin, or HUD integration node.")
		main.free()
		return
	spawn_timer.stop()
	fire_timer.stop()
	if level_label.text != "1" or xp_label.text != "0 / 10" or xp_bar.max_value != 10.0 or xp_bar.value != 0.0:
		failures.append("The live progression HUD does not initialize to level 1 and 0 / 10 XP.")

	var enemy := spawner.spawn_enemy() as Node2D
	if enemy == null:
		failures.append("The spawner could not create an enemy for XP drop integration.")
	else:
		enemy.global_position = Vector2(360.0, 180.0)
		var death_position: Vector2 = enemy.global_position
		enemy.take_damage(enemy.maximum_health)
		if main.get_active_xp_coin_count() != 1:
			failures.append("A normal enemy combat death did not create exactly one XP coin.")
		elif not (coins.get_child(0) as Node2D).global_position.is_equal_approx(death_position):
			failures.append("The XP coin was not dropped at the defeated enemy's position.")
	await process_frame
	var count_before_cleanup: int = main.get_active_xp_coin_count()
	var cleanup_enemy := spawner.spawn_enemy() as Node2D
	if cleanup_enemy != null:
		cleanup_enemy.free()
	await process_frame
	if main.get_active_xp_coin_count() != count_before_cleanup:
		failures.append("Freeing an enemy for cleanup created an XP drop without a combat death.")

	main.maximum_active_xp_coins = 3
	main.create_xp_drop(Vector2(500.0, 0.0), 2)
	main.create_xp_drop(Vector2(550.0, 0.0), 2)
	main.create_xp_drop(Vector2(600.0, 0.0), 3)
	if main.get_active_xp_coin_count() != 3:
		failures.append("The centralized XP coin population cap was not enforced.")
	var uncollected_xp := 0
	for child: Node in coins.get_children():
		if not child.is_queued_for_deletion():
			uncollected_xp += child.xp_value
	if uncollected_xp != 8:
		failures.append("Creating a drop at the coin cap did not preserve all uncollected XP by merging.")

	var collected_coin := coins.get_child(0) as Node2D
	var collected_value: int = collected_coin.xp_value
	collected_coin.global_position = player.global_position
	collected_coin._physics_process(0.0)
	if progression.current_xp != collected_value:
		failures.append("Coin collection did not route the coin's full value into run progression.")
	if xp_label.text != "%d / 10" % collected_value or xp_bar.value != float(collected_value):
		failures.append("Coin collection did not update the XP HUD immediately.")
	await process_frame

	progression.reset_progression()
	progression.add_xp(180)
	if level_label.text != "6" or xp_label.text != "COMPLETE" or xp_bar.value != xp_bar.max_value:
		failures.append("The HUD does not show a clear completed state after the fifth threshold.")
	progression.add_xp(10)
	if level_label.text != "6" or xp_label.text != "COMPLETE":
		failures.append("The completed HUD changed after additional XP.")

	var paused_coin := main.create_xp_drop(player.global_position + Vector2(100.0, 0.0), 1) as Node2D
	var paused_coin_position: Vector2 = paused_coin.global_position
	player.clear_invulnerability()
	player.take_damage(player.maximum_health)
	if not main.is_defeated() or not paused or paused_coin.can_process():
		failures.append("Defeat did not pause the run and XP coin processing.")
	await process_frame
	if not paused_coin.global_position.is_equal_approx(paused_coin_position):
		failures.append("An XP coin continued attraction movement during paused defeat.")

	main.restart_run()
	await process_frame
	await process_frame
	var restarted_main := current_scene
	if restarted_main == null or restarted_main == main:
		failures.append("F04 restart did not reload a new main scene instance.")
		return
	var restarted_progression := restarted_main.get_node_or_null("RunProgression")
	var restarted_coins := restarted_main.get_node_or_null("World/XPCoins")
	var restarted_enemies := restarted_main.get_node_or_null("World/Enemies")
	var restarted_projectiles := restarted_main.get_node_or_null("World/Projectiles")
	var restarted_level := restarted_main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Level/Value") as Label
	var restarted_xp := restarted_main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/XP/Heading/Value") as Label
	if paused or restarted_progression.current_level != 1 or restarted_progression.current_xp != 0 or restarted_progression.completed:
		failures.append("Restart retained pause or progression state from the prior run.")
	if restarted_level.text != "1" or restarted_xp.text != "0 / 10":
		failures.append("Restart did not restore the initial level and XP HUD.")
	if restarted_coins.get_child_count() != 0 or restarted_enemies.get_child_count() != 0 or restarted_projectiles.get_child_count() != 0:
		failures.append("Restart retained enemies, projectiles, or XP coins from the prior run.")


func _record_level_up(level: int) -> void:
	_observed_level_ups.append(level)


func _record_collection(xp_value: int) -> void:
	_observed_collections.append(xp_value)
