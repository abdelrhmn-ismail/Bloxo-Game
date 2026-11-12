class_name PowerupIcon
extends Control
## A power-up icon (drawn in code) with an optional count or "+N" label.
## draw_icon() is also used by PowerupButton.

var kind := ""
var label_text := ""


func _init(power_kind: String = "", text: String = "", side: float = 110.0) -> void:
	kind = power_kind
	label_text = text
	custom_minimum_size = Vector2(side, side * 1.25)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var side := size.x
	draw_icon(self, kind, Vector2(side * 0.5, side * 0.5), side * 0.8, Palette.text)
	if label_text != "":
		var font := get_theme_default_font()
		var fs := int(side * 0.3)
		draw_string_outline(font, Vector2(0, side * 1.18), label_text, HORIZONTAL_ALIGNMENT_CENTER, side, fs, 6, Palette.outline)
		draw_string(font, Vector2(0, side * 1.18), label_text, HORIZONTAL_ALIGNMENT_CENTER, side, fs, Palette.accent)


## Draws the icon for `kind` centred at `c`, roughly `s` wide.
static func draw_icon(ci: CanvasItem, power_kind: String, c: Vector2, s: float, color: Color) -> void:
	var w := maxf(2.0, s * 0.09)
	match power_kind:
		"hammer":
			# handle
			ci.draw_line(c + Vector2(-0.36, 0.38) * s, c + Vector2(0.06, -0.04) * s, color, w * 1.2, true)
			# big head (a rotated block across the handle's end)
			var head := PackedVector2Array()
			for p in [Vector2(-0.34, -0.15), Vector2(0.34, -0.15), Vector2(0.34, 0.15), Vector2(-0.34, 0.15)]:
				head.append(c + (p.rotated(PI / 4) + Vector2(0.14, -0.14)) * s)
			ci.draw_colored_polygon(head, color)
		"bomb":
			var body := c + Vector2(-0.06, 0.08) * s
			ci.draw_circle(body, s * 0.3, color)
			ci.draw_circle(body + Vector2(-0.1, -0.1) * s, s * 0.07, Color(1, 1, 1, 0.5))
			ci.draw_line(body + Vector2(0.18, -0.22) * s, c + Vector2(0.3, -0.36) * s, color, w, true)
			_star(ci, c + Vector2(0.34, -0.4) * s, s * 0.12, Palette.accent)
		"shuffle":
			var a1 := c + Vector2(-0.38, -0.22) * s
			var b1 := c + Vector2(0.36, 0.24) * s
			var a2 := c + Vector2(-0.38, 0.24) * s
			var b2 := c + Vector2(0.36, -0.22) * s
			ci.draw_line(a1, b1, color, w, true)
			ci.draw_line(a2, b2, color, w, true)
			_arrow_head(ci, b1, (b1 - a1).normalized(), s * 0.16, color)
			_arrow_head(ci, b2, (b2 - a2).normalized(), s * 0.16, color)
		"undo":
			var center := c + Vector2(0.04, 0.06) * s
			var r := s * 0.3
			ci.draw_arc(center, r, PI * 1.05, PI * 2.25, 24, color, w, true)
			var tip := center + Vector2.from_angle(PI * 1.05) * r
			_arrow_head(ci, tip + Vector2(0, 0.02) * s, Vector2(-0.2, 1).normalized(), s * 0.17, color)
		"gear":
			for i in 8:
				var tooth := PackedVector2Array()
				for p in [Vector2(-0.07, -0.44), Vector2(0.07, -0.44), Vector2(0.09, -0.25), Vector2(-0.09, -0.25)]:
					tooth.append(c + p.rotated(i * TAU / 8.0) * s)
				ci.draw_colored_polygon(tooth, color)
			ci.draw_circle(c, s * 0.3, color)
			ci.draw_circle(c, s * 0.12, Color(0, 0, 0, 0.45))
		_:
			ci.draw_circle(c, s * 0.3, color)


static func _arrow_head(ci: CanvasItem, tip: Vector2, dir: Vector2, length: float, color: Color) -> void:
	var side := dir.orthogonal() * length * 0.6
	var back := tip - dir * length
	ci.draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), color)


static func _star(ci: CanvasItem, p: Vector2, r: float, color: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.3, 0), p + Vector2(0, r), p + Vector2(-r * 0.3, 0)]), color)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-r, 0), p + Vector2(0, -r * 0.3), p + Vector2(r, 0), p + Vector2(0, r * 0.3)]), color)
