class_name PopupText
extends Label
## Floating text like "Great!" or "+120": pops in, floats up, fades out.


func show_text(value: String, center: Vector2, font_size: int, color: Color, delay: float = 0.0) -> void:
	UIKit.style_label(self, font_size, color)
	text = value
	size = Vector2(1000, font_size * 1.6)
	position = center - size * 0.5
	pivot_offset = size * 0.5
	scale = Vector2(0.2, 0.2)
	modulate.a = 0.0

	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "modulate:a", 1.0, 0.05)
	tw.parallel().tween_property(self, "scale", Vector2.ONE * 1.15, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(0.45)
	tw.tween_property(self, "position:y", position.y - 120.0, 0.4)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
