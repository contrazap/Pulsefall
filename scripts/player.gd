extends CharacterBody2D

@export_range(1.0, 1000.0, 1.0) var movement_speed: float = 320.0


func _physics_process(_delta: float) -> void:
	velocity = calculate_velocity(Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_up",
		&"move_down"
	))
	move_and_slide()


func calculate_velocity(input_direction: Vector2) -> Vector2:
	return input_direction.limit_length(1.0) * movement_speed
