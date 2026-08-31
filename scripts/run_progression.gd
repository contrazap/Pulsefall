extends Node

signal progress_changed(level: int, current_xp: int, required_xp: int, completed: bool)
signal level_up(level: int)

const XP_THRESHOLDS: Array[int] = [5, 9, 14, 20, 28]

var current_level: int = 1
var current_xp: int = 0
var completed: bool = false
var _threshold_index: int = 0


func add_xp(amount: int) -> int:
	if amount <= 0 or completed:
		return 0

	current_xp += amount
	var levels_gained := 0
	while _threshold_index < XP_THRESHOLDS.size():
		var required_xp := XP_THRESHOLDS[_threshold_index]
		if current_xp < required_xp:
			break
		current_xp -= required_xp
		_threshold_index += 1
		current_level += 1
		levels_gained += 1
		level_up.emit(current_level)

	if _threshold_index >= XP_THRESHOLDS.size():
		completed = true
		current_xp = 0

	progress_changed.emit(current_level, current_xp, get_required_xp(), completed)
	return levels_gained


func reset_progression() -> void:
	current_level = 1
	current_xp = 0
	completed = false
	_threshold_index = 0
	progress_changed.emit(current_level, current_xp, get_required_xp(), completed)


func get_required_xp() -> int:
	if completed or _threshold_index >= XP_THRESHOLDS.size():
		return 0
	return XP_THRESHOLDS[_threshold_index]


func get_thresholds() -> Array[int]:
	return XP_THRESHOLDS.duplicate()
