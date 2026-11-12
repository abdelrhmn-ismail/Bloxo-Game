extends Node
## Current language. Lang.t("PLAY") returns the text in that language.
## Texts live in logic/strings.gd. The first launch follows the phone's
## language when it is supported, otherwise English.

signal language_changed

const ARABIC_FONT := "res://assets/fonts/Tajawal-Bold.ttf"
const MAIN_FONT := "res://assets/fonts/Audiowide-Regular.ttf"

var code := "en"


func _ready() -> void:
	_add_font_fallback()
	var saved := SaveData.language
	apply(saved if saved != "" else Strings.from_locale(OS.get_locale()))


## Text for a key in the current language (falls back to English, then
## to the key itself so a missing text is easy to spot).
func t(key: String) -> String:
	var entry: Dictionary = Strings.TEXT.get(key, {})
	return entry.get(code, entry.get("en", key))


func is_rtl() -> bool:
	return Strings.RTL.has(code)


func language_name() -> String:
	return Strings.NAMES.get(code, code)


## Switches language without saving.
func apply(new_code: String) -> void:
	code = new_code if Strings.LANGS.has(new_code) else "en"
	TranslationServer.set_locale(code)
	language_changed.emit()


## Switches language and remembers it.
func set_language(new_code: String) -> void:
	apply(new_code)
	SaveData.language = code
	SaveData.write()


## Next language (used by the LANGUAGE buttons). Ignores a duplicated click.
func cycle_language() -> void:
	if not UIKit.accept_action():
		return
	set_language(Strings.next(code))


## Audiowide has no Arabic letters: let Godot use Tajawal for any glyph
## Audiowide does not have. The project font is a shared resource, so this
## applies to every label and button.
func _add_font_fallback() -> void:
	var main_font := load(MAIN_FONT) as Font
	var arabic := load(ARABIC_FONT) as Font
	if main_font == null or arabic == null:
		push_warning("Lang: could not load fonts for Arabic fallback")
		return
	if not main_font.fallbacks.has(arabic):
		var list := main_font.fallbacks.duplicate()
		list.append(arabic)
		main_font.fallbacks = list
