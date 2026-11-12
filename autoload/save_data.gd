extends Node
## Saves the best score, settings and the unfinished game to the phone
## (user://save.json).

const PATH := "user://save.json"

var best_score := 0
var sound_on := true
var music_on := true
var vibration_on := true
## Snapshot from GameState.to_dict(), or {} when there is no game to resume.
var saved_game := {}


func _ready() -> void:
	load_data()


func has_saved_game() -> bool:
	return not saved_game.is_empty()


func load_data() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	best_score = int(data.get("best_score", 0))
	sound_on = bool(data.get("sound_on", true))
	music_on = bool(data.get("music_on", true))
	vibration_on = bool(data.get("vibration_on", true))
	var game = data.get("saved_game", {})
	saved_game = game if typeof(game) == TYPE_DICTIONARY else {}


func write() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save data: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify({
		"best_score": best_score,
		"sound_on": sound_on,
		"music_on": music_on,
		"vibration_on": vibration_on,
		"saved_game": saved_game,
	}))
