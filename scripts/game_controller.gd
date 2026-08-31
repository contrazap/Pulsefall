extends Node2D

var _player: Node
var _health_label: Label
var _defeat_overlay: Control
var _defeated: bool = false


func _ready() -> void:
	_player = get_node_or_null("World/Player")
	_health_label = get_node_or_null("HUD/Layout/TopBar/Margin/Stats/Health/Value") as Label
	_defeat_overlay = get_node_or_null("HUD/DefeatOverlay") as Control
	var restart_button := get_node_or_null("HUD/DefeatOverlay/Center/Panel/Margin/Content/RestartButton") as Button
	if _player == null or _health_label == null or _defeat_overlay == null or restart_button == null:
		push_error("GameController requires the player, health HUD, defeat overlay, and restart button.")
		return
	_player.health_changed.connect(_on_player_health_changed)
	_player.died.connect(_on_player_died)
	restart_button.pressed.connect(restart_run)
	_defeat_overlay.hide()
	_on_player_health_changed(_player.current_health, _player.maximum_health)


func _exit_tree() -> void:
	if _defeated and get_tree() != null:
		get_tree().paused = false


func restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func is_defeated() -> bool:
	return _defeated


func _on_player_health_changed(current_health: int, maximum_health: int) -> void:
	if is_instance_valid(_health_label):
		_health_label.text = "%d / %d" % [current_health, maximum_health]


func _on_player_died() -> void:
	if _defeated:
		return
	_defeated = true
	_defeat_overlay.show()
	get_tree().paused = true
