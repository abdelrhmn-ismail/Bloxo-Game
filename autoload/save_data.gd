extends Node
## Saves the best score, settings and the unfinished game to the phone
## (user://save.json).

const PATH := "user://save.json"

var best_score := 0
var sound_on := true
var music_on := true
var vibration_on := true
var hints_on := true
## Set once the player finished or skipped the first-time tutorial.
var tutorial_done := false
## Theme id from logic/themes.gd ("" = default theme).
var theme := ""
## Language code from logic/strings.gd ("" = follow the phone's language).
var language := ""
## Power-up counts, e.g. {"hammer": 2, "bomb": 0, ...}.
var powerups := Rewards.STARTER.duplicate()
## Local date ("2026-11-12") of the last daily gift claimed.
var last_daily_date := ""
## Unix time of the last hourly gift claimed (0 = never).
var last_hourly_time := 0.0
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
	hints_on = bool(data.get("hints_on", true))
	tutorial_done = bool(data.get("tutorial_done", false))
	theme = str(data.get("theme", ""))
	language = str(data.get("language", ""))
	var saved_powerups = data.get("powerups", Rewards.STARTER)
	if typeof(saved_powerups) == TYPE_DICTIONARY:
		for kind in Rewards.KINDS:
			powerups[kind] = clampi(int(saved_powerups.get(kind, 0)), 0, Rewards.MAX_EACH)
	last_daily_date = str(data.get("last_daily_date", ""))
	last_hourly_time = float(data.get("last_hourly_time", 0.0))
	var game = data.get("saved_game", {})
	saved_game = game if typeof(game) == TYPE_DICTIONARY else {}


## Writes to a temporary file first and then swaps it in, so if the phone
## kills the app halfway through a save the old save.json stays intact.
func write() -> void:
	var tmp_path := PATH + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save data: %s" % FileAccess.get_open_error())
		return
	file.store_string(_to_json())
	file.close()
	var err := DirAccess.rename_absolute(tmp_path, PATH)
	if err != OK:
		# Rename not possible here: fall back to writing the file directly.
		var direct := FileAccess.open(PATH, FileAccess.WRITE)
		if direct == null:
			push_warning("Could not save data: %s" % FileAccess.get_open_error())
			return
		direct.store_string(_to_json())


func _to_json() -> String:
	return JSON.stringify({
		"best_score": best_score,
		"sound_on": sound_on,
		"music_on": music_on,
		"vibration_on": vibration_on,
		"hints_on": hints_on,
		"tutorial_done": tutorial_done,
		"theme": theme,
		"language": language,
		"powerups": powerups,
		"last_daily_date": last_daily_date,
		"last_hourly_time": last_hourly_time,
		"saved_game": saved_game,
	})


# --- power-ups & gifts ------------------------------------------------------

func powerup_count(kind: String) -> int:
	return int(powerups.get(kind, 0))


## Spends one power-up. Returns false if there was none.
func use_powerup(kind: String) -> bool:
	if powerup_count(kind) <= 0:
		return false
	powerups[kind] = powerup_count(kind) - 1
	write()
	return true


func daily_gift_ready() -> bool:
	return Rewards.daily_available(last_daily_date, Time.get_date_string_from_system())


## Gives today's gift once. Returns what was given ({} if already claimed).
func claim_daily_gift() -> Dictionary:
	if not daily_gift_ready():
		return {}
	for kind in Rewards.DAILY_GIFT:
		Rewards.add(powerups, kind, Rewards.DAILY_GIFT[kind])
	last_daily_date = Time.get_date_string_from_system()
	write()
	return Rewards.DAILY_GIFT


func hourly_gift_seconds_left() -> int:
	return Rewards.hourly_seconds_left(last_hourly_time, Time.get_unix_time_from_system())


## Gives one random power-up if the hourly gift is ready. Returns its
## kind, or "" if it is not ready yet.
func claim_hourly_gift() -> String:
	if hourly_gift_seconds_left() > 0:
		return ""
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var kind := Rewards.random_kind(rng)
	Rewards.add(powerups, kind, 1)
	last_hourly_time = Time.get_unix_time_from_system()
	write()
	return kind
