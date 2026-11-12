extends Node
## Smoke test: opens every screen and plays a few moves through the real
## GameScreen code, to catch script errors. Run from the project folder:
##   godot --headless --path . res://tests/smoke_test.tscn
## (It is a scene, not a -s script, so the autoloads are available.)

var errors := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
	var save := SaveData
	var saved_backup := save.saved_game.duplicate(true)
	var best_backup: int = save.best_score
	save.saved_game = {}

	var menu := MenuScreen.new()
	tree.root.add_child(menu)
	await tree.process_frame
	menu.queue_free()

	var splash := SplashScreen.new()
	tree.root.add_child(splash)
	await tree.process_frame
	splash.queue_free()

	var game := GameScreen.new()
	tree.root.add_child(game)
	await tree.process_frame

	# Play moves by calling the same code the touch handlers use.
	var moves := 0
	for attempt in 40:
		if game.state.game_over:
			break
		var placed := false
		for slot in game.state.tray.size():
			if placed or game.state.tray[slot] == null:
				continue
			var shape: Array = game.state.tray[slot]["shape"]
			for row in Board.SIZE:
				for col in Board.SIZE:
					if not placed and game.state.board.can_place(shape, col, row):
						game.drag_slot = slot
						game.has_ghost = true
						game.ghost_cell = Vector2i(col, row)
						game._drop()
						placed = true
						moves += 1
		await tree.process_frame
	print("moves played: %d, score: %d" % [moves, game.state.score])
	if moves == 0:
		_fail("no moves were played")
	if not game.state.game_over and not save.has_saved_game():
		_fail("game was not auto-saved")

	# Resume the saved game in a new screen.
	if save.has_saved_game():
		var score_before: int = game.state.score
		game.queue_free()
		await tree.process_frame
		var resumed := GameScreen.new()
		resumed.resume_saved = true
		tree.root.add_child(resumed)
		await tree.process_frame
		if resumed.state.score != score_before:
			_fail("resumed score %d != %d" % [resumed.state.score, score_before])
		resumed._open_pause()
		await tree.process_frame
		if not (resumed.overlay is PausePanel):
			_fail("pause panel did not open")
		resumed._restart()
		await tree.process_frame
		if resumed.state.score != 0 or save.has_saved_game():
			_fail("restart did not reset the game")
		resumed.queue_free()

	await tree.process_frame
	# Put the player's real save back.
	save.saved_game = saved_backup
	save.best_score = best_backup
	save.write()
	print("smoke test: %s" % ("OK" if errors == 0 else "%d FAILED" % errors))
	tree.quit(1 if errors > 0 else 0)


func _fail(msg: String) -> void:
	errors += 1
	printerr("FAIL: " + msg)
