extends SceneTree


func _initialize() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	var failures: Array[String] = []
	await _verify_player_health(failures)
	await _verify_enemy_damage_and_separation(failures)
	await _verify_targeting_and_projectiles(failures)
	await _verify_main_combat_defeat_and_restart(failures)

	if failures.is_empty():
		print("F03 verification passed: auto-combat, damage, separation, defeat, and clean restart are configured.")
		quit(0)
		return

	paused = false
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _verify_player_health(failures: Array[String]) -> void:
	var packed_scene := load("res://scenes/player.tscn") as PackedScene
	if packed_scene == null:
		failures.append("The player scene could not be loaded for health verification.")
		return
	var player := packed_scene.instantiate() as CharacterBody2D
	root.add_child(player)
	await process_frame
	if player.maximum_health <= 0 or player.invulnerability_duration <= 0.0:
		failures.append("Player health or invulnerability tuning is not a positive centralized value.")
	if player.current_health != player.maximum_health:
		failures.append("The player does not initialize at full health.")
	if not player.take_damage(12):
		failures.append("The player rejected an eligible positive damage hit.")
	var health_after_hit: int = player.current_health
	if player.take_damage(12) or player.current_health != health_after_hit:
		failures.append("Player invulnerability did not reject repeated contact damage.")
	player.clear_invulnerability()
	player.take_damage(player.maximum_health * 2)
	if player.current_health != 0 or player.is_alive():
		failures.append("Player health did not clamp at zero and enter the dead state.")
	player.free()


func _verify_enemy_damage_and_separation(failures: Array[String]) -> void:
	var enemy_scene := load("res://scenes/enemy.tscn") as PackedScene
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	if enemy_scene == null or player_scene == null:
		failures.append("Combatant scenes could not be loaded for enemy verification.")
		return
	var player := player_scene.instantiate() as CharacterBody2D
	var first := enemy_scene.instantiate() as CharacterBody2D
	var second := enemy_scene.instantiate() as CharacterBody2D
	root.add_child(player)
	root.add_child(first)
	root.add_child(second)
	first.global_position = Vector2(100.0, 100.0)
	second.global_position = first.global_position
	player.global_position = Vector2(900.0, 100.0)
	first.set_target(player)
	second.set_target(player)
	await process_frame
	if first.maximum_health <= 0 or first.contact_damage <= 0:
		failures.append("Enemy health or contact damage is not a positive centralized value.")
	if first.enemy_separation_radius <= 0.0 or first.player_separation_radius <= 0.0:
		failures.append("Enemy separation tuning is not centralized and positive.")
	var first_separation: Vector2 = first.calculate_separation_velocity()
	var second_separation: Vector2 = second.calculate_separation_velocity()
	if first_separation.is_zero_approx():
		failures.append("Exact overlap does not produce a soft enemy/player separation response.")
	if not (first_separation + second_separation).is_zero_approx():
		failures.append("Exactly stacked enemies do not receive opposing soft-separation responses.")
	player.global_position = first.global_position
	var health_before_contact: int = player.current_health
	first._try_contact_damage()
	var health_after_contact: int = player.current_health
	first._try_contact_damage()
	if health_after_contact != health_before_contact - first.contact_damage:
		failures.append("Enemy proximity did not route centralized contact damage to the player.")
	if player.current_health != health_after_contact:
		failures.append("Sustained enemy contact bypassed the player invulnerability window.")
	if not first.take_damage(1) or first.current_health != first.maximum_health - 1:
		failures.append("Enemy reusable damage handling did not reduce health once.")
	first.take_damage(first.maximum_health)
	if first.is_alive() or first.is_in_group(&"normal_enemies") or not first.is_queued_for_deletion():
		failures.append("Enemy death is not idempotent or does not clean up its group/node state.")
	if first.take_damage(1):
		failures.append("An already dead enemy accepted damage more than once.")
	second.free()
	player.free()
	await process_frame


func _verify_targeting_and_projectiles(failures: Array[String]) -> void:
	var weapon_script := load("res://scripts/auto_weapon.gd") as Script
	var projectile_scene := load("res://scenes/projectile.tscn") as PackedScene
	var enemy_scene := load("res://scenes/enemy.tscn") as PackedScene
	if weapon_script == null or projectile_scene == null or enemy_scene == null:
		failures.append("Weapon, projectile, or enemy resources could not be loaded.")
		return

	var weapon := weapon_script.new() as Node
	var near_target := enemy_scene.instantiate() as Node2D
	var far_target := enemy_scene.instantiate() as Node2D
	near_target.position = Vector2(40.0, 0.0)
	far_target.position = Vector2(200.0, 0.0)
	var candidates: Array[Node] = [far_target, near_target]
	if weapon.find_nearest_target(Vector2.ZERO, candidates) != near_target:
		failures.append("Auto-weapon targeting did not choose the nearest living enemy.")
	if weapon.fire_interval <= 0.0:
		failures.append("The weapon fire interval is not a positive centralized value.")

	var projectile := projectile_scene.instantiate() as Area2D
	root.add_child(projectile)
	await process_frame
	if projectile.movement_speed <= 0.0 or projectile.damage <= 0 or projectile.maximum_lifetime <= 0.0 or projectile.hit_allowance <= 0:
		failures.append("Projectile speed, damage, lifetime, or hit allowance is not centralized and positive.")
	if not is_equal_approx(projectile.movement_speed, 480.0):
		failures.append("Projectile speed does not preserve the user-requested slower 480-unit tuning.")
	projectile.configure(Vector2.RIGHT)
	var start_position := projectile.global_position
	projectile._physics_process(0.25)
	if not is_equal_approx(projectile.global_position.x - start_position.x, projectile.movement_speed * 0.25):
		failures.append("Projectile movement is not frame-rate independent.")
	near_target.current_health = near_target.maximum_health
	if not projectile.apply_hit(near_target):
		failures.append("Projectile did not apply an eligible enemy hit.")
	if projectile.apply_hit(near_target):
		failures.append("Projectile damaged the same enemy more than once.")
	if not projectile.is_queued_for_deletion():
		failures.append("Projectile was not removed after exhausting its hit allowance.")

	var expiring_projectile := projectile_scene.instantiate() as Area2D
	root.add_child(expiring_projectile)
	await process_frame
	expiring_projectile._physics_process(expiring_projectile.maximum_lifetime + 0.01)
	if not expiring_projectile.is_queued_for_deletion():
		failures.append("Projectile was not removed when its lifetime expired.")

	var collision_enemy := enemy_scene.instantiate() as CharacterBody2D
	var collision_projectile := projectile_scene.instantiate() as Area2D
	root.add_child(collision_enemy)
	root.add_child(collision_projectile)
	collision_enemy.global_position = Vector2(500.0, 300.0)
	collision_projectile.global_position = collision_enemy.global_position
	collision_projectile.set_physics_process(false)
	var collision_health_before: int = collision_enemy.current_health
	var collision_damage: int = collision_projectile.damage
	await create_timer(0.1).timeout
	if collision_enemy.current_health != collision_health_before - collision_damage:
		failures.append("Projectile collision layers/masks did not route a hit to an overlapping enemy.")
	weapon.free()
	near_target.free()
	far_target.free()
	collision_enemy.free()
	await process_frame


func _verify_main_combat_defeat_and_restart(failures: Array[String]) -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		failures.append("The main scene could not be loaded for F03 integration verification.")
		return
	var main := packed_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	var player := main.get_node_or_null("World/Player") as CharacterBody2D
	var enemies := main.get_node_or_null("World/Enemies")
	var projectiles := main.get_node_or_null("World/Projectiles")
	var spawner := main.get_node_or_null("World/EnemySpawner")
	var weapon := main.get_node_or_null("World/Player/AutoWeapon")
	var fire_timer := main.get_node_or_null("World/Player/AutoWeapon/FireTimer") as Timer
	var health_label := main.get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Health/Value") as Label
	var overlay := main.get_node_or_null("HUD/DefeatOverlay") as Control
	var restart_button := main.get_node_or_null("HUD/DefeatOverlay/Center/Panel/Margin/Content/RestartButton") as Button
	if player == null or enemies == null or projectiles == null or spawner == null or weapon == null:
		failures.append("Main scene is missing an F03 combat integration node.")
		main.free()
		return
	if health_label == null or overlay == null or restart_button == null:
		failures.append("Main scene is missing the live health HUD or defeat controls.")
		main.free()
		return
	if fire_timer == null or fire_timer.is_stopped():
		failures.append("The auto-weapon timer is not running from its centralized interval.")
	if weapon.try_fire() != null or projectiles.get_child_count() != 0:
		failures.append("The auto-weapon did not wait safely when no target existed.")

	var enemy := spawner.spawn_enemy() as Node2D
	if enemy == null:
		failures.append("The spawner could not create an enemy for combat integration.")
	else:
		enemy.global_position = player.global_position + Vector2(160.0, 0.0)
		var fired_projectile := weapon.try_fire() as Node2D
		if fired_projectile == null:
			failures.append("The auto-weapon did not fire while a valid enemy existed.")
		elif not fired_projectile.direction.is_equal_approx(Vector2.RIGHT):
			failures.append("The auto-weapon projectile was not aimed at the nearest enemy.")
		var enemy_health_before_travel: int = enemy.current_health
		await create_timer(0.05).timeout
		if enemy.current_health != enemy_health_before_travel:
			failures.append("A newly spawned enemy registered a stale-origin projectile hit before the projectile reached it.")

	if not player.take_damage(12) or health_label.text != "%d / %d" % [player.current_health, player.maximum_health]:
		failures.append("Eligible player damage did not update the HUD immediately.")
	player.clear_invulnerability()
	player.take_damage(player.maximum_health)
	if not main.is_defeated() or not paused or not overlay.visible:
		failures.append("Zero player health did not pause gameplay and show defeat.")
	if player.can_process() or spawner.can_process() or weapon.can_process():
		failures.append("Player movement, spawning, or firing can still process during defeat.")
	if not overlay.can_process() or not restart_button.can_process():
		failures.append("Defeat UI is not operable while gameplay is paused.")

	main.restart_run()
	await process_frame
	await process_frame
	var restarted_main := current_scene
	if restarted_main == null or restarted_main == main:
		failures.append("Restart did not reload a new main scene instance.")
		return
	var restarted_player := restarted_main.get_node_or_null("World/Player")
	var restarted_overlay := restarted_main.get_node_or_null("HUD/DefeatOverlay") as Control
	var restarted_enemies := restarted_main.get_node_or_null("World/Enemies")
	var restarted_projectiles := restarted_main.get_node_or_null("World/Projectiles")
	var restarted_spawn_timer := restarted_main.get_node_or_null("World/EnemySpawner/SpawnTimer") as Timer
	var restarted_fire_timer := restarted_main.get_node_or_null("World/Player/AutoWeapon/FireTimer") as Timer
	if paused or restarted_main.is_defeated():
		failures.append("Restart retained the prior defeat or pause state.")
	if restarted_player == null or restarted_player.current_health != restarted_player.maximum_health or restarted_player.is_invulnerable():
		failures.append("Restart did not restore full health and clear invulnerability.")
	if restarted_overlay == null or restarted_overlay.visible:
		failures.append("Restart retained the visible defeat overlay.")
	if restarted_enemies == null or restarted_enemies.get_child_count() != 0:
		failures.append("Restart retained enemies from the prior run.")
	if restarted_projectiles == null or restarted_projectiles.get_child_count() != 0:
		failures.append("Restart retained projectiles from the prior run.")
	if restarted_spawn_timer == null or restarted_spawn_timer.is_stopped() or restarted_fire_timer == null or restarted_fire_timer.is_stopped():
		failures.append("Restart did not restore spawning and firing timers.")
