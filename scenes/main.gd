extends Node
## Entry point: keeps the background and switches between screens.

var current: Node
## Control-based screens (menus) live here so they get the full screen size.
var ui_layer: CanvasLayer


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.background_bottom)
	add_child(GradientBackground.new())
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	show_menu()


func show_menu() -> void:
	var menu := MenuScreen.new()
	menu.play_pressed.connect(show_game)
	_switch_to(menu)


func show_game() -> void:
	var game := GameScreen.new()
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


func _notification(what: int) -> void:
	# Android "Back" on the menu closes the app (in game it opens Pause).
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and current is MenuScreen:
		get_tree().quit()
