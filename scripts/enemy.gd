extends CharacterBody2D

@export_range(1.0, 1000.0, 1.0) var movement_speed: float = 135.0

var target: Node2D


func _physics_process(_delta: float) -> void:
	refresh_chase_velocity()
	move_and_slide()


func set_target(next_target: Node2D) -> void:
	target = next_target


func refresh_chase_velocity() -> void:
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	velocity = calculate_chase_velocity(target.global_position)


func calculate_chase_velocity(target_position: Vector2) -> Vector2:
	var direction := global_position.direction_to(target_position)
	return direction * movement_speed
