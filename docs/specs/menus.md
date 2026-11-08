# Menus

The screens before a match: **character select**, then **stage select**, then the match. Pause and
result screens are in [match & stage](match-and-stage.md).

## Flow

```
Character select ──choose──▶ Stage select ──choose──▶ Match
        ▲                          │
        └──────────back────────────┘
```

- The game starts on the character select (`ui/character_select.tscn` is the main scene).
- With `--stage=<id>` on the command line, the menus are skipped and the match starts at once on
  that stage with the default character (for quick testing; headless runs in M8 use this too).
- The choices live in the `Game` autoload (`game/game.gd`, always loaded): `character_id` and
  `stage_id`. The Match reads them when it starts (the `--stage` option wins over `stage_id`).
  `Game` also changes between the screens.

## Controls

Menus use Godot's built-in `ui_*` actions (arrows / d-pad to move, Enter / Space / A to choose,
Esc / B to go back). At startup `Game` also adds the game keys to them, so the same hands work:

| Menu action | Also from |
|---|---|
| `ui_left` / `ui_right` / `ui_up` / `ui_down` | `move_left` / `move_right` / `up` / `down` (A, D, W, S) |
| `ui_accept` | `attack` (J), `jump` (Space) |
| `ui_cancel` | `shield` (L) |

Moving left from the leftmost tile of a row wraps to the rightmost tile of the same row, and right
from the rightmost wraps to the leftmost (on both screens). Up and down don't wrap.

## Characters and the roster

- A **`CharacterData`** resource per character (`fighter/characters/<id>.tres`): `id`,
  `display_name`, `playable`, `portrait` (a select-screen picture, optional) and `stats` (its
  `FighterStats`, which holds its move set; empty for a character that isn't playable yet). The
  sprites are still the one default set (`assets/fighters/default/`); per-character sprite folders
  come with the second playable character.
- The **`Roster`** resource (`fighter/characters/roster.tres`) lists the characters in
  select-screen order and the number of slots: **10**. A slot holding a character that isn't
  `playable`, or past the list, is **locked**.
- v1 has one playable character, `default`, named **Pia**, using `default_stats.tres`, with a
  portrait (`assets/fighters/portraits/default.png`), and nine announced ones in slots 2–10,
  `slot_02` … `slot_10`: not playable, each with a portrait
  (`assets/fighters/portraits/slot_NN.png`). Their names: 2 Gitte,
  3 Trine, 4 Nina, 5 Michael Bech, 6 Henrik, 7 Stig, 8 Casper, 9 Kim, 10 Mette (more details
  later).
- **Portraits are all 221×279** (RGB), used as they are. They're drawn in a pixel-art style that is
  finer than the game's pixels (around 3 px per art pixel, with eyes in even finer detail), so they
  aren't converted to the game's pixel grid: every conversion tried (k-centroid shrinking, snapping
  to their 3.13 px art grid) deformed the eyes. Instead the select screen shows them near their
  native size (below).
- Only P1 chooses. P2 (the dummy, later the CPU) plays the default character.

## Character select

Screen layout (480×270, background `#1a1c2c`):

- **Title** "CHOOSE YOUR FIGHTER", centered, `#f4f4f4`: in the **Ink Yugo** brush font at 24 px
  (top at y 4) when `assets/fonts/ink_yugo.otf` is present; otherwise the pixel font at 16 px (top
  at y 14).
- **Grid:** 5 columns × 2 rows of 74×74 tiles, 8 px apart, centered (x 39…441), top at y 44. A
  tile's picture fills its inside, 70×70 (2 px border).
  - A character with a **portrait** shows its face: the square (0, 6), 221×221 (a square as wide
    as the portrait, starting 6/221 of its width from the top), drawn into the 70×70 picture with
    linear filtering and mipmaps (the portraits are imported with mipmaps). In the default
    1440×810 window that's 210 screen pixels for 221 source pixels, nearly native, so it stays
    sharp.
  - An **unlocked** character without a portrait shows the fighter's head (the cut used by the
    player cards, 20×20) stretched to the picture, nearest-neighbor, on a `#333c57` square.
  - A **locked** slot with a portrait shows the portrait as it is; one without shows the default
    head as a flat silhouette in `#29366f` with a "?" (16 px, `#94b0c2`) on top. Either way it can
    be highlighted but not chosen.
  - The highlighted tile has a 2 px border in the P1 color `#b13e53` and a small "P1" tag above its
    top-left corner.
- **Name** of the highlighted character, 16 px, centered, top at y 208: its `display_name`, or "???"
  for an empty slot.
- **Hint**, 8 px, centered, top at y 250, `#94b0c2`: "WASD: MOVE   J/SPACE: CHOOSE".
- The first slot is highlighted when the screen opens (or the last chosen one, when coming back
  from the stage select). Choosing an unlocked slot sets `Game.character_id` and opens the stage
  select. Choosing a locked one does nothing.

## Stage select

- **Title** "CHOOSE YOUR STAGE", centered, `#f4f4f4`: in Ink Yugo at 24 px (top at y 2) when the
  font is present; otherwise the pixel font at 16 px (top at y 10).
- **Preview** of the highlighted stage: its background at 240×135 (scaled down), centered, top at
  y 32, with a 1 px `#f4f4f4` border.
- **Name** of the highlighted stage (`display_name`), 8 px, centered, top at y 174.
- **Thumbnails:** one per stage, in the order `mms`, `fc`, `slot_sunset`, `cafe_station`,
  `lindevej`, each 80×45, 8 px apart, centered (x 24…456), top at y 190. The highlighted one has a 2 px `#b13e53` border.
- **Hint**, 8 px, centered, top at y 254, `#94b0c2`: "J/SPACE: FIGHT!   L/ESC: BACK".
- The first stage is highlighted when the screen opens (or the last chosen one). Choosing sets
  `Game.stage_id` and starts the match. Back returns to the character select.

## Sound

- **Menu music:** `assets/music/menu.ogg` loops on both select screens without restarting between
  them (the `Game` autoload plays it, on the `Music` bus) and stops when the match starts. Not
  committed, like the stage music.
- **Sound effects** (`SFX` bus), played by `Game` so they finish even when the screen changes:

| Sound | When | File |
|---|---|---|
| Sound | When | File | Source |
|---|---|---|---|
| move | the highlight moves to another tile (not when a screen opens) | `assets/sfx/menu_move.wav` | "navigation" by Andy Rhode (rhodesmas.com), CC BY 3.0 — credited in `assets/sfx/CREDITS.txt` |
| confirm | a character or stage is chosen | `assets/sfx/menu_confirm.wav` | the user's `select` sound; license unknown, so **not committed** (in `.gitignore`) |
| back | back from the stage select | `assets/sfx/menu_back.wav` | synthesized (`tools/gen_menu_sfx.py`): two falling square-wave notes |
| locked | choosing a locked slot | `assets/sfx/menu_locked.wav` | synthesized: a low detuned buzz, about 0.2 s |

- A sound whose file is missing is simply silent.
