extends SceneTree

var _rank_signal_ids: Array[StringName] = []
var _rank_signal_values: Array[int] = []


func _initialize() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	var failures: Array[String] = []
	await _verify_combat_abilities(failures)

	if failures.is_empty():
		print("F06 verification passed: stable offers, ranked Multishot, Piercing, Nova, pause, and restart are configured.")
		quit(0)
		return

	paused = false
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _verify_combat_abilities(failures: Array[String]) -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	if main_scene == null:
		failures.append("The main scene could not be loaded for F06 verification.")
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	main.connect(&"combat_ability_rank_changed", Callable(self, "_record_rank_change"))
	await process_frame

	var player := main.get_node_or_null("World/Player") as CharacterBody2D
	var weapon := main.get_node_or_null("World/Player/AutoWeapon")
	var fire_timer := main.get_node_or_null("World/Player/AutoWeapon/FireTimer") as Timer
	var nova := main.get_node_or_null("World/Player/NovaAbility") as Node2D
	var nova_timer := main.get_node_or_null("World/Player/NovaAbility/PulseTimer") as Timer
	var progression := main.get_node_or_null("RunProgression")
	var spawner := main.get_node_or_null("World/EnemySpawner")
	var spawn_timer := main.get_node_or_null("World/EnemySpawner/SpawnTimer") as Timer
	var enemies := main.get_node_or_null("World/Enemies")
	var projectiles := main.get_node_or_null("World/Projectiles")
	var choice_ui := main.get_node_or_null("HUD/UpgradeChoiceUI") as Control
	if (
		player == null
		or weapon == null
		or fire_timer == null
		or nova == null
		or nova_timer == null
		or progression == null
		or spawner == null
		or spawn_timer == null
		or enemies == null
		or projectiles == null
		or choice_ui == null
	):
		failures.append("The main scene is missing an F06 integration node.")
		main.free()
		return
	spawn_timer.stop()
	fire_timer.stop()

	if main.get_ability_ranks() != {&"multishot": 0, &"piercing": 0, &"nova": 0}:
		failures.append("Combat ability ranks did not initialize independently at zero.")
	if weapon.get_projectile_count() != 1 or weapon.get_projectile_hit_allowance() != 1:
		failures.append("The base weapon did not initialize as single-shot and non-piercing.")
	if nova.rank != 0 or not nova_timer.is_stopped():
		failures.append("Nova was active before its first rank was selected.")

	var target := spawner.spawn_enemy() as CharacterBody2D
	if target == null:
		failures.append("The spawner could not create a target for F06 volley verification.")
		main.free()
		return
	target.set_physics_process(false)
	target.global_position = player.global_position + Vector2(500.0, 0.0)
	weapon.try_fire()
	if (
		projectiles.get_child_count() != 1
		or (projectiles.get_child(0) as Area2D).hit_allowance != 1
	):
		failures.append("Multishot rank 0 did not fire exactly one projectile.")
	_clear_children(projectiles)

	var forced_offers: Array[StringName] = [
		&"multishot",
		&"multishot",
		&"multishot",
		&"piercing",
		&"nova",
		&"nova",
	]
	main.set_forced_combat_offers(forced_offers)
	progression.add_xp(76)
	if not paused or main.get_pending_upgrade_count() != 5 or main.get_current_combat_offer() != &"multishot":
		failures.append("Five queued level-ups did not open one paused stable Multishot offer.")
	var first_offer_metadata := choice_ui.call("get_choice_metadata", &"combat") as Dictionary
	await process_frame
	if (
		main.get_current_combat_offer() != &"multishot"
		or first_offer_metadata != choice_ui.call("get_choice_metadata", &"combat")
		or not String(first_offer_metadata.get("title", "")).contains("MULTISHOT")
		or not String(first_offer_metadata.get("title", "")).contains("RANK 1")
	):
		failures.append("The open combat offer rerolled or did not accurately name Multishot rank 1.")

	choice_ui.call("select_choice", &"combat")
	if main.get_ability_rank(&"multishot") != 1 or weapon.get_projectile_count() != 2:
		failures.append("Selecting the displayed Multishot rank 1 offer did not apply immediately.")
	weapon.try_fire()
	if projectiles.get_child_count() != 2 or not _angles_match(weapon.get_volley_angle_offsets(), [-4.5, 4.5]):
		failures.append("Multishot rank 1 did not create a centered two-projectile volley.")
	_clear_children(projectiles)
	if main.get_current_combat_offer() != &"multishot":
		failures.append("The next queued screen did not receive its own eligible forced offer.")

	choice_ui.call("select_choice", &"combat")
	if main.get_ability_rank(&"multishot") != 2 or weapon.get_projectile_count() != 3:
		failures.append("Selecting Multishot rank 2 did not raise its rank and projectile count to three.")
	weapon.try_fire()
	if projectiles.get_child_count() != 3 or not _angles_match(weapon.get_volley_angle_offsets(), [-9.0, 0.0, 9.0]):
		failures.append("Multishot rank 2 did not create a centered three-projectile volley.")
	_clear_children(projectiles)
	if main.get_eligible_combat_offers().has(&"multishot") or main.get_current_combat_offer() != &"piercing":
		failures.append("A max-rank ability was not filtered from the next combat offer.")

	var ranks_before_vitality: Dictionary = main.get_ability_ranks()
	choice_ui.call("select_choice", &"vitality")
	if main.get_ability_ranks() != ranks_before_vitality or main.get_current_combat_offer() != &"nova":
		failures.append("Vitality changed a combat rank or the next queued offer was not independent.")

	choice_ui.call("select_choice", &"combat")
	if main.get_ability_rank(&"nova") != 1 or nova.rank != 1:
		failures.append("Selecting the displayed Nova rank 1 offer did not activate Nova immediately.")
	if not is_equal_approx(nova.get_interval(), 5.0) or nova_timer.is_stopped():
		failures.append("Nova rank 1 did not start its single timer at the configured five-second interval.")
	if main.get_current_combat_offer() != &"nova" or not paused:
		failures.append("The queued Nova rank 2 screen did not remain paused and stable.")
	if nova.can_process():
		failures.append("The Nova component could still process while the upgrade overlay paused gameplay.")
	var time_left_before_pause: float = nova.get_time_left()
	await create_timer(0.12, true).timeout
	if absf(nova.get_time_left() - time_left_before_pause) > 0.03:
		failures.append("Nova timer progress continued while an upgrade screen paused gameplay.")

	var near_enemy := spawner.spawn_enemy() as CharacterBody2D
	var near_enemy_two := spawner.spawn_enemy() as CharacterBody2D
	var far_enemy := spawner.spawn_enemy() as CharacterBody2D
	near_enemy.set_physics_process(false)
	near_enemy_two.set_physics_process(false)
	far_enemy.set_physics_process(false)
	near_enemy.maximum_health = 100
	near_enemy.current_health = 100
	near_enemy_two.maximum_health = 100
	near_enemy_two.current_health = 100
	far_enemy.maximum_health = 100
	far_enemy.current_health = 100
	near_enemy.global_position = player.global_position + Vector2(nova.pulse_radius - 10.0, 0.0)
	near_enemy_two.global_position = player.global_position + Vector2(0.0, -nova.pulse_radius + 20.0)
	far_enemy.global_position = player.global_position + Vector2(nova.pulse_radius + 40.0, 0.0)
	var nova_child_count: int = nova.get_child_count()
	if (
		nova.emit_pulse() != 2
		or near_enemy.current_health != 100 - nova.rank_one_damage
		or near_enemy_two.current_health != 100 - nova.rank_one_damage
		or far_enemy.current_health != 100
	):
		failures.append("Nova rank 1 did not damage each in-radius normal enemy once while excluding an outside enemy.")

	choice_ui.call("select_choice", &"combat")
	if (
		paused
		or main.get_ability_rank(&"nova") != 2
		or nova.rank != 2
		or not is_equal_approx(nova.get_interval(), 3.5)
		or nova.get_damage() <= nova.rank_one_damage
	):
		failures.append("Nova rank 2 did not apply stronger damage and the configured 3.5-second interval.")
	near_enemy.current_health = 100
	near_enemy_two.current_health = 100
	far_enemy.current_health = 100
	if (
		nova.emit_pulse() != 2
		or near_enemy.current_health != 100 - nova.rank_two_damage
		or near_enemy_two.current_health != 100 - nova.rank_two_damage
		or far_enemy.current_health != 100
	):
		failures.append("Nova rank 2 did not use its stronger radius-filtered damage.")
	nova.emit_pulse()
	if nova.get_child_count() != nova_child_count or nova.get_pulse_count() != 3:
		failures.append("Repeated Nova pulses accumulated nodes or did not reuse the single pulse component.")

	weapon.set_combat_ranks(2, 2)
	weapon.try_fire()
	if projectiles.get_child_count() != 3:
		failures.append("The ranked weapon did not retain Multishot when Piercing was configured.")
	var piercing_projectile := projectiles.get_child(0) as Area2D
	if piercing_projectile == null or piercing_projectile.hit_allowance != 3 or piercing_projectile.remaining_hits != 3:
		failures.append("Piercing rank 2 did not configure new projectiles with three total hits.")
	else:
		near_enemy.current_health = 100
		near_enemy_two.current_health = 100
		far_enemy.current_health = 100
		var first_hit: bool = piercing_projectile.apply_hit(near_enemy)
		var duplicate_hit: bool = piercing_projectile.apply_hit(near_enemy)
		var second_hit: bool = piercing_projectile.apply_hit(far_enemy)
		var third_hit: bool = piercing_projectile.apply_hit(near_enemy_two)
		if not first_hit or duplicate_hit or not second_hit or not third_hit:
			failures.append("A piercing projectile did not hit three distinct enemies while rejecting a duplicate target.")
		if piercing_projectile.remaining_hits != 0 or not piercing_projectile.is_queued_for_deletion():
			failures.append("A piercing projectile was not exhausted after its configured distinct-hit allowance.")
	if weapon.get_projectile_hit_allowance() != 3:
		failures.append("Piercing rank 2 did not report a total hit allowance of three.")
	weapon.set_combat_ranks(0, 0)
	if weapon.get_projectile_hit_allowance() != 1:
		failures.append("Piercing rank 0 did not restore the base one-hit allowance.")
	weapon.set_combat_ranks(0, 1)
	_clear_children(projectiles)
	weapon.try_fire()
	if (
		weapon.get_projectile_hit_allowance() != 2
		or projectiles.get_child_count() != 1
		or (projectiles.get_child(0) as Area2D).hit_allowance != 2
	):
		failures.append("Piercing rank 1 did not provide exactly two total hits.")

	if _rank_signal_ids != [&"multishot", &"multishot", &"nova", &"nova"] or _rank_signal_values != [1, 2, 1, 2]:
		failures.append("Combat rank signals did not report exactly the displayed abilities and ranks once.")
	if main.get_applied_selection_count() != 5 or main.get_pending_upgrade_count() != 0 or choice_ui.visible:
		failures.append("The five F06 selections did not preserve F05 queue completion and UI guards.")
	player.clear_invulnerability()
	player.take_damage(player.maximum_health)
	if not main.is_defeated() or not paused or nova.can_process() or choice_ui.visible:
		failures.append("Defeat did not pause an active ranked Nova and preserve the hidden upgrade UI.")

	main.restart_run()
	await process_frame
	await process_frame
	var restarted_main := current_scene
	if restarted_main == null or restarted_main == main:
		failures.append("F06 restart did not reload a fresh main scene.")
		return
	var restarted_weapon := restarted_main.get_node_or_null("World/Player/AutoWeapon")
	var restarted_nova := restarted_main.get_node_or_null("World/Player/NovaAbility") as Node2D
	var restarted_nova_timer := restarted_main.get_node_or_null("World/Player/NovaAbility/PulseTimer") as Timer
	var restarted_ui := restarted_main.get_node_or_null("HUD/UpgradeChoiceUI") as Control
	if (
		paused
		or restarted_main.get_ability_ranks() != {&"multishot": 0, &"piercing": 0, &"nova": 0}
		or not restarted_main.get_current_combat_offer().is_empty()
		or restarted_weapon.get_projectile_count() != 1
		or restarted_weapon.get_projectile_hit_allowance() != 1
		or restarted_nova.rank != 0
		or not restarted_nova_timer.is_stopped()
		or restarted_nova.get_child_count() != 1
		or restarted_ui.visible
	):
		failures.append("Restart retained F06 ranks, offer, volley, piercing, Nova, pause, or UI state.")
	if (
		restarted_main.get_node("World/Enemies").get_child_count() != 0
		or restarted_main.get_node("World/Projectiles").get_child_count() != 0
		or restarted_main.get_node("World/XPCoins").get_child_count() != 0
	):
		failures.append("Restart retained F06 gameplay entities.")


func _clear_children(container: Node) -> void:
	for child: Node in container.get_children():
		child.free()


func _angles_match(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for index: int in range(actual.size()):
		if not is_equal_approx(float(actual[index]), float(expected[index])):
			return false
	return true


func _record_rank_change(ability_id: StringName, rank: int) -> void:
	_rank_signal_ids.append(ability_id)
	_rank_signal_values.append(rank)
