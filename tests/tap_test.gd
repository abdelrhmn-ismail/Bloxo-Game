extends Node
## Regression test: a quick TAP on a tray piece (no drag) must never place
## it on the board, wherever in the piece's touch area the tap lands.
##   godot --headless --path . res://tests/tap_test.tscn

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
	var backup := SaveData.saved_game.duplicate(true)
	var game := GameScreen.new()
	tree.root.add_child(game)
	await tree.process_frame
	var placed := 0
	var taps := 0
	for slot in game.state.tray.size():
		var rect := Rect2(game.tray_centers[slot] - game.tray_slot_size * 0.5, game.tray_slot_size)
		for fy in [0.02, 0.25, 0.5, 0.75, 0.98]:
			for fx in [0.1, 0.5, 0.9]:
				if game.state.tray[slot] == null:
					continue
				var pos: Vector2 = rect.position + rect.size * Vector2(fx, fy)
				var filled_before := game.state.board.filled_count()
				_touch(game, pos, true)
				_touch(game, pos, false)
				taps += 1
				await tree.process_frame
				if game.state.board.filled_count() != filled_before:
					placed += 1
					print("tap at %s (slot %d) PLACED the piece" % [pos, slot])
					game.state.new_game()
	print("tap test: %d taps, %d accidental placements -> %s" % [taps, placed, "OK" if placed == 0 else "FAIL"])

	# A real drag (press, move in steps, release over the board) must place it.
	var drags_ok := 0
	var drags := 0
	for n in 6:
		if game.state.game_over:
			game.state.new_game()
		var slot := -1
		for i in game.state.tray.size():
			if game.state.tray[i] != null:
				slot = i
				break
		if slot == -1:
			break
		var shape: Array = game.state.tray[slot]["shape"]
		var target := Vector2i(-1, -1)
		for row in Board.SIZE:
			for col in Board.SIZE:
				if target.x < 0 and game.state.board.can_place(shape, col, row):
					target = Vector2i(col, row)
		var b := Vector2(Shapes.bounds(shape))
		var top_left: Vector2 = game.board_origin + Vector2(target) * game.cell_size
		var finger: Vector2 = top_left + Vector2(b.x * 0.5 * game.cell_size, b.y * game.cell_size + game.cell_size * GameScreen.LIFT_CELLS)
		var start: Vector2 = game.tray_centers[slot]
		var before := game.state.board.filled_count()
		_touch(game, start, true)
		for k in range(1, 11):
			var e := InputEventScreenDrag.new()
			e.index = 0
			e.position = start.lerp(finger, k / 10.0)
			game._unhandled_input(e)
		_touch(game, finger, false)
		await tree.process_frame
		drags += 1
		if game.state.board.filled_count() != before:
			drags_ok += 1
	print("drag test: %d/%d drags placed the piece -> %s" % [drags_ok, drags, "OK" if drags_ok == drags else "FAIL"])

	SaveData.saved_game = backup
	SaveData.write()
	Audio.stop_all()
	tree.quit(0 if placed == 0 and drags_ok == drags else 1)


func _touch(game: GameScreen, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = pressed
	game._unhandled_input(e)
