extends Node2D

@export var xp_coin_scene: PackedScene
@export_range(1, 500, 1) var maximum_active_xp_coins: int = 40

var _player: Node
var _health_label: Label
var _level_label: Label
var _xp_label: Label
var _xp_bar: ProgressBar
var _defeat_overlay: Control
var _enemy_spawner: Node
var _xp_coin_container: Node
var _progression: Node
var _defeated: bool = false


func _ready() -> void:
	_player = get_node_or_null("World/Player")
	_health_label = get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Health/Value") as Label
	_level_label = get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Level/Value") as Label
	_xp_label = get_node_or_null("HUD/Layout/TopBar/Margin/Stats/XP/Heading/Value") as Label
	_xp_bar = get_node_or_null("HUD/Layout/TopBar/Margin/Stats/XP/Bar") as ProgressBar
	_defeat_overlay = get_node_or_null("HUD/DefeatOverlay") as Control
	_enemy_spawner = get_node_or_null("World/EnemySpawner")
	_xp_coin_container = get_node_or_null("World/XPCoins")
	_progression = get_node_or_null("RunProgression")
	var restart_button := get_node_or_null("HUD/DefeatOverlay/Center/Panel/Margin/Content/RestartButton") as Button
	if (
		_player == null
		or _health_label == null
		or _level_label == null
		or _xp_label == null
		or _xp_bar == null
		or _defeat_overlay == null
		or _enemy_spawner == null
		or _xp_coin_container == null
		or _progression == null
		or restart_button == null
	):
		push_error("GameController requires the player, progression, world containers, HUD, and defeat controls.")
		return
	_player.health_changed.connect(_on_player_health_changed)
	_player.died.connect(_on_player_died)
	_enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	_progression.progress_changed.connect(_on_progress_changed)
	restart_button.pressed.connect(restart_run)
	_defeat_overlay.hide()
	_on_player_health_changed(_player.current_health, _player.maximum_health)
	_on_progress_changed(
		_progression.current_level,
		_progression.current_xp,
		_progression.get_required_xp(),
		_progression.completed
	)


func _exit_tree() -> void:
	if _defeated and get_tree() != null:
		get_tree().paused = false


func restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func is_defeated() -> bool:
	return _defeated


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


func _on_player_health_changed(current_health: int, maximum_health: int) -> void:
	if is_instance_valid(_health_label):
		_health_label.text = "%d / %d" % [current_health, maximum_health]


func _on_player_died() -> void:
	if _defeated:
		return
	_defeated = true
	_defeat_overlay.show()
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
