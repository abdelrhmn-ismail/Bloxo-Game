class_name GameOverPanel
extends OverlayPanel

signal play_again_pressed
signal home_pressed


func setup(score: int, best: int, is_new_best: bool) -> void:
	add_text("Game Over", 96, Palette.text)
	if is_new_best:
		add_text("NEW BEST!", 64, Palette.accent)
	add_text("SCORE", 40, Palette.text_dim)
	add_text(str(score), 120, Palette.text)
	add_text("BEST  %d" % best, 48, Palette.accent)
	add_button("Play Again", func(): play_again_pressed.emit(), Palette.button_primary)
	add_button("Home", func(): home_pressed.emit())
