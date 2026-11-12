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
godot --headless --path . -s tests/test_runner.gd      # rules + 300 random games → "0 failed"
godot --headless --path . res://tests/smoke_test.tscn  # plays real moves, all themes/languages → "smoke test: OK"
godot --headless --path . res://tests/tap_test.tscn    # a tap never drops a piece; a drag does → both "OK"
godot --path . res://tests/click_theme_test.tscn       # needs a window: clicks THEME with doubled clicks
godot --headless --path . -s tests/balance_check.gd    # difficulty report (smart player), not pass/fail
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

## 🎨 Themes
Four built-in themes, switchable from the menu (**THEME** button) or the pause screen.
The choice is saved. **Neon** is the default.

| Theme | Blocks | Background |
|---|---|---|
| 🌌 Neon | dark glass with glowing edges | scrolling synthwave grid |
| 🍬 Candy | glossy candy with a 3D edge | floating bubbles |
| 💎 Gems | cut jewels with facets and a sparkle | twinkling stars |
| 🌿 Nature | leaf tiles on a wooden board | rolling hills, falling leaves |

Add a theme by copying an entry in `logic/themes.gd` and adding its id to `ORDER`.

## 🌍 Languages
English, French, German, Spanish, Italian and Arabic (right-to-left).
The first launch follows the phone's language (English if unsupported); players can
switch from the menu (**LANGUAGE** button) or the pause screen, and the choice is saved.

- All texts: `logic/strings.gd` → use them in code with `Lang.t("KEY")`
- Add a language: add its code to `LANGS`, its name to `NAMES`, and a translation to
  every entry in `TEXT` — the tests fail if anything is missing
- Arabic uses the **Tajawal** font automatically (Audiowide has no Arabic letters)

## 🛠️ Developer options
Arguments after `--` (handy for previews and screenshots):
```
godot --path . -- --theme=candy --screen=game-demo --shot=/tmp/candy.png
```
| Option | Effect |
|---|---|
| `--theme=<id>` | preview a theme without saving it |
| `--lang=<code>` | preview a language (`en fr de es it ar`) without saving it |
| `--screen=menu\|game\|game-demo\|pause\|gameover` | skip the splash and open that screen (`game-demo` pre-fills the board) |
| `--shot=<file.png>` | save a screenshot after ~1.5 s, then quit |

## 🎨 Where to change things
| What | File |
|---|---|
| Game name | `project.godot` → `config/name` |
| Theme colors and styles | `logic/themes.gd` (current theme lives in `autoload/palette.gd`) |
| Animated backgrounds | `scenes/background.gd` |
| Piece shapes | `logic/shapes.gd` (drawn with `X` and `.`) |
| Points and combos | `logic/scoring.gd` |
| Difficulty | `logic/piece_generator.gd`, `logic/game_state.gd` |
| Block look (per theme) | `effects/cell_painter.gd` |
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
- Font: [Audiowide](https://fonts.google.com/specimen/Audiowide) by Astigmatic — SIL Open Font License 1.1 (`assets/fonts/OFL-Audiowide.txt`)
- Arabic font: [Tajawal](https://fonts.google.com/specimen/Tajawal) by Boutros International — SIL Open Font License 1.1 (`assets/fonts/OFL-Tajawal.txt`)
- Everything else (code, logo, icons, sounds) is original to this project.
