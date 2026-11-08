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
  `display_name`, `stats` (its `FighterStats`, which holds its move set). The sprites are still the
  one default set (`assets/fighters/default/`); per-character sprite folders come with the second
  character.
- The **`Roster`** resource (`fighter/characters/roster.tres`) lists the playable characters in
  order and the number of slots on the select screen: **10**. Slots past the list are **locked**.
- v1 has one character: `default` ("Default" until it gets a real name), using `default_stats.tres`.
- Only P1 chooses. P2 (the dummy, later the CPU) plays the default character.

## Character select

Screen layout (480×270, background `#1a1c2c`):

- **Title** "CHOOSE YOUR FIGHTER", 16 px, centered, top at y 14, `#f4f4f4`.
- **Grid:** 5 columns × 2 rows of 64×64 tiles, 8 px apart, centered (x 64…416), top at y 44.
  - An **unlocked** tile shows the character's head (the portrait cut used by the player cards,
    20×20) at 3× (60×60, nearest-neighbor) on a `#333c57` square.
  - A **locked** tile shows the same head as a flat silhouette in `#29366f` with a "?" (16 px,
    `#94b0c2`) on top. It can be highlighted but not chosen.
  - The highlighted tile has a 2 px border in the P1 color `#b13e53` and a small "P1" tag above its
    top-left corner.
- **Name** of the highlighted character, 16 px, centered, top at y 196: its `display_name`, or "???"
  for a locked slot.
- **Hint**, 8 px, centered, top at y 250, `#94b0c2`: "WASD: MOVE   J/SPACE: CHOOSE".
- The first slot is highlighted when the screen opens (or the last chosen one, when coming back
  from the stage select). Choosing an unlocked slot sets `Game.character_id` and opens the stage
  select. Choosing a locked one does nothing.

## Stage select

- **Title** "CHOOSE A STAGE", 16 px, centered, top at y 10.
- **Preview** of the highlighted stage: its background at 240×135 (scaled down), centered, top at
  y 32, with a 1 px `#f4f4f4` border.
- **Name** of the highlighted stage (`display_name`), 8 px, centered, top at y 174.
- **Thumbnails:** one per stage, in the order `mms`, `fc`, `slot_sunset`, `cafe_station`,
  `lindevej`, each 80×45, 8 px apart, centered (x 24…456), top at y 190. The highlighted one has a 2 px `#b13e53` border.
- **Hint**, 8 px, centered, top at y 254, `#94b0c2`: "J/SPACE: FIGHT!   L/ESC: BACK".
- The first stage is highlighted when the screen opens (or the last chosen one). Choosing sets
  `Game.stage_id` and starts the match. Back returns to the character select.
