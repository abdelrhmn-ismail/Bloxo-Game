class_name GradientBackground
extends Node2D
## Vertical color gradient behind everything (colors from Palette).


func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)


func _draw() -> void:
	var s := get_viewport_rect().size
	var top := Palette.background_top
	var bottom := Palette.background_bottom
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)]),
		PackedColorArray([top, top, bottom, bottom]))
