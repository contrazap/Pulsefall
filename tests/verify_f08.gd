extends SceneTree


func _initialize() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	var failures: Array[String] = []
	await _verify_boss_phase_victory_and_restart(failures)

	if failures.is_empty():
		print("F08 verification passed: boss transition, shared targeting, health HUD, victory, terminal guards, and restart are configured.")
		quit(0)
		return

	paused = false
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _verify_boss_phase_victory_and_restart(failures: Array[String]) -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var normal_scene := load("res://scenes/enemy.tscn") as PackedScene
	var projectile_scene := load("res://scenes/projectile.tscn") as PackedScene
	if main_scene == null or normal_scene == null or projectile_scene == null:
		failures.append("An F08 gameplay scene could not be loaded.")
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	var player := main.get_node_or_null("World/Player") as CharacterBody2D
	var camera := main.get_node_or_null("World/Player/Camera2D") as Camera2D
	var weapon := main.get_node_or_null("World/Player/AutoWeapon")
	var fire_timer := main.get_node_or_null("World/Player/AutoWeapon/FireTimer") as Timer
	var nova := main.get_node_or_null("World/Player/NovaAbility") as Node2D
	var spawner := main.get_node_or_null("World/EnemySpawner")
	var spawn_timer := main.get_node_or_null("World/EnemySpawner/SpawnTimer") as Timer
	var enemies := main.get_node_or_null("World/Enemies") as Node2D
	var bosses := main.get_node_or_null("World/Bosses") as Node2D
	var progression := main.get_node_or_null("RunProgression")
	var choice_ui := main.get_node_or_null("HUD/UpgradeChoiceUI") as Control
	var boss_hud := main.get_node_or_null("HUD/Layout/BossHealth") as Control
	var boss_bar := main.get_node_or_null("HUD/Layout/BossHealth/Margin/Content/Bar") as ProgressBar
	var boss_value := main.get_node_or_null("HUD/Layout/BossHealth/Margin/Content/Heading/Value") as Label
	var defeat_overlay := main.get_node_or_null("HUD/DefeatOverlay") as Control
	var victory_overlay := main.get_node_or_null("HUD/VictoryOverlay") as Control
	var victory_restart := main.get_node_or_null("HUD/VictoryOverlay/Center/Panel/Margin/Content/RestartButton") as Button
	var population := main.get_node_or_null("World/WorldPopulation")
	if (
		player == null
		or camera == null
		or weapon == null
		or fire_timer == null
		or nova == null
		or spawner == null
		or spawn_timer == null
		or enemies == null
		or bosses == null
		or progression == null
		or choice_ui == null
		or boss_hud == null
		or boss_bar == null
		or boss_value == null
		or defeat_overlay == null
		or victory_overlay == null
		or victory_restart == null
		or population == null
	):
		failures.append("The main scene is missing an F08 integration node.")
		main.free()
		return
	fire_timer.stop()

	if (
		main.is_boss_phase_started()
		or main.get_active_boss() != null
		or main.start_boss_phase() != null
		or bosses.get_child_count() != 0
		or boss_hud.visible
		or victory_overlay.visible
		or not spawner.is_spawning_enabled()
		or spawn_timer.is_stopped()
	):
		failures.append("A fresh run did not begin with hidden boss UI, no boss, and enabled normal spawning.")

	var retained_normal := spawner.spawn_enemy() as CharacterBody2D
	if retained_normal == null:
		failures.append("A normal enemy could not be created before the boss transition.")
		main.free()
		return
	retained_normal.set_physics_process(false)
	retained_normal.global_position = player.global_position + Vector2(420.0, 0.0)

	progression.add_xp(180)
	for selection_index: int in range(4):
		if not choice_ui.call("select_choice", &"vitality"):
			failures.append("A pre-boss Vitality choice could not be applied at selection %d." % [selection_index + 1])
			break
		if main.is_boss_phase_started() or bosses.get_child_count() != 0:
			failures.append("The boss appeared before the fifth applied upgrade selection.")
			break
	if not choice_ui.call("select_choice", &"vitality"):
		failures.append("The fifth upgrade choice could not be applied.")

	var boss := main.get_active_boss() as CharacterBody2D
	if (
		boss == null
		or not main.is_boss_phase_started()
		or main.get_applied_selection_count() != 5
		or player.maximum_health != 200
		or bosses.get_child_count() != 1
		or paused
	):
		failures.append("The fifth upgrade did not apply first and then begin one active, unpaused boss phase.")
		main.free()
		return
	boss.set_physics_process(false)
	if (
		not retained_normal.is_alive()
		or retained_normal.is_queued_for_deletion()
		or spawner.is_spawning_enabled()
		or not spawn_timer.is_stopped()
		or spawner.spawn_enemy() != null
		or main.start_boss_phase() != boss
		or bosses.get_child_count() != 1
	):
		failures.append("Boss transition did not retain normals, stop future spawning, and reject duplicate bosses.")
	if not spawner.is_position_beyond_spawn_margin(
		boss.global_position,
		camera.get_screen_center_position(),
		camera.get_viewport_rect().size,
		camera.zoom
	):
		failures.append("The boss did not spawn just beyond the current camera margin.")

	var normal_reference := normal_scene.instantiate() as CharacterBody2D
	if (
		not boss.is_in_group(&"bosses")
		or not boss.is_in_group(&"combat_targets")
		or boss.is_in_group(&"normal_enemies")
		or not retained_normal.is_in_group(&"combat_targets")
		or boss.maximum_health == normal_reference.maximum_health
		or is_equal_approx(boss.movement_speed, normal_reference.movement_speed)
		or boss.contact_damage == normal_reference.contact_damage
		or boss.get_node_or_null("SpikeCrown") == null
		or boss.get_node("CollisionShape2D").shape.radius <= normal_reference.get_node("CollisionShape2D").shape.radius
	):
		failures.append("Boss tuning, groups, collision size, or spiked presentation is not distinct from a normal enemy.")
	normal_reference.free()

	if (
		not boss_hud.visible
		or int(boss_bar.max_value) != boss.maximum_health
		or int(boss_bar.value) != boss.current_health
		or boss_value.text != "%d / %d" % [boss.current_health, boss.maximum_health]
	):
		failures.append("Boss health HUD did not initialize from the live boss health values.")
	var default_boss_hud_rect := boss_hud.get_global_rect()
	if default_boss_hud_rect.position.x < 0.0 or default_boss_hud_rect.position.y < 0.0 or default_boss_hud_rect.end.x > 1280.0 or default_boss_hud_rect.end.y > 720.0:
		failures.append("Boss health HUD did not fit within the default logical viewport.")
	root.size = Vector2i(800, 450)
	await process_frame
	var boss_hud_rect := boss_hud.get_global_rect()
	if (
		boss_hud_rect.position.x < 0.0
		or boss_hud_rect.position.y < 0.0
		or boss_hud_rect.end.x > 1280.0
		or boss_hud_rect.end.y > 720.0
		or boss_hud_rect.size.x < 400.0
	):
		failures.append("Boss health HUD was not readable within the stretched logical viewport at 800x450.")

	boss.global_position = player.global_position + Vector2(80.0, 0.0)
	retained_normal.global_position = player.global_position + Vector2(160.0, 0.0)
	var shared_targets := get_nodes_in_group(&"combat_targets")
	if weapon.target_group != &"combat_targets" or weapon.find_nearest_target(player.global_position, shared_targets) != boss:
		failures.append("AutoWeapon did not use the shared group to select the nearest boss or normal target.")
	nova.set_rank(1)
	var boss_health_before_nova: int = boss.current_health
	var normal_health_before_nova: int = retained_normal.current_health
	if (
		nova.target_group != &"combat_targets"
		or nova.emit_pulse() != 2
		or boss.current_health != boss_health_before_nova - nova.rank_one_damage
		or retained_normal.current_health != normal_health_before_nova - nova.rank_one_damage
	):
		failures.append("Nova did not damage both an in-range boss and normal enemy through the shared group.")

	var boss_health_before_bomb: int = boss.current_health
	var coins_before_normal_death: int = main.get_active_xp_coin_count()
	if (
		main.apply_world_pickup(&"bomb") != 1
		or boss.current_health != boss_health_before_bomb
		or not retained_normal.is_queued_for_deletion()
		or main.is_victorious()
		or main.get_active_xp_coin_count() != coins_before_normal_death + 1
	):
		failures.append("Bomb did not kill only the normal enemy through its XP path while leaving the boss and victory state untouched.")
	await process_frame

	var projectile := projectile_scene.instantiate() as Area2D
	main.get_node("World/Projectiles").add_child(projectile)
	await process_frame
	var health_before_projectile: int = boss.current_health
	if not projectile.apply_hit(boss) or boss.current_health != health_before_projectile - projectile.damage:
		failures.append("The reused boss implementation did not accept projectile damage.")
	if int(boss_bar.value) != boss.current_health or boss_value.text != "%d / %d" % [boss.current_health, boss.maximum_health]:
		failures.append("Boss health HUD did not update immediately after damage.")

	player.clear_invulnerability()
	var player_health_before_contact: int = player.current_health
	boss.global_position = player.global_position
	boss._try_contact_damage()
	var player_health_after_contact: int = player.current_health
	boss._try_contact_damage()
	if (
		player_health_after_contact != player_health_before_contact - boss.contact_damage
		or player.current_health != player_health_after_contact
	):
		failures.append("Boss contact did not reuse player damage and invulnerability behavior.")

	var coins_before_boss_death: int = main.get_active_xp_coin_count()
	boss.take_damage(boss.current_health)
	if (
		not main.is_victorious()
		or main.is_defeated()
		or not paused
		or not victory_overlay.visible
		or defeat_overlay.visible
		or boss_hud.visible
		or main.get_active_xp_coin_count() != coins_before_boss_death
		or population.can_process()
		or not victory_overlay.can_process()
		or not victory_restart.can_process()
	):
		failures.append("Boss death did not produce one paused victory without XP or continued world activity.")
	main._on_player_died()
	progression.emit_signal(&"level_up", 7)
	if main.is_defeated() or not main.is_victorious() or choice_ui.visible or main.apply_world_pickup(&"health") != 0:
		failures.append("Victory could be replaced by defeat, reopen upgrades, or accept later pickup effects.")

	main.restart_run()
	await process_frame
	await process_frame
	var restarted_main := current_scene
	if restarted_main == null or restarted_main == main:
		failures.append("Victory restart did not reload a fresh main scene.")
		return
	var restarted_spawner := restarted_main.get_node_or_null("World/EnemySpawner")
	var restarted_spawn_timer := restarted_main.get_node_or_null("World/EnemySpawner/SpawnTimer") as Timer
	var restarted_boss_hud := restarted_main.get_node_or_null("HUD/Layout/BossHealth") as Control
	var restarted_victory := restarted_main.get_node_or_null("HUD/VictoryOverlay") as Control
	var restarted_defeat := restarted_main.get_node_or_null("HUD/DefeatOverlay") as Control
	if (
		paused
		or restarted_main.is_boss_phase_started()
		or restarted_main.is_victorious()
		or restarted_main.is_defeated()
		or restarted_main.get_applied_selection_count() != 0
		or restarted_main.get_node("RunProgression").current_level != 1
		or restarted_main.get_node("World/Bosses").get_child_count() != 0
		or restarted_main.get_node("World/Enemies").get_child_count() != 0
		or restarted_main.get_node("World/Projectiles").get_child_count() != 0
		or restarted_main.get_node("World/XPCoins").get_child_count() != 0
		or not restarted_spawner.is_spawning_enabled()
		or restarted_spawn_timer.is_stopped()
		or restarted_boss_hud.visible
		or restarted_victory.visible
		or restarted_defeat.visible
	):
		failures.append("Victory restart retained boss, progression, entities, pause, terminal UI, or stopped spawning.")

	var restarted_progression := restarted_main.get_node("RunProgression")
	var restarted_choice_ui := restarted_main.get_node("HUD/UpgradeChoiceUI")
	restarted_progression.add_xp(180)
	for selection_index: int in range(5):
		restarted_choice_ui.select_choice(&"vitality")
	var defeat_boss := restarted_main.get_active_boss() as CharacterBody2D
	var restarted_player := restarted_main.get_node("World/Player") as CharacterBody2D
	if defeat_boss == null:
		failures.append("A second natural five-choice transition could not create the boss for defeat precedence.")
		return
	defeat_boss.set_physics_process(false)
	restarted_player.clear_invulnerability()
	restarted_player.take_damage(restarted_player.maximum_health)
	defeat_boss.take_damage(defeat_boss.current_health)
	if (
		not restarted_main.is_defeated()
		or restarted_main.is_victorious()
		or not restarted_defeat.visible
		or restarted_victory.visible
	):
		failures.append("Player death before boss death did not preserve defeat as the terminal result.")
