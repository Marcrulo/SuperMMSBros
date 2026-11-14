# Stig

Stig's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Stig — cross

Stig carries a big gold cross (see [art guide](#look)) and uses it as a sword. He
swings it in the **same three moves as Henrik**, with the same poses, frames, damage, knockback and
charge (see [Henrik](henrik.md#henrik--guitar)); everything else except the down special (below) is the default
move set, the cross staying on his back. Only the hitboxes differ, fitted to the drawn cross (held by the foot of the long
beam, never choked up):

| Move | Hitbox center, size | Reach |
|---|---|---|
| Jab | (22, −10), 22×12 | 33 px |
| Side tilt | (29, −16), 24×12 | 41 px |
| Neutral special | (18, −28), 38×26 | 37 px forward, up to 41 px above the feet |

His charge glow is where the raised cross's beams meet, `charge_glow` (−19, −44).

### Down special — cross smash

Stig's down special replaces the ground energy burst: like a wizard driving his staff into the
ground, he grips the upright cross in both hands, lifts it, and pushes its foot straight down onto
the floor in front of him as he drops to one knee; a burst of holy light shoots out along the
ground ahead, launching whoever it hits **nearly straight sideways**.

- **On the ground:** 10 / 6 / 12 (28) frames (the default down special's, so its animation timing
  fits). Hitbox (36, −10), 56×20 — in front of him only (from 8 to 64 px ahead, up to 20 px
  high): from where the cross's foot hits the floor (about 13 px ahead) out along the light.
  Damage 9, base 180, growth 1.4, angle 10°, FACING: a low, nearly horizontal launch away from
  him.
- **In the air:** he drops straight down at 360 px/s like the default dive, but with **no hitbox**
  on the way (`down_special_dive` with no active frames), then smashes on landing (from frame 1).
- **The light:** a picture drawn in front of him from the impact point on the active frames and a
  little after (see [art guide](#look)); presentation only.

Files: `characters/stig/moves/` (`moveset.tres` + `jab.tres`, `side_tilt.tres`,
`neutral_special.tres`, `down_special.tres`, `down_special_dive.tres`).

## Look

### Weapon and own drawings

- **Stig's cross:** a solid gold Latin cross, not a sword: a long beam about 39 px and a crossbar
  16 px wide near the top (the arm above it shorter than the side arms, so it reads as a Latin
  cross even when only the top shows), both beams about 4 px thick with square ends, bevelled (lit
  edges up and right, shaded down and left). He holds it 6 px up from the foot of the long beam
  and swings it like a sword (Henrik's poses, no choking up), so the crossbar is out at the far
  end. It never points below level, so in the follow-throughs it's held out forward instead of
  down into the floor. Frames 112×80 like Henrik's. On his back it hangs diagonally like Gitte's
  scissors, at the same slant: the cross head sticks out behind his neck at head height (left),
  the long beam slants down behind his body, and its foot pokes out just in front of his hip
  (right).
- **Stig's cross smash** (his `down_special`, 5 drawings), like a wizard driving his staff into
  the ground: the cross held upright in front of him in **both hands** (the back fist drawn over
  the beam just above the front one), well clear of his face; lifted higher; then (the strike
  drawing and the next) pushed straight down, its foot on the floor about 13 px ahead, as he drops
  to one knee; then getting up, still holding it upright. **The light** (`burst.png`, 4 drawings
  of 80×28, drawn at ¾ on the floor with its left edge 7 px ahead of his feet, so it starts at the
  cross's foot; 3 ticks each from the first active frame): a white flash where the cross hits,
  with short rays; then warm light fanning out forward along the floor up to ~26° (white core on
  the floor, pale yellow glow and three rays, a gold rim, a dithered far end), with a few
  twinkles; then the same breaking up as it fades. Colors: white (255, 255, 236), pale
  (255, 238, 150), gold (246, 196, 72).
