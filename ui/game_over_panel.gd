class_name GameOverPanel
extends OverlayPanel

signal play_again_pressed
signal home_pressed
## Player wants to use a power-up to get out of a stuck board.
signal keep_playing_pressed


func setup(score: int, best: int, is_new_best: bool, can_keep_playing: bool = false) -> void:
	add_text(Lang.t("GAME_OVER"), 96, Palette.text)
	if is_new_best:
		add_text(Lang.t("NEW_BEST"), 64, Palette.accent)
	add_text(Lang.t("SCORE"), 40, Palette.text_dim)
	box.add_child(UIKit.number_label(str(score), 120, Palette.text))
	box.add_child(UIKit.number_label("%s  %d" % [Lang.t("BEST"), best], 48, Palette.accent))
	if can_keep_playing:
		add_button(Lang.t("KEEP_PLAYING"), func(): keep_playing_pressed.emit(), Palette.accent)
	add_button(Lang.t("PLAY_AGAIN"), func(): play_again_pressed.emit(), Palette.button_primary)
	add_button(Lang.t("HOME"), func(): home_pressed.emit())
