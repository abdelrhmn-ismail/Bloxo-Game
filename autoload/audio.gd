extends Node
## Plays sounds by name: Audio.play("place") looks for
## res://assets/sounds/place.wav (or .ogg / .mp3).
## Missing files are skipped silently, so you can add sounds any time.
##
## Music: each theme has its own loop, assets/sounds/music_<theme>.*
## (falls back to music.*). It switches with a short fade when the
## theme changes.

const SOUND_DIR := "res://assets/sounds/"
const POOL_SIZE := 8
const MUSIC_DB := -12.0
const FADE := 0.4

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_tween: Tween


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)
	Palette.theme_changed.connect(refresh_music)


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


## Name of the music track for the current theme.
func music_for_theme() -> String:
	var name_for_theme := "music_" + Palette.theme_id
	return name_for_theme if _get_stream(name_for_theme) != null else "music"


## Plays the current theme's music (fades over from another track).
func play_music() -> void:
	if not SaveData.music_on:
		_music.stop()
		return
	var stream := _get_stream(music_for_theme())
	if stream == null or (_music.playing and _music.stream == stream):
		return
	_make_looping(stream)
	if _music_tween:
		_music_tween.kill()
	if _music.playing:
		_music_tween = create_tween()
		_music_tween.tween_property(_music, "volume_db", -40.0, FADE)
		_music_tween.tween_callback(_start_music.bind(stream))
		_music_tween.tween_property(_music, "volume_db", MUSIC_DB, FADE)
	else:
		_start_music(stream)
		_music.volume_db = MUSIC_DB


## Name of the stream currently playing as music ("" if none).
func current_music() -> String:
	if not _music.playing or _music.stream == null:
		return ""
	return _music.stream.resource_path.get_file().get_basename()


## Call after the music setting or the theme changes.
func refresh_music() -> void:
	if SaveData.music_on:
		play_music()
	else:
		_music.stop()


## duration in ms; strength 0..1 (phones that support it vibrate harder).
func vibrate(duration_ms: int = 20, strength: float = -1.0) -> void:
	if SaveData.vibration_on and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms, strength)


## Stops every sound (used before quitting so nothing is left playing).
func stop_all() -> void:
	for player in _players:
		player.stop()
	if _music_tween:
		_music_tween.kill()
	_music.stop()


func _exit_tree() -> void:
	stop_all()


func _start_music(stream: AudioStream) -> void:
	_music.stream = stream
	_music.play()


func _make_looping(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.set("loop", true)


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
