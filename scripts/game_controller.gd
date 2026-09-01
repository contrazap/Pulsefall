extends Node2D

signal combat_choice_selected(combat_choice_id: StringName)
signal combat_ability_rank_changed(ability_id: StringName, rank: int)
signal selection_applied(choice_id: StringName, applied_selection_count: int, level: int)

const CHOICE_VITALITY: StringName = &"vitality"
const CHOICE_HASTE: StringName = &"haste"
const CHOICE_COMBAT: StringName = &"combat"
const VALID_UPGRADE_CHOICES: Array[StringName] = [CHOICE_VITALITY, CHOICE_HASTE, CHOICE_COMBAT]
const MAXIMUM_UPGRADE_SELECTIONS: int = 5
const PICKUP_HEALTH: StringName = &"health"
const PICKUP_MAGNET: StringName = &"magnet"
const PICKUP_BOMB: StringName = &"bomb"
const HEALTH_PICKUP_RESTORE: int = 25
const BOMB_PICKUP_DAMAGE: int = 250
const ABILITY_MULTISHOT: StringName = &"multishot"
const ABILITY_PIERCING: StringName = &"piercing"
const ABILITY_NOVA: StringName = &"nova"
const ABILITY_IDS: Array[StringName] = [ABILITY_MULTISHOT, ABILITY_PIERCING, ABILITY_NOVA]
const MAXIMUM_ABILITY_RANK: int = 2
const ABILITY_METADATA: Dictionary = {
	ABILITY_MULTISHOT: {
		"title": "MULTISHOT",
		"rank_descriptions": [
			"Fire 2 projectiles\nSmall centered spread",
			"Fire 3 projectiles\nWider centered spread",
		],
	},
	ABILITY_PIERCING: {
		"title": "PIERCING",
		"rank_descriptions": [
			"Projectiles hit 2 enemies\nDistinct targets only",
			"Projectiles hit 3 enemies\nDistinct targets only",
		],
	},
	ABILITY_NOVA: {
		"title": "NOVA",
		"rank_descriptions": [
			"Radial pulse every 5 seconds\nDamages nearby enemies",
			"Stronger radial pulse\nRepeats every 3.5 seconds",
		],
	},
}

@export var xp_coin_scene: PackedScene
@export var boss_scene: PackedScene
@export_range(1, 500, 1) var maximum_active_xp_coins: int = 40

var _player: Node
var _health_label: Label
var _level_label: Label
var _xp_label: Label
var _xp_bar: ProgressBar
var _defeat_overlay: Control
var _victory_overlay: Control
var _boss_health_hud: Control
var _boss_health_bar: ProgressBar
var _boss_health_value: Label
var _upgrade_choice_ui: Control
var _enemy_spawner: Node
var _boss_container: Node2D
var _xp_coin_container: Node
var _progression: Node
var _auto_weapon: Node
var _nova_ability: Node
var _world_population: Node
var _defeated: bool = false
var _victorious: bool = false
var _boss_phase_started: bool = false
var _boss: Node2D
var _choice_open: bool = false
var _pending_level_ups: Array[int] = []
var _applied_selection_count: int = 0
var _ability_ranks: Dictionary = {
	ABILITY_MULTISHOT: 0,
	ABILITY_PIERCING: 0,
	ABILITY_NOVA: 0,
}
var _current_combat_offer: StringName = &""
var _forced_combat_offers: Array[StringName] = []
var _ability_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_player = get_node_or_null("World/Player")
	_health_label = get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Health/Value") as Label
	_level_label = get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Level/Value") as Label
	_xp_label = get_node_or_null("HUD/Layout/TopBar/Margin/Stats/XP/Heading/Value") as Label
	_xp_bar = get_node_or_null("HUD/Layout/TopBar/Margin/Stats/XP/Bar") as ProgressBar
	_defeat_overlay = get_node_or_null("HUD/DefeatOverlay") as Control
	_victory_overlay = get_node_or_null("HUD/VictoryOverlay") as Control
	_boss_health_hud = get_node_or_null("HUD/Layout/BossHealth") as Control
	_boss_health_bar = get_node_or_null("HUD/Layout/BossHealth/Margin/Content/Bar") as ProgressBar
	_boss_health_value = get_node_or_null("HUD/Layout/BossHealth/Margin/Content/Heading/Value") as Label
	_upgrade_choice_ui = get_node_or_null("HUD/UpgradeChoiceUI") as Control
	_enemy_spawner = get_node_or_null("World/EnemySpawner")
	_boss_container = get_node_or_null("World/Bosses") as Node2D
	_xp_coin_container = get_node_or_null("World/XPCoins")
	_progression = get_node_or_null("RunProgression")
	_auto_weapon = get_node_or_null("World/Player/AutoWeapon")
	_nova_ability = get_node_or_null("World/Player/NovaAbility")
	_world_population = get_node_or_null("World/WorldPopulation")
	var defeat_restart_button := get_node_or_null("HUD/DefeatOverlay/Center/Panel/Margin/Content/RestartButton") as Button
	var victory_restart_button := get_node_or_null("HUD/VictoryOverlay/Center/Panel/Margin/Content/RestartButton") as Button
	if (
		_player == null
		or _health_label == null
		or _level_label == null
		or _xp_label == null
		or _xp_bar == null
		or _defeat_overlay == null
		or _victory_overlay == null
		or _boss_health_hud == null
		or _boss_health_bar == null
		or _boss_health_value == null
		or _upgrade_choice_ui == null
		or _enemy_spawner == null
		or _boss_container == null
		or _xp_coin_container == null
		or _progression == null
		or _auto_weapon == null
		or _nova_ability == null
		or _world_population == null
		or defeat_restart_button == null
		or victory_restart_button == null
		or boss_scene == null
	):
		push_error("GameController requires its player, progression, world containers, boss scene, and terminal HUD controls.")
		return
	_player.health_changed.connect(_on_player_health_changed)
	_player.died.connect(_on_player_died)
	_enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	_progression.progress_changed.connect(_on_progress_changed)
	_progression.level_up.connect(_on_level_up)
	_upgrade_choice_ui.connect(&"choice_selected", Callable(self, "_on_upgrade_choice_selected"))
	_world_population.connect(&"pickup_collected", Callable(self, "_on_world_pickup_collected"))
	defeat_restart_button.pressed.connect(restart_run)
	victory_restart_button.pressed.connect(restart_run)
	_defeat_overlay.hide()
	_victory_overlay.hide()
	_boss_health_hud.hide()
	_upgrade_choice_ui.call("hide_choices")
	_ability_rng.randomize()
	_apply_combat_rank_effects()
	_on_player_health_changed(_player.current_health, _player.maximum_health)
	_on_progress_changed(
		_progression.current_level,
		_progression.current_xp,
		_progression.get_required_xp(),
		_progression.completed
	)


func _exit_tree() -> void:
	if (_defeated or _victorious or _choice_open) and get_tree() != null:
		get_tree().paused = false


func restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func is_defeated() -> bool:
	return _defeated


func is_victorious() -> bool:
	return _victorious


func is_boss_phase_started() -> bool:
	return _boss_phase_started


func get_active_boss() -> Node2D:
	return _boss if is_instance_valid(_boss) and not _boss.is_queued_for_deletion() else null


func is_upgrade_choice_open() -> bool:
	return _choice_open


func get_pending_upgrade_count() -> int:
	return _pending_level_ups.size()


func get_applied_selection_count() -> int:
	return _applied_selection_count


func get_ability_rank(ability_id: StringName) -> int:
	return int(_ability_ranks.get(ability_id, 0))


func get_ability_ranks() -> Dictionary:
	return _ability_ranks.duplicate()


func get_current_combat_offer() -> StringName:
	return _current_combat_offer


func get_eligible_combat_offers() -> Array[StringName]:
	var eligible: Array[StringName] = []
	for ability_id: StringName in ABILITY_IDS:
		if get_ability_rank(ability_id) < MAXIMUM_ABILITY_RANK:
			eligible.append(ability_id)
	return eligible


func get_ability_offer_metadata(ability_id: StringName) -> Dictionary:
	if not ABILITY_METADATA.has(ability_id):
		return {}
	var rank := get_ability_rank(ability_id)
	if rank >= MAXIMUM_ABILITY_RANK:
		return {}
	var ability_data: Dictionary = ABILITY_METADATA[ability_id]
	var descriptions: Array = ability_data["rank_descriptions"]
	return {
		"ability_id": ability_id,
		"title": "%s — RANK %d" % [ability_data["title"], rank + 1],
		"description": descriptions[rank],
		"next_rank": rank + 1,
	}


func set_forced_combat_offers(ability_ids: Array[StringName]) -> void:
	_forced_combat_offers.clear()
	for ability_id: StringName in ability_ids:
		if ABILITY_IDS.has(ability_id):
			_forced_combat_offers.append(ability_id)


func apply_upgrade_choice(choice_id: StringName, offered_level: int) -> bool:
	if (
		_is_run_ended()
		or not _choice_open
		or _pending_level_ups.is_empty()
		or not VALID_UPGRADE_CHOICES.has(choice_id)
		or _pending_level_ups[0] != offered_level
		or (choice_id == CHOICE_COMBAT and _current_combat_offer.is_empty())
	):
		return false

	var resolved_combat_offer := _current_combat_offer
	_choice_open = false
	_pending_level_ups.pop_front()
	match choice_id:
		CHOICE_VITALITY:
			_player.call("apply_vitality")
		CHOICE_HASTE:
			_player.call("apply_haste")
		CHOICE_COMBAT:
			_apply_combat_ability(resolved_combat_offer)
			combat_choice_selected.emit(CHOICE_COMBAT)
	_current_combat_offer = &""
	_applied_selection_count += 1
	_upgrade_choice_ui.call("hide_choices")
	selection_applied.emit(choice_id, _applied_selection_count, offered_level)
	if _applied_selection_count == MAXIMUM_UPGRADE_SELECTIONS:
		start_boss_phase()
	_show_next_upgrade_choice()
	return true


func create_xp_drop(world_position: Vector2, xp_value: int = 1) -> Node2D:
	if xp_value <= 0 or xp_coin_scene == null or not is_instance_valid(_xp_coin_container):
		return null

	if get_active_xp_coin_count() >= maximum_active_xp_coins:
		var merge_target := _find_xp_merge_target()
		if merge_target != null:
			merge_target.call("add_xp_value", xp_value)
			return merge_target

	var coin := xp_coin_scene.instantiate() as Node2D
	if coin == null:
		push_error("GameController's xp_coin_scene must instantiate a Node2D.")
		return null
	_xp_coin_container.add_child(coin)
	coin.global_position = world_position
	coin.call("configure", _player, xp_value)
	coin.connect(&"collected", Callable(self, "_on_xp_coin_collected"))
	return coin


func get_active_xp_coin_count() -> int:
	if not is_instance_valid(_xp_coin_container):
		return 0
	var active_count := 0
	for child: Node in _xp_coin_container.get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			active_count += 1
	return active_count


func apply_world_pickup(pickup_type: StringName) -> int:
	if _is_run_ended() or not is_instance_valid(_player) or not _player.call("is_alive"):
		return 0
	match pickup_type:
		PICKUP_HEALTH:
			return int(_player.call("heal", HEALTH_PICKUP_RESTORE))
		PICKUP_MAGNET:
			return _collect_all_xp_coins()
		PICKUP_BOMB:
			return _damage_all_normal_enemies()
	return 0


func _on_player_health_changed(current_health: int, maximum_health: int) -> void:
	if is_instance_valid(_health_label):
		_health_label.text = "%d / %d" % [current_health, maximum_health]


func _on_player_died() -> void:
	if _is_run_ended():
		return
	_defeated = true
	_choice_open = false
	_pending_level_ups.clear()
	_current_combat_offer = &""
	_upgrade_choice_ui.call("hide_choices")
	_defeat_overlay.show()
	get_tree().paused = true


func start_boss_phase() -> Node2D:
	if _boss_phase_started or _is_run_ended() or boss_scene == null:
		return get_active_boss()
	if _applied_selection_count < MAXIMUM_UPGRADE_SELECTIONS:
		return null
	_boss_phase_started = true
	_enemy_spawner.call("set_spawning_enabled", false)
	var next_boss := boss_scene.instantiate() as Node2D
	if next_boss == null:
		push_error("GameController's boss_scene must instantiate a Node2D.")
		return null
	_boss_container.add_child(next_boss)
	var boss_spawn_position: Vector2 = _enemy_spawner.call("calculate_current_spawn_position")
	next_boss.global_position = boss_spawn_position
	if next_boss.has_method("set_target"):
		next_boss.call("set_target", _player)
	if next_boss.has_signal(&"health_changed"):
		next_boss.connect(&"health_changed", Callable(self, "_on_boss_health_changed"))
	if next_boss.has_signal(&"died"):
		next_boss.connect(&"died", Callable(self, "_on_boss_died"))
	_boss = next_boss
	_on_boss_health_changed(next_boss.current_health, next_boss.maximum_health)
	_boss_health_hud.show()
	return next_boss


func _on_boss_health_changed(current_health: int, maximum_health: int) -> void:
	if not is_instance_valid(_boss_health_bar) or not is_instance_valid(_boss_health_value):
		return
	_boss_health_bar.max_value = float(maximum_health)
	_boss_health_bar.value = float(current_health)
	_boss_health_value.text = "%d / %d" % [current_health, maximum_health]


func _on_boss_died(dead_boss: Node) -> void:
	if _is_run_ended() or dead_boss != _boss:
		return
	_victorious = true
	_choice_open = false
	_pending_level_ups.clear()
	_current_combat_offer = &""
	_upgrade_choice_ui.call("hide_choices")
	_boss_health_hud.hide()
	_victory_overlay.show()
	get_tree().paused = true


func _on_enemy_spawned(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or not enemy.has_signal(&"died"):
		return
	enemy.connect(&"died", Callable(self, "_on_enemy_died"))


func _on_enemy_died(enemy: Node) -> void:
	if not enemy is Node2D:
		return
	create_xp_drop((enemy as Node2D).global_position, 1)


func _on_xp_coin_collected(xp_value: int) -> void:
	if is_instance_valid(_progression):
		_progression.add_xp(xp_value)


func _on_world_pickup_collected(pickup_type: StringName) -> void:
	apply_world_pickup(pickup_type)


func _on_level_up(level: int) -> void:
	if _is_run_ended() or _applied_selection_count + _pending_level_ups.size() >= MAXIMUM_UPGRADE_SELECTIONS:
		return
	_pending_level_ups.append(level)
	_show_next_upgrade_choice()


func _on_upgrade_choice_selected(choice_id: StringName, offered_level: int) -> void:
	apply_upgrade_choice(choice_id, offered_level)


func _on_progress_changed(level: int, current_xp: int, required_xp: int, completed: bool) -> void:
	if not is_instance_valid(_level_label) or not is_instance_valid(_xp_label) or not is_instance_valid(_xp_bar):
		return
	_level_label.text = str(level)
	if completed:
		_xp_label.text = "COMPLETE"
		_xp_bar.max_value = 1.0
		_xp_bar.value = 1.0
		return
	_xp_label.text = "%d / %d" % [current_xp, required_xp]
	_xp_bar.max_value = float(required_xp)
	_xp_bar.value = float(current_xp)


func _find_xp_merge_target() -> Node2D:
	for child: Node in _xp_coin_container.get_children():
		if child is Node2D and is_instance_valid(child) and not child.is_queued_for_deletion():
			return child as Node2D
	return null


func _collect_all_xp_coins() -> int:
	if not is_instance_valid(_xp_coin_container):
		return 0
	var collected_count := 0
	var coins := _xp_coin_container.get_children()
	for coin: Node in coins:
		if (
			is_instance_valid(coin)
			and not coin.is_queued_for_deletion()
			and coin.has_method("collect")
			and coin.call("collect")
		):
			collected_count += 1
	return collected_count


func _damage_all_normal_enemies() -> int:
	var damaged_count := 0
	var normal_enemies := get_tree().get_nodes_in_group(&"normal_enemies")
	for enemy: Node in normal_enemies:
		if (
			not is_instance_valid(enemy)
			or enemy.is_queued_for_deletion()
			or not enemy.has_method("take_damage")
			or (enemy.has_method("is_alive") and not enemy.call("is_alive"))
		):
			continue
		if enemy.call("take_damage", BOMB_PICKUP_DAMAGE):
			damaged_count += 1
	return damaged_count


func _show_next_upgrade_choice() -> void:
	if _is_run_ended() or _choice_open:
		return
	if _pending_level_ups.is_empty():
		_current_combat_offer = &""
		get_tree().paused = false
		return
	_current_combat_offer = _choose_combat_offer()
	var offer_metadata := get_ability_offer_metadata(_current_combat_offer)
	if offer_metadata.is_empty():
		push_error("GameController could not create an eligible combat ability offer.")
		return
	_choice_open = true
	get_tree().paused = true
	_upgrade_choice_ui.call(
		"show_choices",
		_pending_level_ups[0],
		offer_metadata["title"],
		offer_metadata["description"]
	)


func _is_run_ended() -> bool:
	return _defeated or _victorious


func _choose_combat_offer() -> StringName:
	var eligible := get_eligible_combat_offers()
	while not _forced_combat_offers.is_empty():
		var forced_offer: StringName = _forced_combat_offers.pop_front()
		if eligible.has(forced_offer):
			return forced_offer
	if eligible.is_empty():
		return &""
	return eligible[_ability_rng.randi_range(0, eligible.size() - 1)]


func _apply_combat_ability(ability_id: StringName) -> void:
	if not ABILITY_IDS.has(ability_id):
		return
	var current_rank := get_ability_rank(ability_id)
	if current_rank >= MAXIMUM_ABILITY_RANK:
		return
	var next_rank := current_rank + 1
	_ability_ranks[ability_id] = next_rank
	_apply_combat_rank_effects()
	combat_ability_rank_changed.emit(ability_id, next_rank)


func _apply_combat_rank_effects() -> void:
	if is_instance_valid(_auto_weapon):
		_auto_weapon.call(
			"set_combat_ranks",
			get_ability_rank(ABILITY_MULTISHOT),
			get_ability_rank(ABILITY_PIERCING)
		)
	if is_instance_valid(_nova_ability):
		_nova_ability.call("set_rank", get_ability_rank(ABILITY_NOVA))
