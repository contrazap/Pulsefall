extends Node2D

@export_range(0, 2, 1) var variant: int = 0
@export var tint: Color = Color(0.18, 0.72, 0.92, 0.34)


func configure(next_variant: int, next_rotation: float, next_scale: float) -> void:
	variant = posmod(next_variant, 3)
	rotation = next_rotation
	scale = Vector2.ONE * next_scale
	queue_redraw()


func _draw() -> void:
	match variant:
		0:
			draw_circle(Vector2.ZERO, 15.0, Color(tint, 0.08))
			draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 24, tint, 2.0)
			draw_circle(Vector2.ZERO, 3.0, tint)
		1:
			var diamond := PackedVector2Array([
				Vector2(0.0, -17.0),
				Vector2(13.0, 0.0),
				Vector2(0.0, 17.0),
				Vector2(-13.0, 0.0),
			])
			draw_colored_polygon(diamond, Color(tint, 0.07))
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), tint, 2.0)
		2:
			for spoke_index: int in range(3):
				var direction := Vector2.UP.rotated(float(spoke_index) * TAU / 3.0)
				draw_line(direction * 5.0, direction * 20.0, tint, 2.0)
			draw_circle(Vector2.ZERO, 5.0, Color(tint, 0.55))
