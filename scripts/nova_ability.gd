extends Node2D

signal pulse_emitted(rank: int, damaged_enemy_count: int)

@export_range(1.0, 1000.0, 1.0) var pulse_radius: float = 190.0
@export_range(1, 10000, 1) var rank_one_damage: int = 18
@export_range(1, 10000, 1) var rank_two_damage: int = 32
@export_range(0.1, 60.0, 0.1) var rank_one_interval: float = 5.0
@export_range(0.1, 60.0, 0.1) var rank_two_interval: float = 3.5
@export_range(0.05, 2.0, 0.05) var visual_duration: float = 0.35
@export var target_group: StringName = &"combat_targets"

var rank: int = 0
var _pulse_timer: Timer
var _visual_remaining: float = 0.0
var _pulse_count: int = 0


func _ready() -> void:
	_pulse_timer = get_node_or_null("PulseTimer") as Timer
	if _pulse_timer == null:
		push_error("NovaAbility requires a PulseTimer child.")
		return
	_pulse_timer.one_shot = false
	_pulse_timer.timeout.connect(emit_pulse)
	set_process(false)
	set_rank(rank)


func _process(delta: float) -> void:
	_visual_remaining = maxf(_visual_remaining - delta, 0.0)
	queue_redraw()
	if _visual_remaining <= 0.0:
		set_process(false)


func _draw() -> void:
	if _visual_remaining <= 0.0 or visual_duration <= 0.0:
		return
	var progress := 1.0 - _visual_remaining / visual_duration
	var radius := lerpf(24.0, pulse_radius, progress)
	var alpha := 0.85 * (1.0 - progress)
	draw_circle(Vector2.ZERO, radius, Color(0.18, 0.95, 1.0, alpha * 0.12))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.35, 0.98, 1.0, alpha), 5.0)


func set_rank(next_rank: int) -> void:
	rank = clampi(next_rank, 0, 2)
	if _pulse_timer == null:
		return
	if rank == 0:
		_pulse_timer.stop()
		_visual_remaining = 0.0
		set_process(false)
		queue_redraw()
		return
	_pulse_timer.wait_time = get_interval()
	_pulse_timer.start()


func get_interval() -> float:
	return rank_two_interval if rank >= 2 else rank_one_interval


func get_damage() -> int:
	if rank <= 0:
		return 0
	return rank_two_damage if rank >= 2 else rank_one_damage


func get_pulse_count() -> int:
	return _pulse_count


func get_time_left() -> float:
	return _pulse_timer.time_left if _pulse_timer != null else 0.0


func emit_pulse() -> int:
	if rank <= 0 or get_tree() == null:
		return 0
	var damaged_enemy_count := 0
	for candidate: Node in get_tree().get_nodes_in_group(target_group):
		if not candidate is Node2D or not is_instance_valid(candidate):
			continue
		if candidate.has_method("is_alive") and not candidate.call("is_alive"):
			continue
		var enemy := candidate as Node2D
		if global_position.distance_to(enemy.global_position) > pulse_radius:
			continue
		if enemy.has_method("take_damage") and enemy.call("take_damage", get_damage()):
			damaged_enemy_count += 1
	_pulse_count += 1
	_visual_remaining = visual_duration
	set_process(true)
	queue_redraw()
	pulse_emitted.emit(rank, damaged_enemy_count)
	return damaged_enemy_count
