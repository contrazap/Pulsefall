extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal died

const VITALITY_HEALTH_INCREASE: int = 20
const HASTE_SPEED_MULTIPLIER: float = 1.12

@export_range(1.0, 1000.0, 1.0) var movement_speed: float = 320.0
@export_range(1, 10000, 1) var maximum_health: int = 100
@export_range(0.05, 10.0, 0.05) var invulnerability_duration: float = 0.8

var current_health: int
var _invulnerability_remaining: float = 0.0
var _is_dead: bool = false


func _ready() -> void:
	current_health = maximum_health
	health_changed.emit(current_health, maximum_health)


func _physics_process(delta: float) -> void:
	_invulnerability_remaining = maxf(_invulnerability_remaining - delta, 0.0)
	modulate = Color.WHITE if _invulnerability_remaining <= 0.0 else Color(1.0, 0.45, 0.65, 1.0)
	if _is_dead:
		velocity = Vector2.ZERO
		return
	velocity = calculate_velocity(Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_up",
		&"move_down"
	))
	move_and_slide()


func calculate_velocity(input_direction: Vector2) -> Vector2:
	return input_direction.limit_length(1.0) * movement_speed


func apply_vitality() -> void:
	maximum_health += VITALITY_HEALTH_INCREASE
	current_health = mini(current_health + VITALITY_HEALTH_INCREASE, maximum_health)
	health_changed.emit(current_health, maximum_health)


func apply_haste() -> void:
	movement_speed *= HASTE_SPEED_MULTIPLIER


func heal(amount: int) -> int:
	if amount <= 0 or _is_dead:
		return 0
	var previous_health := current_health
	current_health = mini(current_health + amount, maximum_health)
	var restored_health := current_health - previous_health
	if restored_health > 0:
		health_changed.emit(current_health, maximum_health)
	return restored_health


func take_damage(amount: int) -> bool:
	if amount <= 0 or _is_dead or _invulnerability_remaining > 0.0:
		return false
	current_health = maxi(current_health - amount, 0)
	_invulnerability_remaining = invulnerability_duration
	health_changed.emit(current_health, maximum_health)
	if current_health == 0:
		_is_dead = true
		velocity = Vector2.ZERO
		died.emit()
	return true


func is_alive() -> bool:
	return not _is_dead


func is_invulnerable() -> bool:
	return _invulnerability_remaining > 0.0


func clear_invulnerability() -> void:
	_invulnerability_remaining = 0.0
	modulate = Color.WHITE
