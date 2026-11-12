extends Node
## Entry point: keeps the background and switches between screens
## (splash → menu → game). Rebuilds the menu when the theme changes.
##
## Developer options (after "--" on the command line), e.g.
##   godot --path . -- --theme=candy --screen=game-demo
##   --theme=<id>        preview a theme without saving it
##   --lang=<code>       preview a language (en fr de es it ar) without saving it
##   --screen=menu|game|game-demo|pause|gameover|tutorial|hint   skip the splash and open that screen
##   --shot=<file.png>   save a screenshot after ~1.5 s, then quit

var current: Node
## Control-based screens (menus) live here so they get the full screen size.
var ui_layer: CanvasLayer


func _ready() -> void:
	add_child(GradientBackground.new())
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	Palette.theme_changed.connect(_on_theme_changed)
	Lang.language_changed.connect(_on_theme_changed)

	var screen := ""
	var shot := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--theme="):
			Palette.apply(arg.trim_prefix("--theme="))
		elif arg.begins_with("--lang="):
			Lang.apply(arg.trim_prefix("--lang="))
		elif arg.begins_with("--screen="):
			screen = arg.trim_prefix("--screen=")
		elif arg.begins_with("--shot="):
			shot = arg.trim_prefix("--shot=")
	match screen:
		"menu":
			show_menu()
		"game":
			show_game()
		"game-demo":
			show_game(false, 12)
		"pause":
			show_game(false, 12)
			current.call_deferred("_open_pause")
		"gameover":
			show_game(false, 12)
			current.call_deferred("_show_game_over_panel", true)
		"tutorial":
			show_game(false, 0, true)
		"hint":
			show_game(false, 12)
			current.set("idle_time", 100.0) # show the hint right away
		_:
			show_splash()
	if shot != "":
		_take_screenshot(shot)


## Developer option: wait for animations to settle, save a PNG, quit.
func _take_screenshot(path: String) -> void:
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("screenshot saved: ", path)
	get_tree().quit()


func show_splash() -> void:
	var splash := SplashScreen.new()
	splash.finished.connect(show_menu)
	_switch_to(splash)


func show_menu() -> void:
	var menu := MenuScreen.new()
	menu.play_pressed.connect(_on_play_pressed)
	menu.how_to_play_pressed.connect(show_game.bind(false, 0, true))
	_switch_to(menu)


## First new game ever starts with the tutorial.
func _on_play_pressed(resume: bool) -> void:
	show_game(resume, 0, not resume and not SaveData.tutorial_done)


func show_game(resume: bool = false, demo_moves: int = 0, tutorial: bool = false) -> void:
	var game := GameScreen.new()
	game.resume_saved = resume
	game.demo_moves = demo_moves
	game.tutorial = tutorial
	game.exit_to_menu.connect(show_menu)
	_switch_to(game)


func _switch_to(screen: Node) -> void:
	if current:
		current.queue_free()
	current = screen
	if screen is Control:
		ui_layer.add_child(screen)
	else:
		add_child(screen)


func _on_theme_changed() -> void:
	# The game screen restyles itself; the menu is simply rebuilt.
	if current is MenuScreen:
		show_menu()


func _notification(what: int) -> void:
	# Android "Back" on the menu closes the app (in game it opens Pause).
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and current is MenuScreen:
		get_tree().quit()
