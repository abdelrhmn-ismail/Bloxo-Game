extends Node
## Renders the game at full phone resolution in an off-screen viewport,
## so store screenshots are 1080x1920 no matter how small the monitor is.
## Takes the same developer options as the game (see scenes/main.gd), plus:
##   --score=<n>   score shown on the game screens
##   --best=<n>    best score shown
##   godot --path . res://tools/store_shot.tscn -- --theme=candy --screen=game-demo --score=1260 --shot=/tmp/a.png
## Used by tools/make_store_screenshots.sh. Values are set in memory only;
## that script also backs up and restores the real save file.

const SIZE := Vector2i(1080, 1920)


func _ready() -> void:
	var score := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--score="):
			score = int(arg.trim_prefix("--score="))
		elif arg.begins_with("--best="):
			SaveData.best_score = int(arg.trim_prefix("--best="))
	# No daily-gift pop-up covering the menu.
	SaveData.last_daily_date = Time.get_date_string_from_system()

	var holder := SubViewportContainer.new()
	add_child(holder)
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(vp)
	# main.gd takes the screenshot of its own viewport (this one) and quits.
	var main: Node = load("res://scenes/main.tscn").instantiate()
	vp.add_child(main)
	if score >= 0 and main.get("current") is GameScreen:
		var game: GameScreen = main.get("current")
		game.state.score = score
		game.displayed_score = float(score)
