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
		"powerups": SaveData.powerups.duplicate(), "last_daily_date": SaveData.last_daily_date,
		"last_hourly_time": SaveData.last_hourly_time, "best_score": SaveData.best_score,
	}
	SaveData.saved_game = {}

	await _test_tutorial()
	await _test_tutorial_skip()
	await _test_hint()
	await _test_music()
	await _test_powerups()
	await _test_rescue()
	await _test_gifts()

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
	_check(game.tutorial_step == 2 and game.banner_key == "TUT_TRY_AGAIN", "wrong move -> try again")

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


func _tap_board(game: GameScreen, cell: Vector2i) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = true
	e.position = game.board_origin + (Vector2(cell) + Vector2(0.5, 0.5)) * game.cell_size
	game._unhandled_input(e)


func _test_powerups() -> void:
	SaveData.powerups = {"hammer": 2, "bomb": 2, "shuffle": 2, "undo": 2}
	var game := GameScreen.new()
	tree.root.add_child(game)
	await tree.process_frame
	_check(game.power_buttons.size() == 4 and game.power_buttons["bomb"].visible, "power-up bar shown")

	# Hammer: button → aim → tap a block → it breaks, count goes down.
	game.state.board.set_cell(1, 1, 2)
	game._on_power_pressed("hammer")
	_check(game.aim_mode == "hammer" and game.banner_key == "TAP_HAMMER", "hammer waits for a tap")
	_tap_board(game, Vector2i(5, 5)) # empty cell: nothing happens, still aiming
	_check(game.aim_mode == "hammer" and SaveData.powerup_count("hammer") == 2, "tapping an empty cell keeps aiming")
	_tap_board(game, Vector2i(1, 1))
	_check(game.state.board.get_cell(1, 1) == Board.EMPTY, "hammer broke the block")
	_check(SaveData.powerup_count("hammer") == 1 and game.aim_mode == "", "hammer used once")

	# Pressing the active button again cancels without spending.
	game._on_power_pressed("bomb")
	game._on_power_pressed("bomb")
	_check(game.aim_mode == "" and SaveData.powerup_count("bomb") == 2, "second press cancels the bomb")

	# Bomb: clears a 3x3 area.
	for c in Rewards.bomb_area(Vector2i(4, 4)):
		game.state.board.set_cell(c.x, c.y, 1)
	game._on_power_pressed("bomb")
	_tap_board(game, Vector2i(4, 4))
	_check(game.state.board.filled_count() == 0, "bomb cleared the 3x3 area")
	_check(SaveData.powerup_count("bomb") == 1, "bomb used once")

	# Shuffle: new tray.
	game.state.tray[0] = null
	game.state.tray[1] = null
	game._on_power_pressed("shuffle")
	_check(game.state.tray.all(func(p): return p != null), "shuffle refilled the tray")
	_check(SaveData.powerup_count("shuffle") == 1, "shuffle used once")

	# Undo: place a piece, then undo it.
	game._on_power_pressed("undo")
	_check(SaveData.powerup_count("undo") == 2, "undo with nothing to undo is free")
	var before_cells := game.state.board.filled_count()
	var before_score := game.state.score
	var slot := 0
	_drag(game, slot, Vector2i(0, 0))
	await tree.process_frame
	_check(game.state.board.filled_count() > before_cells, "piece placed before undo")
	game._on_power_pressed("undo")
	_check(game.state.board.filled_count() == before_cells and game.state.score == before_score, "undo restored board and score")
	_check(game.state.tray[slot] != null and SaveData.powerup_count("undo") == 1, "undo returned the piece")
	game.queue_free()
	await tree.process_frame
	print("power-ups: ok")


func _test_rescue() -> void:
	SaveData.powerups = {"hammer": 0, "bomb": 1, "shuffle": 0, "undo": 0}
	var game := GameScreen.new()
	tree.root.add_child(game)
	await tree.process_frame
	# Build a stuck board: everything full except a scattered pattern, tray = 3x3 squares.
	for r in Board.SIZE:
		for c in Board.SIZE:
			game.state.board.set_cell(c, r, 0 if (r + c) % 2 == 0 else Board.EMPTY)
	var big := {"shape": Shapes.parse("XXX\nXXX\nXXX"), "color": 1}
	game.state.tray = [big, null, null]
	game.state.game_over = not game.state.has_any_move()
	_check(game.state.game_over, "test board is stuck")
	game._show_game_over_panel(false)
	await tree.process_frame
	_check(game._can_rescue(), "rescue offered with a bomb in stock")
	var panel: GameOverPanel = game.overlay
	panel.keep_playing_pressed.emit()
	await tree.process_frame
	_check(game.rescue_mode and game.overlay == null and game.banner_key == "RESCUE", "rescue mode started")
	game._on_power_pressed("bomb")
	_tap_board(game, Vector2i(1, 1)) # clears a 3x3 → the 3x3 piece fits
	_check(not game.state.game_over and not game.rescue_mode, "bomb saved the game")
	_check(game.banner_key == "", "rescue message gone")
	game.queue_free()
	await tree.process_frame
	print("rescue: ok")


func _test_gifts() -> void:
	SaveData.powerups = {"hammer": 0, "bomb": 0, "shuffle": 0, "undo": 0}
	SaveData.last_daily_date = ""
	SaveData.last_hourly_time = 0.0
	_check(SaveData.daily_gift_ready(), "daily gift ready the first time")
	var gift := SaveData.claim_daily_gift()
	_check(gift.size() == 4 and SaveData.powerup_count("bomb") == 1, "daily gift gives one of each")
	_check(SaveData.claim_daily_gift().is_empty(), "daily gift only once per day")
	var kind := SaveData.claim_hourly_gift()
	_check(kind in Rewards.KINDS and SaveData.powerup_count(kind) == 2, "hourly gift adds a power-up")
	_check(SaveData.claim_hourly_gift() == "", "hourly gift then waits")
	_check(SaveData.hourly_gift_seconds_left() > 3500, "about an hour to wait")

	# Menu shows the daily pop-up when available and claims it on close.
	SaveData.last_daily_date = ""
	var menu := MenuScreen.new()
	tree.root.add_child(menu)
	await tree.process_frame
	await tree.process_frame
	var panel: GiftPanel = null
	for child in menu.get_children():
		if child is GiftPanel:
			panel = child
	_check(panel != null, "menu shows the daily gift pop-up")
	if panel:
		var before := SaveData.powerup_count("hammer")
		panel.close()
		_check(SaveData.powerup_count("hammer") == before + 1, "closing the pop-up claims the gift")
	_check(menu.gift_button.disabled, "free gift button waits for the timer")
	menu.queue_free()
	await tree.process_frame
	print("gifts: ok")


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
