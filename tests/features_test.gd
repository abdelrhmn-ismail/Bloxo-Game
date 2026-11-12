extends Node
## Tests the tutorial, idle hints and per-theme music through the real
## GameScreen / Audio code.
##   godot --headless --path . res://tests/features_test.tscn

var errors := 0
var tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	tree = get_tree()
	var backup := {
		"saved_game": SaveData.saved_game.duplicate(true), "tutorial_done": SaveData.tutorial_done,
		"hints_on": SaveData.hints_on, "music_on": SaveData.music_on, "theme": SaveData.theme,
	}
	SaveData.saved_game = {}

	await _test_tutorial()
	await _test_tutorial_skip()
	await _test_hint()
	await _test_music()

	for key in backup:
		SaveData.set(key, backup[key])
	Palette.apply(backup["theme"])
	SaveData.write()
	Audio.stop_all()
	print("features test: %s" % ("OK" if errors == 0 else "%d FAILED" % errors))
	tree.quit(1 if errors > 0 else 0)


func _test_tutorial() -> void:
	SaveData.tutorial_done = false
	var game := GameScreen.new()
	game.tutorial = true
	tree.root.add_child(game)
	await tree.process_frame
	_check(game.tutorial_step == 1, "tutorial starts at step 1")
	_check(game.tutorial_label.visible and not game.score_label.visible, "tutorial HUD shown")
	_check(game.state.tray[1] != null and game.guide_slot == 1, "step 1 has a guided piece")

	_drag(game, 1, game.guide_cell)
	await tree.create_timer(1.0).timeout
	_check(game.tutorial_step == 2, "after placing, step 2 (got %d)" % game.tutorial_step)
	_check(game.state.board.filled_count() == 5, "step 2 board has a row with a gap")

	# Wrong move: place it somewhere that clears nothing.
	_drag(game, 1, Vector2i(0, 0))
	await tree.create_timer(1.0).timeout
	_check(game.tutorial_step == 2 and game.tutorial_text_key == "TUT_TRY_AGAIN", "wrong move -> try again")

	# Right move: fill the gap → line clears → end panel.
	_drag(game, 1, game.guide_cell)
	await tree.create_timer(1.2).timeout
	_check(game.overlay != null, "end-of-tutorial panel shown")

	game._finish_tutorial()
	await tree.process_frame
	_check(game.tutorial_step == 0 and SaveData.tutorial_done, "tutorial finished and remembered")
	_check(game.score_label.visible and not game.skip_button.visible, "normal HUD back")
	_check(game.state.score == 0 and game.state.tray.all(func(p): return p != null), "real game starts fresh")
	game.queue_free()
	await tree.process_frame
	print("tutorial: ok")


func _test_tutorial_skip() -> void:
	SaveData.tutorial_done = false
	var game := GameScreen.new()
	game.tutorial = true
	tree.root.add_child(game)
	await tree.process_frame
	game.skip_button.pressed.emit()
	await tree.create_timer(1.0).timeout # a pending step change must not come back
	_check(game.tutorial_step == 0 and SaveData.tutorial_done, "skip ends the tutorial")
	_check(game.state.tray.all(func(p): return p != null), "skip leaves a normal game")
	game.queue_free()
	await tree.process_frame
	print("tutorial skip: ok")


func _test_hint() -> void:
	SaveData.hints_on = true
	var game := GameScreen.new()
	tree.root.add_child(game)
	await tree.process_frame
	game._update_hint(GameScreen.HINT_DELAY - 1.0)
	_check(not game.hint_active, "no hint before the delay")
	game._update_hint(2.0)
	_check(game.hint_active, "hint after the delay")
	if game.hint_active:
		var shape: Array = game.state.tray[game.guide_slot]["shape"]
		_check(game.state.board.can_place(shape, game.guide_cell.x, game.guide_cell.y), "hint is a legal move")
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = true
	e.position = Vector2(-500, -500) # touch outside the tray
	game._unhandled_input(e)
	_check(not game.hint_active, "touching hides the hint")

	SaveData.hints_on = false
	game._update_hint(GameScreen.HINT_DELAY * 3)
	_check(not game.hint_active, "no hint when hints are off")
	game.queue_free()
	await tree.process_frame
	print("hint: ok")


func _test_music() -> void:
	SaveData.music_on = true
	for id in Themes.ORDER:
		Palette.apply(id) # Audio listens to theme changes
		await tree.create_timer(1.0).timeout # cross-fade
		var playing := Audio.current_music()
		_check(playing == "music_" + id, "theme %s plays its music (got '%s')" % [id, playing])
	SaveData.music_on = false
	Audio.refresh_music()
	_check(Audio.current_music() == "", "music stops when turned off")
	print("music: ok")


## Drags tray[slot] so its top-left lands on `cell`, like a finger would.
func _drag(game: GameScreen, slot: int, cell: Vector2i) -> void:
	var shape: Array = game.state.tray[slot]["shape"]
	var b := Vector2(Shapes.bounds(shape))
	var finger: Vector2 = game.board_origin + Vector2(cell) * game.cell_size \
		+ Vector2(b.x * 0.5, b.y + GameScreen.LIFT_CELLS) * game.cell_size
	var start: Vector2 = game.tray_centers[slot]
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	t.position = start
	game._unhandled_input(t)
	for k in range(1, 11):
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = start.lerp(finger, k / 10.0)
		game._unhandled_input(d)
	t = t.duplicate()
	t.pressed = false
	t.position = finger
	game._unhandled_input(t)


func _check(ok: bool, msg: String) -> void:
	if not ok:
		errors += 1
		printerr("FAIL: " + msg)
