# Fidusen

Fidusen's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Fidusen — banana, book, vine

Fidusen's down, side and up specials are his own; everything else is the default move set.

**Down special — banana peel** (`down_special.tres` with `ability` → `PeelData`):

- 8 / 0 / 10 (18) frames, on the ground or in the air (no dive). On frame 8 a peel appears at
  (8, 0) from his feet, facing side mirrored. In the air it falls at 300 px/s to the floor below it
  (the main platform or a pass-through platform: `Stage.floor_below(point, true)`); with none, it
  falls out of the blast zone and is gone.
- **Up to 3 peels** of his at a time: a 4th removes his oldest. Each lasts 600 ticks (10 s).
- **Tripping:** a fighter other than Fidusen who is on the ground (a grounded state, not `LEDGE`,
  `LEDGE_CLIMB`, `KO` or `TRIPPED`), can be hit, and whose hurtbox touches a landed peel (12×4,
  bottom center at the peel's position) slips: 3 % damage, no launch (horizontal speed 0), state
  `TRIPPED` for 45 ticks, and the peel is gone. Shields don't protect from it. A peel trips one
  fighter. Jumping over it is safe (airborne fighters don't trip).

**Side special — book** (`side_special.tres`): like the [side special](../moves.md#side-special--projectile)
(10 / 0 / 12, one at a time), but the book is thrown at 25° upward (`projectile_angle_deg`) at
240 px/s and falls with gravity 700 px/s² (`projectile_gravity`), spinning. It appears at (14, −16);
hitbox 10×8; damage 7, base 120, growth 0.7, angle 40°, launched in its direction. It's gone on a
hit or a shield, when it lands on the main platform (it passes through the pass-through
platforms), out of the blast zone, or after 120 ticks.

**Up special — vine** (`up_special.tres` with `ability` → `VineData`):

- 6 frames of startup (no launch), on the ground or in the air; once per stay in the air like the
  default up special.
- On frame 6 the Match picks: the nearest **ledge** that nobody holds, whose corner is at most
  100 px from his center, that he's beside or below (feet at most 4 px above the corner, not more
  than 4 px on the stage side of it) → **pull**: over 12 ticks he moves in a straight line to the
  ledge's hang position (no physics), then grabs it (as a normal ledge grab).
- Otherwise → **swing**: a vine hangs from an anchor 140 px straight above his feet. He swings
  forward on it (toward his facing side) at a constant 2.09 rad/s: 60° in 30 ticks, his feet at
  `anchor + 140 × (sin φ × facing, cos φ)` (moved with physics, so floors and walls stop him).
  Then he lets go with the swing's speed (140 × 2.09 px/s along the arc's tangent: about
  (146 × facing, −254) px/s) and carries on like a launched up special: air steering, gravity,
  `HELPLESS` once he stops rising, ledges can be grabbed while rising.
- Getting hit ends the vine.

Files: `characters/fidusen/moves/` (`moveset.tres`, `down_special.tres`, `peel.tres`,
`side_special.tres`, `up_special.tres`, `vine.tres`).

## Look

### Fidusen's peel and book

Drawn by the 64 px generator in the same style (outline, three tones), at ¾ in the game:

- `assets/fighters/slot_13/peel.png`: a banana peel lying on the floor, 16×8, one drawing:
  yellow with brown tips, three floppy flaps; its bottom center is the peel's position.
- `assets/fighters/slot_13/projectile.png`: a book, 3 drawings of 16×16 turned 120° further each
  (it spins): a red cover with white page edges.
- His own **down special** pose (5 drawings: bend, drop, crouch, rise, stand) and **side special**
  pose (4 drawings: wind back, throw over the shoulder, follow-through, stand).
