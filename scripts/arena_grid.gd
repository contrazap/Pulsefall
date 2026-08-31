extends Node2D

@export_range(16.0, 256.0, 1.0) var grid_spacing: float = 64.0
@export_range(0.0, 512.0, 1.0) var safety_margin: float = 128.0
@export_range(2, 16, 1) var major_line_interval: int = 4
@export var target_path: NodePath
@export var background_color: Color = Color("030409")
@export var minor_line_color: Color = Color(0.05, 0.28, 0.38, 0.5)
@export var major_line_color: Color = Color(0.08, 0.55, 0.68, 0.72)

var _target: Node2D
var _draw_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_refresh_grid(true)


func _process(_delta: float) -> void:
	_refresh_grid(false)


func calculate_grid_origin(target_position: Vector2) -> Vector2:
	return target_position.snapped(Vector2.ONE * grid_spacing)


func get_draw_line_count(viewport_size: Vector2) -> int:
	var covered_size := viewport_size + Vector2.ONE * safety_margin * 2.0
	var columns := ceili(covered_size.x / grid_spacing) + 1
	var rows := ceili(covered_size.y / grid_spacing) + 1
	return columns + rows


func _refresh_grid(force_redraw: bool) -> void:
	var next_position := Vector2.ZERO
	if is_instance_valid(_target):
		next_position = calculate_grid_origin(_target.global_position)

	var next_draw_size := get_viewport_rect().size + Vector2.ONE * safety_margin * 2.0
	if force_redraw or next_position != global_position or next_draw_size != _draw_size:
		global_position = next_position
		_draw_size = next_draw_size
		queue_redraw()


func _draw() -> void:
	var half_size := _draw_size * 0.5
	draw_rect(Rect2(-half_size, _draw_size), background_color)

	var half_columns := ceili(half_size.x / grid_spacing)
	var half_rows := ceili(half_size.y / grid_spacing)
	var origin_column := roundi(global_position.x / grid_spacing)
	var origin_row := roundi(global_position.y / grid_spacing)

	for column_offset: int in range(-half_columns, half_columns + 1):
		var column_index := origin_column + column_offset
		var color := major_line_color if posmod(column_index, major_line_interval) == 0 else minor_line_color
		var width := 2.0 if posmod(column_index, major_line_interval) == 0 else 1.0
		var x := column_offset * grid_spacing
		draw_line(Vector2(x, -half_size.y), Vector2(x, half_size.y), color, width)

	for row_offset: int in range(-half_rows, half_rows + 1):
		var row_index := origin_row + row_offset
		var color := major_line_color if posmod(row_index, major_line_interval) == 0 else minor_line_color
		var width := 2.0 if posmod(row_index, major_line_interval) == 0 else 1.0
		var y := row_offset * grid_spacing
		draw_line(Vector2(-half_size.x, y), Vector2(half_size.x, y), color, width)


func _on_viewport_size_changed() -> void:
	_refresh_grid(true)
