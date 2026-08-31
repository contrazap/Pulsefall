extends Area2D

@export_range(1.0, 3000.0, 1.0) var movement_speed: float = 720.0
@export_range(1, 10000, 1) var damage: int = 15
@export_range(0.05, 30.0, 0.05) var maximum_lifetime: float = 2.0
@export_range(1, 100, 1) var hit_allowance: int = 1

var direction: Vector2 = Vector2.RIGHT
var remaining_hits: int
var remaining_lifetime: float
var _hit_instance_ids: Dictionary[int, bool] = {}


func _ready() -> void:
	remaining_hits = hit_allowance
	remaining_lifetime = maximum_lifetime
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * movement_speed * delta
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		queue_free()


func configure(aim_direction: Vector2) -> void:
	direction = aim_direction.normalized() if not aim_direction.is_zero_approx() else Vector2.RIGHT
	rotation = direction.angle()


func apply_hit(body: Node) -> bool:
	if remaining_hits <= 0 or not is_instance_valid(body) or not body.has_method("take_damage"):
		return false
	var instance_id := body.get_instance_id()
	if _hit_instance_ids.has(instance_id):
		return false
	_hit_instance_ids[instance_id] = true
	body.call("take_damage", damage)
	remaining_hits -= 1
	if remaining_hits <= 0:
		queue_free()
	return true


func _on_body_entered(body: Node) -> void:
	apply_hit(body)
