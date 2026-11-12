# Bloxo

**Bloxo** is an original block puzzle game built with **Godot 4**.
Drag pieces onto an 8×8 board, fill rows or columns to clear them, chain combos, and chase your best score.

See [PLAN.md](PLAN.md) for the full roadmap.

## ▶️ Run the game
1. Download **Godot 4.4 or newer** (Standard, not .NET) from https://godotengine.org/download
2. Open Godot → **Import** → select this folder's `project.godot` → **Import & Edit**
3. The first import takes a few seconds
4. Press **▶️** (top right) or **F5**
5. Play with the mouse: drag the pieces from the bottom onto the board

If anything red shows up in the **Output** panel, copy it and open an issue.

## 🧪 Run the tests
From the project folder:
```
godot --headless --path . --import
godot --headless --path . -s tests/test_runner.gd      # rule tests → "0 failed"
godot --headless --path . res://tests/smoke_test.tscn  # plays real moves → "smoke test: OK"
```

## 🖼️ Regenerate the logo and icons
```
python3 tools/make_logo.py     # needs Pillow
python3 tools/make_sounds.py   # starter sound effects
```

## 🎮 How to play
- Drag one of the 3 pieces onto an empty spot (pieces cannot be rotated)
- A full row or column is cleared and gives points
- Clearing several lines at once multiplies the points
- Clearing at least once every 3 pieces keeps a **combo** going
- When you use all 3 pieces you get 3 new ones
- **Game over** when none of your pieces fit anywhere

## 🎨 Where to change things
| What | File |
|---|---|
| Game name | `project.godot` → `config/name` |
| Colors | `autoload/palette.gd` |
| Piece shapes | `logic/shapes.gd` (drawn with `X` and `.`) |
| Points and combos | `logic/scoring.gd` |
| Difficulty | `logic/piece_generator.gd`, `logic/game_state.gd` |
| Block look (neon) | `effects/cell_painter.gd` |
| In-game logo | `ui/neon_logo.gd` |
| Logo / icon images | `tools/make_logo.py` → `icon.png`, `assets/images/` |
| Font | `assets/fonts/` (Audiowide, SIL OFL) + `project.godot` → `gui/theme/custom_font` |
| Sounds | put a file with the same name in `assets/sounds/` |
| Background music | add `assets/sounds/music.ogg` |
| App icon | `icon.png` (generated) |

## 📁 Project structure
```
autoload/   always-loaded singletons (colors, save data, audio)
logic/      game rules, no drawing (board, shapes, scoring, state)
scenes/     main entry, menu, game screen, background
ui/         buttons, labels and pop-up panels
effects/    block drawing, clear effect, floating text
assets/     images, sounds, fonts
tests/      rule tests + smoke test scene
tools/      helper scripts (logo/icon renderer, starter sound generator)
```

## 📜 Credits
- Font: [Audiowide](https://fonts.google.com/specimen/Audiowide) by Astigmatic — SIL Open Font License 1.1 (`assets/fonts/OFL.txt`)
- Everything else (code, logo, icons, sounds) is original to this project.
