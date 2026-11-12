class_name IconButton
extends Button
## A square themed button showing a drawn icon (e.g. the settings gear).
## Icons come from PowerupIcon.draw_icon().

var icon_kind := ""


func _init(kind: String = "gear", side: float = 120.0, color: Color = Color.TRANSPARENT) -> void:
	icon_kind = kind
	UIKit.style_button(self, Vector2(side, side), 40, color)
	text = ""


func _draw() -> void:
	PowerupIcon.draw_icon(self, icon_kind, size * 0.5, size.y * 0.62, Color.WHITE)
