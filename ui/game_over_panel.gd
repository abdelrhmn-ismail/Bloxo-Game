class_name GameOverPanel
extends OverlayPanel

signal play_again_pressed
signal home_pressed


func setup(score: int, best: int, is_new_best: bool) -> void:
	add_text(Lang.t("GAME_OVER"), 96, Palette.text)
	if is_new_best:
		add_text(Lang.t("NEW_BEST"), 64, Palette.accent)
	add_text(Lang.t("SCORE"), 40, Palette.text_dim)
	add_text(str(score), 120, Palette.text)
	add_text("%s  %d" % [Lang.t("BEST"), best], 48, Palette.accent)
	add_button(Lang.t("PLAY_AGAIN"), func(): play_again_pressed.emit(), Palette.button_primary)
	add_button(Lang.t("HOME"), func(): home_pressed.emit())
