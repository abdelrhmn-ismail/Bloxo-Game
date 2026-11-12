# 🎮 Bloxo — Full Plan (Godot 4 → Google Play)

> **Rule:** no images, sounds or code from any other game. Everything here is original,
> and the name and look must stay clearly different from existing block puzzle games.

---

## ✅ Progress

- [x] Phase 0 — Project folder and settings
- [x] Phase 1 — Project structure
- [x] Phase 2 — Game rules (board, pieces, clearing, scoring, game over) + tests
- [x] Phase 3 — Touch controls (drag, ghost preview, return animation)
- [x] Phase 4 — Look and identity (**Bloxo**, 4 switchable themes — Neon default, Candy, Gems, Nature — block logo, icons, Audiowide font)
- [x] Phase 5 — Audio (generated sound effects + an original music loop per theme)
- [x] Player helpers — first-time tutorial, idle hints, stronger vibration on big combos
- [x] Languages — English, French, German, Spanish, Italian, Arabic (RTL); follows the phone, switchable in settings
- [x] Phase 6 — Screens (splash, menu with Continue, pause, game over, auto-save/resume, safe area)
- [ ] Phase 7 — Testing on a real phone
- [ ] Phase 8 — Ads (optional)
- [ ] Phase 9 — Android export (AAB)
- [ ] Phase 10 — Google Play release
- [ ] Phase 11 — After launch

---

## 📦 Phase 0 — Setup

**Install:**
1. **Godot 4** (Standard, not .NET) — https://godotengine.org/download
2. **JDK 17** (for Android export later)
3. **Android Studio** (only for the Android SDK)

**Project settings (in `project.godot`):**
- Portrait, base resolution 1080×1920
- `stretch mode = canvas_items` + `aspect = expand` → fits every phone
- Mouse emulates touch → playable on desktop
- Android Back button opens Pause instead of quitting

---

## 🗂️ Phase 1 — Structure

```
bloxo/
├── project.godot            ← project settings (game name here)
├── PLAN.md                  ← this plan
├── README.md                ← how to run
├── autoload/
│   ├── palette.gd           ← 🎨 all colors in one place
│   ├── save_data.gd         ← best score + settings
│   └── audio.gd             ← sounds, music, vibration
├── logic/                   ← game rules (no drawing)
│   ├── board.gd             ← grid, placing, clearing
│   ├── shapes.gd            ← piece shapes (drawn with X and .)
│   ├── piece_generator.gd   ← fair random pieces
│   ├── scoring.gd           ← point rules
│   └── game_state.gd        ← whole game state
├── scenes/
│   ├── main.tscn / main.gd  ← switches screens
│   ├── menu_screen.gd
│   ├── game_screen.gd       ← drawing + dragging
│   └── background.gd
├── ui/                      ← UI kit, pause / game over panels, logo
├── effects/                 ← block painter, clear effect, popup text
├── assets/images | sounds | fonts
├── tests/test_runner.gd
└── tools/make_sounds.py
```

Logic is separated from scenes (like backend vs frontend) so the rules can be tested on their own.

---

## 🧠 Phase 2 — Game rules

### Board `board.gd`
- 8×8, each cell is `-1` (empty) or a color index `0..7`
- `can_place` / `place` / `find_full_lines` / `clear_lines` / `can_fit_anywhere` / `lines_if_placed`

### Shapes `shapes.gd`
Shapes are drawn as text — `X` filled, `.` empty:
```
"X..\nX..\nXXX"   ← big corner
```
To add a shape, draw it and add it to the list.

### Piece generator `piece_generator.gd`
- 3 pieces per round; a new set arrives when all 3 are used
- Small pieces are more common early; big pieces grow with the score
- At least one of the 3 always fits (no unfair losses)

### Scoring `scoring.gd`
| Event | Points |
|---|---|
| Place a piece | number of its cells |
| Clear lines | cleared cells × 10 × number of lines |
| Combo (clears in a row) | +50% per combo level |
| Whole board cleared | +300 🎉 |

The combo stays alive while you clear at least once every 3 pieces.

### Game over
After every move: if none of the remaining pieces fit → game over, best score saved.

---

## 👆 Phase 3 — Touch controls
- Touching a piece enlarges it and lifts it **above the finger**
- A transparent ghost shows where it will land
- Lines that would be cleared light up in the piece's color before release
- Invalid spot → piece flies back to the tray
- Light vibration (can be turned off)

---

## 🎨 Phase 4 — Look and identity

1. **Name:** **Bloxo** ✅ (store title: *Bloxo: Block Puzzle*)
2. **Themes** ✅ — switchable from the menu and pause screen, choice is saved:
   - 🌌 **Neon** (default) — dark glass blocks with glowing borders, synthwave grid
   - 🍬 **Candy** — glossy candy blocks, floating bubbles
   - 💎 **Gems** — faceted jewel blocks, twinkling stars
   - 🌿 **Nature** — leaf tiles on a wooden board, hills and falling leaves
3. **Colors:** per theme in `logic/themes.gd`, current theme in `autoload/palette.gd` ✅
4. **Logo:** "BLOXO" built from neon blocks ✅ (`ui/neon_logo.gd` in game, `tools/make_logo.py` for PNGs)
5. **Icons:** `icon.png`, adaptive foreground/background, store icon, feature graphic ✅
6. **Font:** Audiowide (SIL OFL) ✅

Generated images in `assets/images/`:
| Image | Size | Use |
|---|---|---|
| `logo.png` | 1200×360 | boot splash, store, social |
| `store_icon.png` | 512×512 | Google Play icon |
| `icon_foreground.png` / `icon_background.png` | 432×432 | Android adaptive icon |
| `feature_graphic.png` | 1024×500 | Google Play feature graphic |

**Free legal sources:** Kenney.nl (CC0), or design in Figma/Inkscape.

**Juice:** placement flash ✅, clear particles ✅, praise words ✅, counting score ✅, screen shake ✅.

---

## 🔊 Phase 5 — Audio

| File (`assets/sounds/`) | When |
|---|---|
| `pick.wav` | pick up a piece |
| `place.wav` | place it |
| `invalid.wav` | piece returns |
| `clear.wav` | clear (pitch rises with combo) |
| `new_best.wav` | new best score |
| `game_over.wav` | game over |
| `click.wav` | buttons |
| `music_<theme>.wav` | background music per theme (generated by `tools/make_music.py`) |

- Current sounds are generated by `tools/make_sounds.py` (100% original)
- To replace one, drop a file with **the same name** into `assets/sounds/`
- Sources: **jsfxr.me**, **Kenney.nl**, **Pixabay Music**

---

## 📱 Phase 6 — Screens
- ✅ Menu: logo, Play, best score, sound/music/vibration toggles
- ✅ Game: score, best score, pause button
- ✅ Pause: resume / restart / home + settings
- ✅ Game over: score, "NEW BEST!", play again
- ✅ Auto-save after every move + **Continue** on the menu
- ✅ Splash: boot splash (logo image) + animated block logo
- ✅ Safe area: HUD and tray avoid notches / system bars

---

## ✅ Phase 7 — Testing
1. **Automated:** `godot --headless --path . -s tests/test_runner.gd` (rules) and
   `godot --headless --path . res://tests/smoke_test.tscn` (plays real moves)
2. **Desktop:** ▶️ in Godot, play with the mouse
3. **Phone:** USB cable + USB debugging + Godot's Android remote deploy button
4. **Checklist:**
   - [ ] Small, large and tablet screens
   - [ ] Low-end phone runs smoothly
   - [ ] Best score survives closing the app
   - [ ] Sound stops when muted
   - [ ] Back button opens Pause

---

## 💰 Phase 8 — Ads (optional)
- Godot AdMob plugin
- **Interstitial:** after every 2–3 game overs (not every time)
- **Rewarded:** "watch an ad to continue" (clear a few cells)
- **Banner:** optional, at the bottom
- ⚠️ Use **test ad IDs only** while developing — clicking your own live ads can get the account banned

---

## 🤖 Phase 9 — Android export
1. Godot: **Editor → Editor Settings → Export → Android** → set SDK and JDK paths
2. **Project → Install Android Build Template**
3. **Project → Export → Add → Android**:
   - Package name: `com.<yourname>.bloxo` (**cannot change after release**)
   - Version code: 1 (increase on every update) — Version name: `1.0.0`
   - Architectures: arm64-v8a + armeabi-v7a
   - Permissions: **VIBRATE**
   - Icons (main + adaptive)
4. **Signing key:**
   ```
   keytool -genkey -v -keystore bloxo-release.keystore -alias bloxo -keyalg RSA -keysize 2048 -validity 10000
   ```
   ⚠️⚠️ **Back up the keystore and password in 3 places.** Losing it means you can never update the app.
   ⚠️ Never commit it (already in `.gitignore`).
5. Export an **AAB** (Export With Debug = off)

---

## 🏪 Phase 10 — Google Play
1. Developer account: play.google.com/console — **$25 one-time** + identity verification
2. Create App → Game → Free
3. Store listing: 512×512 icon, 1024×500 feature graphic, 4–8 phone screenshots, short (80 chars) and full description
4. **Privacy policy** page (GitHub Pages works)
5. Forms: content rating, data safety (AdMob collects the advertising ID), target audience (⚠️ don't target children with regular ads), ads declaration
6. ⚠️ **Closed test: at least 12 testers for 14 continuous days** (required for new personal accounts) — start collecting testers early
7. Apply for production → review (a few days to a week) → 🎉

---

## 🔄 Phase 11 — After launch
- Watch Android Vitals (crashes / ANRs)
- Reply to reviews
- Update = version code +1 → new AAB → upload
- Ideas: daily challenge, unlockable themes, achievements, leaderboard (Google Play Games)

---

## ⏱️ Timeline

| Week | Work | Result |
|---|---|---|
| 1 | Phases 0–3 | playable game ✅ |
| 2 | Phases 4–6 | own look, sounds, all screens ✅ (music pending) |
| 3 | Phases 7–9 | running on a phone + ads + AAB |
| 4–5 | Phase 10 | closed test (14 days) |
| 6 | | 🚀 launch |
