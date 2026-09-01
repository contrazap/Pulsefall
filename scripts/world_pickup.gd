extends Node2D

signal collected(pickup_type: StringName)

const TYPE_HEALTH: StringName = &"health"
const TYPE_MAGNET: StringName = &"magnet"
const TYPE_BOMB: StringName = &"bomb"
const VALID_TYPES: Array[StringName] = [TYPE_HEALTH, TYPE_MAGNET, TYPE_BOMB]

@export var pickup_type: StringName = TYPE_HEALTH
@export_range(1.0, 256.0, 1.0) var collection_radius: float = 42.0

var target: Node2D
var _collected: bool = false


func _physics_process(_delta: float) -> void:
	if _collected or not _has_living_target():
		return
	if global_position.distance_to(target.global_position) <= collection_radius:
		collect()


func configure(next_target: Node2D, next_type: StringName, next_collection_radius: float) -> void:
	target = next_target
	pickup_type = next_type if VALID_TYPES.has(next_type) else TYPE_HEALTH
	collection_radius = maxf(next_collection_radius, 1.0)
	_collected = false
	queue_redraw()


func collect() -> bool:
	if _collected or not _has_living_target():
		return false
	_collected = true
	collected.emit(pickup_type)
	queue_free()
	return true


func is_collected() -> bool:
	return _collected


func _has_living_target() -> bool:
	if not is_instance_valid(target):
		return false
	if target.has_method("is_alive") and not target.call("is_alive"):
		return false
	return true


func _draw() -> void:
	match pickup_type:
		TYPE_HEALTH:
			draw_circle(Vector2.ZERO, 19.0, Color(1.0, 0.18, 0.48, 0.2))
			draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.2, 0.48, 0.92))
			draw_rect(Rect2(-3.0, -10.0, 6.0, 20.0), Color.WHITE)
			draw_rect(Rect2(-10.0, -3.0, 20.0, 6.0), Color.WHITE)
		TYPE_MAGNET:
			draw_circle(Vector2.ZERO, 20.0, Color(0.65, 0.3, 1.0, 0.18))
			draw_arc(Vector2.ZERO, 13.0, 0.0, PI, 20, Color(0.72, 0.38, 1.0), 7.0)
			draw_rect(Rect2(-16.0, -4.0, 7.0, 13.0), Color(0.94, 0.84, 1.0))
			draw_rect(Rect2(9.0, -4.0, 7.0, 13.0), Color(0.94, 0.84, 1.0))
		TYPE_BOMB:
			var diamond := PackedVector2Array([
				Vector2(0.0, -17.0),
				Vector2(17.0, 0.0),
				Vector2(0.0, 17.0),
				Vector2(-17.0, 0.0),
			])
			draw_colored_polygon(diamond, Color(1.0, 0.55, 0.08, 0.92))
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(1.0, 0.91, 0.58), 3.0)
			for spoke_index: int in range(4):
				var direction := Vector2.UP.rotated(float(spoke_index) * TAU / 4.0)
				draw_line(direction * 20.0, direction * 27.0, Color(1.0, 0.72, 0.18), 2.0)
