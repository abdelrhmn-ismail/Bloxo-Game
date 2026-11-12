extends Node
## Plays sounds by name: Audio.play("place") looks for
## res://assets/sounds/place.wav (or .ogg / .mp3).
## Missing files are skipped silently, so you can add sounds any time.

const SOUND_DIR := "res://assets/sounds/"
const POOL_SIZE := 8

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -10.0
	add_child(_music)


func play(sound_name: String, pitch: float = 1.0) -> void:
	if not SaveData.sound_on:
		return
	var stream := _get_stream(sound_name)
	if stream == null:
		return
	var player := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	player.stream = stream
	player.pitch_scale = pitch
	player.play()


func play_music(sound_name: String = "music") -> void:
	if not SaveData.music_on:
		_music.stop()
		return
	var stream := _get_stream(sound_name)
	if stream == null or (_music.playing and _music.stream == stream):
		return
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.set("loop", true)
	_music.stream = stream
	_music.play()


## Call after the music setting changes.
func refresh_music() -> void:
	if SaveData.music_on:
		play_music()
	else:
		_music.stop()


func vibrate(duration_ms: int = 20) -> void:
	if SaveData.vibration_on and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)


## Stops every sound (used before quitting so nothing is left playing).
func stop_all() -> void:
	for player in _players:
		player.stop()
	_music.stop()


func _exit_tree() -> void:
	stop_all()


func _get_stream(sound_name: String) -> AudioStream:
	if _streams.has(sound_name):
		return _streams[sound_name]
	var stream: AudioStream = null
	for ext: String in ["wav", "ogg", "mp3"]:
		var path: String = SOUND_DIR + sound_name + "." + ext
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	_streams[sound_name] = stream
	return stream
