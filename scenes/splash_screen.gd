class_name SplashScreen
extends Control
## Short animated logo when the app starts. Tap to skip.

signal finished

const DURATION := 1.8

var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 40)
	center.add_child(box)

	var logo := NeonLogo.new(32.0)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(logo)
	logo.play_intro(0.9)

	var tagline := UIKit.label("BLOCK PUZZLE", 44, Palette.text_dim)
	tagline.modulate.a = 0.0
	box.add_child(tagline)

	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(tagline, "modulate:a", 1.0, 0.4)
	tw.tween_interval(DURATION - 1.2)
	tw.tween_callback(_finish)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
