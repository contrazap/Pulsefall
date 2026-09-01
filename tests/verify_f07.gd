extends SceneTree


func _initialize() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	var failures: Array[String] = []
	await _verify_world_population_and_pickups(failures)

	if failures.is_empty():
		print("F07 verification passed: bounded recycled decorations and Health, Magnet, and Bomb pickups are configured.")
		quit(0)
		return

	paused = false
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _verify_world_population_and_pickups(failures: Array[String]) -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var enemy_scene := load("res://scenes/enemy.tscn") as PackedScene
	if main_scene == null or enemy_scene == null:
		failures.append("The main or enemy scene could not be loaded for F07 verification.")
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	var player := main.get_node_or_null("World/Player") as CharacterBody2D
	var population := main.get_node_or_null("World/WorldPopulation")
	var decorations := main.get_node_or_null("World/Decorations") as Node2D
	var pickups := main.get_node_or_null("World/Pickups") as Node2D
	var coins := main.get_node_or_null("World/XPCoins") as Node2D
	var enemies := main.get_node_or_null("World/Enemies") as Node2D
	var spawner := main.get_node_or_null("World/EnemySpawner")
	var progression := main.get_node_or_null("RunProgression")
	var choice_ui := main.get_node_or_null("HUD/UpgradeChoiceUI") as Control
	var health_label := main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Health/Value") as Label
	var refresh_timer := main.get_node_or_null("World/WorldPopulation/RefreshTimer") as Timer
	var pickup_timer := main.get_node_or_null("World/WorldPopulation/PickupSpawnTimer") as Timer
	var spawn_timer := main.get_node_or_null("World/EnemySpawner/SpawnTimer") as Timer
	var fire_timer := main.get_node_or_null("World/Player/AutoWeapon/FireTimer") as Timer
	if (
		player == null
		or population == null
		or decorations == null
		or pickups == null
		or coins == null
		or enemies == null
		or spawner == null
		or progression == null
		or choice_ui == null
		or health_label == null
		or refresh_timer == null
		or pickup_timer == null
		or spawn_timer == null
		or fire_timer == null
	):
		failures.append("The main scene is missing an F07 integration node.")
		main.free()
		return
	spawn_timer.stop()
	fire_timer.stop()
	population.set_random_seed(707)

	if (
		population.maximum_decorations <= 0
		or population.maximum_pickups <= 0
		or population.pickup_minimum_distance <= 0.0
		or population.pickup_collection_radius <= 0.0
		or population.decoration_retention_distance <= population.decoration_maximum_distance
		or population.pickup_retention_distance <= population.pickup_maximum_distance
	):
		failures.append("World-population caps, distances, or collection tuning are not centralized and positive.")
	if population.get_active_decoration_count() != population.maximum_decorations:
		failures.append("A new run did not create the configured bounded decoration population.")
	if population.get_active_pickup_count() != population.maximum_pickups:
		failures.append("A new run did not create the configured bounded pickup population.")

	var decoration_ids := _active_instance_ids(decorations)
	var pickup_ids := _active_instance_ids(pickups)
	for travel_index: int in range(8):
		player.global_position += Vector2(2400.0, 175.0 * float(travel_index + 1))
		population.refresh_population()
		if population.get_active_decoration_count() > population.maximum_decorations:
			failures.append("Repeated travel exceeded the centralized decoration cap.")
			break
		if population.get_active_pickup_count() > population.maximum_pickups:
			failures.append("Repeated travel exceeded the centralized pickup cap.")
			break
		if not _positions_in_annulus(
			decorations,
			player.global_position,
			population.decoration_minimum_distance,
			population.decoration_maximum_distance
		):
			failures.append("A recycled decoration was outside its configured placement annulus.")
			break
		if not _positions_in_annulus(
			pickups,
			player.global_position,
			population.pickup_minimum_distance,
			population.pickup_maximum_distance
		):
			failures.append("A recycled pickup was outside its configured placement annulus.")
			break
	if _active_instance_ids(decorations) != decoration_ids:
		failures.append("Long-distance travel replaced decoration nodes instead of recycling the bounded population.")
	if _active_instance_ids(pickups) != pickup_ids:
		failures.append("Long-distance travel accumulated or replaced pickups instead of recycling distant entries.")
	for decoration: Node in decorations.get_children():
		if decoration is CollisionObject2D or decoration.find_children("*", "CollisionObject2D", true, false).size() > 0:
			failures.append("A decorative node introduced collision or gameplay physics.")
			break

	var pickup_types := _active_pickup_types(pickups)
	if (
		pickup_types.size() != 3
		or not pickup_types.has(&"health")
		or not pickup_types.has(&"magnet")
		or not pickup_types.has(&"bomb")
	):
		failures.append("The capped population did not expose all three stable pickup identifiers: %s." % [pickup_types])

	var health_pickup := _find_pickup(pickups, &"health")
	if health_pickup == null:
		failures.append("No Health pickup was available for effect verification.")
	else:
		player.apply_vitality()
		player.clear_invulnerability()
		player.take_damage(40)
		var health_before: int = player.current_health
		health_pickup.global_position = player.global_position + Vector2(population.pickup_collection_radius + 10.0, 0.0)
		health_pickup._physics_process(0.0)
		if health_pickup.is_collected() or player.current_health != health_before:
			failures.append("Health collected outside the centralized collection radius.")
		health_pickup.global_position = player.global_position
		var first_health_collection: bool = health_pickup.collect()
		var repeated_health_collection: bool = health_pickup.collect()
		if (
			not first_health_collection
			or repeated_health_collection
			or player.current_health != health_before + main.HEALTH_PICKUP_RESTORE
			or player.current_health > player.maximum_health
			or health_label.text != "%d / %d" % [player.current_health, player.maximum_health]
		):
			failures.append("Health did not restore exactly 25 once, clamp to Vitality-adjusted maximum, and update the HUD.")
		var clamped_restore: int = main.apply_world_pickup(&"health")
		if clamped_restore != 15 or player.current_health != player.maximum_health:
			failures.append("Health near maximum did not report and apply only the clamped remainder.")
	await process_frame

	main.maximum_active_xp_coins = 1
	main.create_xp_drop(player.global_position + Vector2(900.0, 0.0), 5)
	main.create_xp_drop(player.global_position + Vector2(920.0, 0.0), 8)
	if main.get_active_xp_coin_count() != 1 or coins.get_child(0).xp_value != 13:
		failures.append("The Magnet setup did not preserve a merged thirteen-XP coin.")
	var distant_coin := coins.get_child(0) as Node2D
	var distant_coin_position := distant_coin.global_position
	distant_coin._physics_process(0.5)
	if not distant_coin.global_position.is_equal_approx(distant_coin_position):
		failures.append("A distant XP coin moved before the Magnet pickup was collected.")
	var magnet_pickup := _find_pickup(pickups, &"magnet")
	if magnet_pickup == null:
		failures.append("No Magnet pickup was available for effect verification.")
	else:
		magnet_pickup.global_position = player.global_position
		magnet_pickup.collect()
		if (
			main.get_active_xp_coin_count() != 0
			or progression.current_level != 2
			or progression.current_xp != 3
			or not paused
			or not main.is_upgrade_choice_open()
		):
			failures.append("Magnet did not collect the full merged XP value through the ordered paused progression path.")
		if population.can_process():
			failures.append("World-population generation could process while Magnet opened an upgrade choice.")
		for pickup: Node in pickups.get_children():
			if not pickup.is_queued_for_deletion() and pickup.can_process():
				failures.append("A pickup could still collect while an upgrade choice paused gameplay.")
				break
	await process_frame
	if paused:
		choice_ui.select_choice(&"vitality")
	if paused:
		failures.append("The normal upgrade choice did not resume gameplay after Magnet-triggered progression.")

	var first_enemy := spawner.spawn_enemy() as CharacterBody2D
	var second_enemy := spawner.spawn_enemy() as CharacterBody2D
	var non_normal_enemy := enemy_scene.instantiate() as CharacterBody2D
	enemies.add_child(non_normal_enemy)
	non_normal_enemy.remove_from_group(&"normal_enemies")
	non_normal_enemy.maximum_health = 400
	non_normal_enemy.current_health = 400
	first_enemy.set_physics_process(false)
	second_enemy.set_physics_process(false)
	non_normal_enemy.set_physics_process(false)
	first_enemy.global_position = player.global_position + Vector2(500.0, 0.0)
	second_enemy.global_position = player.global_position + Vector2(-500.0, 0.0)
	non_normal_enemy.global_position = player.global_position + Vector2(0.0, 500.0)
	var bomb_pickup := _find_pickup(pickups, &"bomb")
	if bomb_pickup == null:
		failures.append("No Bomb pickup was available for effect verification.")
	else:
		bomb_pickup.global_position = player.global_position
		bomb_pickup.collect()
		if (
			not first_enemy.is_queued_for_deletion()
			or not second_enemy.is_queued_for_deletion()
			or non_normal_enemy.current_health != 400
			or non_normal_enemy.is_queued_for_deletion()
			or main.get_active_xp_coin_count() != 1
			or coins.get_child(0).xp_value != 2
		):
			failures.append("Bomb did not kill normal enemies through their XP-drop path while ignoring a damageable non-normal node.")
	await process_frame

	population.replenish_pickups()
	if population.get_active_pickup_count() != population.maximum_pickups:
		failures.append("Collected pickups were not replenished back to the bounded cap.")
	var paused_pickup := _first_active_child(pickups) as Node2D
	var paused_pickup_position := paused_pickup.global_position if paused_pickup != null else Vector2.ZERO
	var refresh_time_left := refresh_timer.time_left
	var pickup_time_left := pickup_timer.time_left
	player.clear_invulnerability()
	player.take_damage(player.maximum_health)
	if (
		not main.is_defeated()
		or not paused
		or population.can_process()
		or (paused_pickup != null and paused_pickup.can_process())
	):
		failures.append("Defeat did not freeze population generation and pickup collection.")
	await create_timer(0.12, true).timeout
	if (
		(paused_pickup != null and not paused_pickup.global_position.is_equal_approx(paused_pickup_position))
		or absf(refresh_timer.time_left - refresh_time_left) > 0.03
		or absf(pickup_timer.time_left - pickup_time_left) > 0.03
	):
		failures.append("World-population nodes or timers advanced while gameplay was paused.")

	main.restart_run()
	await process_frame
	await process_frame
	var restarted_main := current_scene
	if restarted_main == null or restarted_main == main:
		failures.append("F07 restart did not reload a fresh main scene.")
		return
	var restarted_population := restarted_main.get_node_or_null("World/WorldPopulation")
	var restarted_player := restarted_main.get_node_or_null("World/Player")
	if (
		paused
		or restarted_population == null
		or restarted_population.get_active_decoration_count() != restarted_population.maximum_decorations
		or restarted_population.get_active_pickup_count() != restarted_population.maximum_pickups
		or restarted_player.current_health != restarted_player.maximum_health
		or restarted_main.get_node("World/Enemies").get_child_count() != 0
		or restarted_main.get_node("World/Projectiles").get_child_count() != 0
		or restarted_main.get_node("World/XPCoins").get_child_count() != 0
	):
		failures.append("Restart retained F07 effects/entities or failed to create a fresh bounded population.")


func _positions_in_annulus(container: Node, center: Vector2, minimum_distance: float, maximum_distance: float) -> bool:
	for child: Node in container.get_children():
		if not child is Node2D or child.is_queued_for_deletion():
			continue
		var distance := (child as Node2D).global_position.distance_to(center)
		if distance < minimum_distance - 0.1 or distance > maximum_distance + 0.1:
			return false
	return true


func _active_instance_ids(container: Node) -> Array[int]:
	var ids: Array[int] = []
	for child: Node in container.get_children():
		if not child.is_queued_for_deletion():
			ids.append(child.get_instance_id())
	ids.sort()
	return ids


func _active_pickup_types(container: Node) -> Array[StringName]:
	var pickup_types: Array[StringName] = []
	for child: Node in container.get_children():
		if not child.is_queued_for_deletion():
			pickup_types.append(child.pickup_type)
	pickup_types.sort()
	return pickup_types


func _find_pickup(container: Node, pickup_type: StringName) -> Node2D:
	for child: Node in container.get_children():
		if not child.is_queued_for_deletion() and child.pickup_type == pickup_type:
			return child as Node2D
	return null


func _first_active_child(container: Node) -> Node:
	for child: Node in container.get_children():
		if not child.is_queued_for_deletion():
			return child
	return null
