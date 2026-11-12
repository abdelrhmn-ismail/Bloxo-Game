extends Node
## Clicks the menu THEME button with real (simulated) mouse events, each
## delivered twice, and checks every click advances exactly one theme.
##   godot --path . res://tests/click_theme_test.tscn

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
	var backup := SaveData.theme
	Palette.set_theme("neon")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	main.show_menu()
	for i in 5:
		await tree.create_timer(0.3).timeout
		var btn := _find_theme_button(main.current)
		if btn == null:
			printerr("no theme button")
			break
		var pos: Vector2 = btn.get_viewport().get_final_transform() * (btn.get_global_transform_with_canvas() * (btn.size * 0.5))
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = pos
		down.global_position = pos
		var up := down.duplicate()
		up.pressed = false
		# Deliver the same click twice, like the editor-embedded game can.
		for repeat in 2:
			Input.parse_input_event(down)
			await tree.process_frame
			Input.parse_input_event(up)
			await tree.process_frame
		await tree.process_frame
		var expected: String = Themes.ORDER[(i + 1) % Themes.ORDER.size()]
		print("click %d -> %s (expected %s)%s" % [i + 1, Palette.theme_id, expected,
			"" if Palette.theme_id == expected else "  FAIL"])
	Palette.set_theme(backup)
	tree.quit()


func _find_theme_button(node: Node) -> Button:
	if node is Button and node.text.begins_with("THEME"):
		return node
	for c in node.get_children():
		var b := _find_theme_button(c)
		if b:
			return b
	return null
