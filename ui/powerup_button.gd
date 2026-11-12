class_name PowerupButton
extends Button
## In-game power-up button: icon + count badge. Dimmed when you have none,
## highlighted while it is waiting for you to tap the board.

var kind := ""
var count := 0
var active := false


func _init(power_kind: String = "") -> void:
	kind = power_kind
	UIKit.style_button(self, Vector2(200, 130), 40, Palette.button)
	text = ""


func set_state(new_count: int, is_active: bool) -> void:
	count = new_count
	active = is_active
	disabled = count <= 0 and not active
	modulate.a = 1.0 if (count > 0 or active) else 0.45
	queue_redraw()


func _draw() -> void:
	var icon_color := Palette.accent if active else Color.WHITE
	PowerupIcon.draw_icon(self, kind, Vector2(size.x * 0.42, size.y * 0.5), size.y * 0.62, icon_color)
	# count badge
	var badge := Vector2(size.x - 34, 32)
	draw_circle(badge, 26, Palette.accent)
	draw_arc(badge, 26, 0, TAU, 24, Palette.outline, 3, true)
	var font := get_theme_default_font()
	draw_string(font, badge + Vector2(-26, 11), str(count), HORIZONTAL_ALIGNMENT_CENTER, 52, 30, Palette.outline)
	if active:
		draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Palette.accent, false, 4)
