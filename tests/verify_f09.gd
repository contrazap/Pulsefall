extends SceneTree


func _initialize() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	var failures: Array[String] = []
	await _verify_complete_loop_and_restarts(failures)

	if failures.is_empty():
		print("F09 verification passed: complete run integration, bounded populations, both endings, and clean restarts are configured.")
		quit(0)
		return

	paused = false
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _verify_complete_loop_and_restarts(failures: Array[String]) -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	if main_scene == null:
		failures.append("The configured main scene could not be loaded for F09 verification.")
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	if not _is_clean_run(main):
		failures.append("A clean launch retained runtime state or did not initialize bounded world populations and timers.")
		main.free()
		return

	var player := main.get_node("World/Player") as CharacterBody2D
	var progression := main.get_node("RunProgression")
	var choice_ui := main.get_node("HUD/UpgradeChoiceUI") as Control
	var spawner := main.get_node("World/EnemySpawner")
	var spawn_timer := main.get_node("World/EnemySpawner/SpawnTimer") as Timer
	var fire_timer := main.get_node("World/Player/AutoWeapon/FireTimer") as Timer
	var weapon := main.get_node("World/Player/AutoWeapon")
	var nova := main.get_node("World/Player/NovaAbility") as Node2D
	var bosses := main.get_node("World/Bosses") as Node2D
	var boss_hud := main.get_node("HUD/Layout/BossHealth") as Control
	var victory_overlay := main.get_node("HUD/VictoryOverlay") as Control
	var victory_button := main.get_node("HUD/VictoryOverlay/Center/Panel/Margin/Content/RestartButton") as Button
	spawn_timer.stop()
	fire_timer.stop()
	var base_maximum_health: int = player.maximum_health
	var base_speed: float = player.movement_speed

	var selections: Array[StringName] = [
		&"vitality",
		&"combat",
		&"combat",
		&"haste",
		&"combat",
	]
	var combat_offers: Array[StringName] = [&"multishot", &"piercing", &"nova"]
	var combat_offer_index := 0
	for selection_index: int in range(selections.size()):
		var choice_id: StringName = selections[selection_index]
		if choice_id == &"combat":
			var forced_offer: Array[StringName] = [combat_offers[combat_offer_index]]
			main.set_forced_combat_offers(forced_offer)
			combat_offer_index += 1
		var xp_needed: int = progression.get_required_xp() - progression.current_xp
		if selection_index == 0:
			xp_needed += 2
		var coin: Node2D = main.create_xp_drop(player.global_position, xp_needed)
		if coin == null or not coin.collect():
			failures.append("Selection %d could not be reached through the real XP-coin collection path." % [selection_index + 1])
			main.free()
			return
		if (
			not paused
			or not main.is_upgrade_choice_open()
			or main.get_pending_upgrade_count() != 1
			or choice_ui.get_offered_level() != selection_index + 2
		):
			failures.append("Selection %d did not produce one ordered paused upgrade screen." % [selection_index + 1])
		if selection_index < 4 and (main.is_boss_phase_started() or bosses.get_child_count() != 0):
			failures.append("The boss appeared before selection five during the complete-loop sequence.")
		if not choice_ui.select_choice(choice_id):
			failures.append("Selection %d could not be resolved through the live choice UI." % [selection_index + 1])
			main.free()
			return
		if main.get_applied_selection_count() != selection_index + 1:
			failures.append("Applied selection count did not advance exactly once at selection %d." % [selection_index + 1])

	if (
		paused
		or player.maximum_health != base_maximum_health + 20
		or not is_equal_approx(player.movement_speed, base_speed * 1.12)
		or main.get_ability_rank(&"multishot") != 1
		or main.get_ability_rank(&"piercing") != 1
		or main.get_ability_rank(&"nova") != 1
		or weapon.get_projectile_count() != 2
		or weapon.get_projectile_hit_allowance() != 2
		or nova.rank != 1
		or not progression.completed
	):
		failures.append("The five-choice path did not preserve carry-over and immediately integrate stat/combat effects.")
	var boss := main.get_active_boss() as CharacterBody2D
	if (
		boss == null
		or bosses.get_child_count() != 1
		or not main.is_boss_phase_started()
		or spawner.is_spawning_enabled()
		or not spawn_timer.is_stopped()
		or not boss_hud.visible
	):
		failures.append("Selection five did not create exactly one readable boss and stop normal spawning.")
		main.free()
		return
	boss.set_physics_process(false)
	boss.global_position = player.global_position + Vector2(nova.pulse_radius - 20.0, 0.0)
	var boss_health_before_abilities: int = boss.current_health
	if nova.emit_pulse() != 1 or boss.current_health >= boss_health_before_abilities:
		failures.append("The integrated combat build could not damage the boss with Nova.")
	var projectile := weapon.try_fire() as Area2D
	if projectile == null or not projectile.apply_hit(boss):
		failures.append("The integrated Multishot/Piercing weapon could not target and damage the boss.")
	_clear_children(main.get_node("World/Projectiles"))
	var xp_before_boss_death: int = main.get_active_xp_coin_count()
	boss.take_damage(boss.current_health)
	if (
		not main.is_victorious()
		or main.is_defeated()
		or not paused
		or not victory_overlay.visible
		or boss_hud.visible
		or main.get_active_xp_coin_count() != xp_before_boss_death
	):
		failures.append("The complete-loop boss death did not produce only a paused XP-free victory.")
	victory_button.pressed.emit()
	await process_frame
	await process_frame
	var after_victory := current_scene
	if after_victory == null or after_victory == main or not _is_clean_run(after_victory):
		failures.append("The victory restart button did not restore the clean base run.")
		return

	await _verify_population_stress(after_victory, failures)
	var defeat_player := after_victory.get_node("World/Player") as CharacterBody2D
	var defeat_overlay := after_victory.get_node("HUD/DefeatOverlay") as Control
	var defeat_button := after_victory.get_node("HUD/DefeatOverlay/Center/Panel/Margin/Content/RestartButton") as Button
	defeat_player.clear_invulnerability()
	defeat_player.take_damage(defeat_player.maximum_health)
	if not after_victory.is_defeated() or after_victory.is_victorious() or not paused or not defeat_overlay.visible:
		failures.append("Player death after the stress segment did not produce only the paused defeat state.")
	var terminal_counts := _runtime_counts(after_victory)
	await create_timer(0.12, true).timeout
	if _runtime_counts(after_victory) != terminal_counts:
		failures.append("A runtime population changed while the defeat state paused the complete run.")
	defeat_button.pressed.emit()
	await process_frame
	await process_frame
	var after_defeat := current_scene
	if after_defeat == null or after_defeat == after_victory or not _is_clean_run(after_defeat):
		failures.append("The defeat restart button did not restore the same clean base run.")


func _verify_population_stress(main: Node, failures: Array[String]) -> void:
	var player := main.get_node("World/Player") as CharacterBody2D
	var spawner := main.get_node("World/EnemySpawner")
	var spawn_timer := main.get_node("World/EnemySpawner/SpawnTimer") as Timer
	var weapon := main.get_node("World/Player/AutoWeapon")
	var fire_timer := main.get_node("World/Player/AutoWeapon/FireTimer") as Timer
	var enemies := main.get_node("World/Enemies") as Node2D
	var projectiles := main.get_node("World/Projectiles") as Node2D
	var coins := main.get_node("World/XPCoins") as Node2D
	var decorations := main.get_node("World/Decorations") as Node2D
	var pickups := main.get_node("World/Pickups") as Node2D
	var bosses := main.get_node("World/Bosses") as Node2D
	var population := main.get_node("World/WorldPopulation")
	spawn_timer.stop()
	fire_timer.stop()
	population.set_random_seed(909)
	var decoration_ids := _active_instance_ids(decorations)
	var pickup_ids := _active_instance_ids(pickups)

	for spawn_index: int in range(spawner.maximum_active_enemies + 8):
		var enemy := spawner.spawn_enemy() as CharacterBody2D
		if enemy != null:
			enemy.set_physics_process(false)
			enemy.global_position = player.global_position + Vector2(1600.0 + spawn_index * 3.0, 0.0)
	if spawner.get_active_enemy_count() != spawner.maximum_active_enemies or spawner.spawn_enemy() != null:
		failures.append("Normal-enemy stress exceeded or failed to reach the configured hard cap.")
	var first_enemy := enemies.get_child(0) as CharacterBody2D
	var second_enemy := enemies.get_child(1) as CharacterBody2D
	first_enemy.global_position = player.global_position + Vector2(200.0, 0.0)
	second_enemy.global_position = first_enemy.global_position
	var first_separation: Vector2 = first_enemy.calculate_separation_velocity()
	var second_separation: Vector2 = second_enemy.calculate_separation_velocity()
	if first_separation.is_zero_approx() or not (first_separation + second_separation).is_zero_approx():
		failures.append("Dense overlap did not retain the soft opposing separation response.")
	first_enemy.global_position = player.global_position
	if first_enemy.calculate_separation_velocity().is_zero_approx():
		failures.append("An enemy directly on the player did not receive a soft displacement response.")
	first_enemy.global_position = player.global_position + Vector2(5000.0, 0.0)
	second_enemy.global_position = player.global_position + Vector2(5100.0, 0.0)

	weapon.set_combat_ranks(2, 2)
	var projectile_scene := weapon.projectile_scene as PackedScene
	var projectile_reference := projectile_scene.instantiate() as Area2D
	var projectile_bound: int = (ceili(projectile_reference.maximum_lifetime / weapon.fire_interval) + 2) * weapon.get_projectile_count()
	projectile_reference.free()
	var observed_projectile_max := 0
	var frames_per_volley := maxi(roundi(weapon.fire_interval * 60.0), 1)
	for frame_index: int in range(360):
		if frame_index % frames_per_volley == 0:
			weapon.try_fire()
		for projectile_node: Node in projectiles.get_children():
			if not projectile_node.is_queued_for_deletion():
				projectile_node.call("_physics_process", 1.0 / 60.0)
		observed_projectile_max = maxi(observed_projectile_max, _active_child_count(projectiles))
		if observed_projectile_max > projectile_bound:
			break
	if observed_projectile_max <= 0 or observed_projectile_max > projectile_bound:
		failures.append("Sustained firing did not remain within its lifetime/interval-derived projectile bound.")
	for projectile_node: Node in projectiles.get_children():
		if projectile_node.has_method("_physics_process"):
			projectile_node.call("_physics_process", projectile_node.maximum_lifetime + 0.1)
	await process_frame
	if _active_child_count(projectiles) != 0:
		failures.append("Expired projectiles remained active after their centralized lifetime.")

	main.maximum_active_xp_coins = 40
	for coin_index: int in range(55):
		main.create_xp_drop(player.global_position + Vector2(2500.0 + coin_index, 0.0), 1)
	if _active_child_count(coins) != main.maximum_active_xp_coins or _total_xp_value(coins) != 55:
		failures.append("XP stress did not enforce the cap while preserving merged XP value.")

	for travel_index: int in range(12):
		player.global_position += Vector2(2200.0, 310.0)
		population.refresh_population()
		if (
			_active_child_count(decorations) > population.maximum_decorations
			or _active_child_count(pickups) > population.maximum_pickups
			or _active_child_count(enemies) > spawner.maximum_active_enemies
			or _active_child_count(coins) > main.maximum_active_xp_coins
			or _active_child_count(bosses) > 1
		):
			failures.append("Long-distance travel exceeded a configured runtime population cap.")
			break
	if _active_instance_ids(decorations) != decoration_ids or _active_instance_ids(pickups) != pickup_ids:
		failures.append("Long-distance travel replaced bounded decoration/pickup nodes instead of recycling them.")
	var pickup_types := _pickup_types(pickups)
	if pickup_types.size() != 3 or not pickup_types.has(&"health") or not pickup_types.has(&"magnet") or not pickup_types.has(&"bomb"):
		failures.append("The bounded pickup population lost one of its three readable stable types.")


func _is_clean_run(main: Node) -> bool:
	var player := main.get_node_or_null("World/Player") as CharacterBody2D
	var population := main.get_node_or_null("World/WorldPopulation")
	var spawner := main.get_node_or_null("World/EnemySpawner")
	var spawn_timer := main.get_node_or_null("World/EnemySpawner/SpawnTimer") as Timer
	var fire_timer := main.get_node_or_null("World/Player/AutoWeapon/FireTimer") as Timer
	if player == null or population == null or spawner == null or spawn_timer == null or fire_timer == null:
		return false
	return (
		not paused
		and player.current_health == player.maximum_health
		and not player.is_invulnerable()
		and main.get_node("RunProgression").current_level == 1
		and main.get_node("RunProgression").current_xp == 0
		and main.get_applied_selection_count() == 0
		and main.get_ability_ranks() == {&"multishot": 0, &"piercing": 0, &"nova": 0}
		and not main.is_upgrade_choice_open()
		and not main.is_boss_phase_started()
		and not main.is_defeated()
		and not main.is_victorious()
		and main.get_node("World/Enemies").get_child_count() == 0
		and main.get_node("World/Projectiles").get_child_count() == 0
		and main.get_node("World/XPCoins").get_child_count() == 0
		and main.get_node("World/Bosses").get_child_count() == 0
		and population.get_active_decoration_count() == population.maximum_decorations
		and population.get_active_pickup_count() == population.maximum_pickups
		and spawner.is_spawning_enabled()
		and not spawn_timer.is_stopped()
		and not fire_timer.is_stopped()
		and not main.get_node("HUD/UpgradeChoiceUI").visible
		and not main.get_node("HUD/Layout/BossHealth").visible
		and not main.get_node("HUD/DefeatOverlay").visible
		and not main.get_node("HUD/VictoryOverlay").visible
	)


func _runtime_counts(main: Node) -> Dictionary:
	return {
		"enemies": _active_child_count(main.get_node("World/Enemies")),
		"projectiles": _active_child_count(main.get_node("World/Projectiles")),
		"coins": _active_child_count(main.get_node("World/XPCoins")),
		"decorations": _active_child_count(main.get_node("World/Decorations")),
		"pickups": _active_child_count(main.get_node("World/Pickups")),
		"bosses": _active_child_count(main.get_node("World/Bosses")),
	}


func _active_child_count(container: Node) -> int:
	var count := 0
	for child: Node in container.get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count


func _active_instance_ids(container: Node) -> Array[int]:
	var ids: Array[int] = []
	for child: Node in container.get_children():
		if not child.is_queued_for_deletion():
			ids.append(child.get_instance_id())
	ids.sort()
	return ids


func _pickup_types(container: Node) -> Array[StringName]:
	var types: Array[StringName] = []
	for child: Node in container.get_children():
		if not child.is_queued_for_deletion():
			types.append(child.pickup_type)
	types.sort()
	return types


func _total_xp_value(container: Node) -> int:
	var total := 0
	for child: Node in container.get_children():
		if not child.is_queued_for_deletion():
			total += child.xp_value
	return total


func _clear_children(container: Node) -> void:
	for child: Node in container.get_children():
		child.free()
