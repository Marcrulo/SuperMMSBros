# Kim

Kim's own moves and drawings. The shared rules are in [moves](../moves.md) and the
[art guide](../art-guide.md).

## Kim — handyman

All four of Kim's specials and three of his normals are tools; everything else (up tilt, the air attacks) is the default move set. Every number
below is a starting value, tuned in playtesting.

**Normal attacks** (`jab.tres`, `side_tilt.tres`, `down_tilt.tres`, each with `ability` → `ToolSwingData`):

| Move | Frames | Hitbox center, size | Damage | Base, growth | Angle | Direction | Idea |
|---|---|---|---|---|---|---|---|
| A — hammer | 4 / 3 / 7 (14) | (17, −14), 18×12 | 4 | 110, 0.8 | 35° | FACING | Quick hammer blow, a little more reach and bite than a punch |
| Side+A — axe | 12 / 4 / 14 (30) | (28, −14), 30×16 | 14 | 220, 2.0 | 38° | FACING | Slow, big overhead chop: strong, and reaches 43 px, further than any other normal |
| Down+A — screwdriver | 5 / 4 / 8 (17) | (22, −4), 30×6 | 5 | 90, 0.5 | 70° | FACING | A low stab that sweeps along the floor, 37 px of reach, pops them up a little for combos |

The body keeps the default attack drawings, but a move with other frame counts than the default
plays them stretched to its own frames: the first two drawings over the startup, the strike
drawing (3rd) over the active frames, the last two over the recovery. The tool in his hand
(see [Look](#look)) swings over the same frames. The screwdriver's sweep is only drawn: its
hitbox stays where it is for the 4 active frames.

**Neutral special — hammer** (`neutral_special.tres` with `ability` → `HammerData`): like
[Fidusen's book](fidusen.md#fidusen--banana-book-vine) but on the neutral special, so there is no
charge. 10 / 0 / 12 (22) frames, on the ground or in the air. On frame 10 a hammer appears at
(14, −16) from his feet, thrown toward his facing side at 20° upward (`projectile_angle_deg`) at
260 px/s, and falls with gravity 600 px/s² (`projectile_gravity`), spinning. Hitbox 10×10;
damage 8, base 130, growth 0.8, angle 40°, launched toward its flight side. **One hammer at a
time** (K does nothing while his hammer is out). It's gone on a hit or a shield, when it lands on
the main platform (it passes through the pass-through platforms), out of the blast zone, or after
120 ticks. It can't hit its owner.

**Up special — ladder** (`up_special.tres` with `ability` → `LadderData`): 6 frames of startup
(no launch), on the ground or in the air; once per stay in the air like the default up special.
- On frame 6 a ladder (14 px wide, 88 px high, its foot at his feet) is set up where he stands
  and he starts to climb: for 16 ticks he moves straight up at 300 px/s (about 80 px; moved with
  physics, so a ceiling stops him), with no gravity and no steering.
- Then he jumps off it: velocity (90 × `move_x`, −280) px/s toward the held direction (straight
  up when nothing is held), and carries on like a launched up special: air steering, gravity,
  `HELPLESS` once he stops rising, ledges can be grabbed while rising.
- The ladder stays 60 ticks after it appeared, then is gone (it goes at once if he's KO'd). It is
  scenery: it has no hitbox, can't be climbed by others and doesn't block anyone.
- No hitbox on the move itself. Getting hit ends the climb (the ladder still stands its time).

**Down special — leaf blower** (`down_special.tres` with `ability` → `BlowerData`): 20 / 12 / 14
(46) frames, on the ground or in the air (no dive). He winds it up for 20 frames (the charge-up),
then a gust hits for 12 frames: hitbox (36, −14), 64×26, **damage 0**, base 260, growth 0 (so it
never grows with the victim's %), angle 8°, FACING. It pushes opponents away and nothing else:
no damage, but they are in hitstun while they fly (a shield blocks it like any hit, for no
damage). Anyone it hits is hit once per use.

**Side special — torch** (`side_special.tres` with `ability` → `TorchData`): a small flamethrower.
8 / 40 / 10 (58) frames, on the ground or in the air (turning toward the held direction first,
like the side special does). For the 40 active frames a hitbox (24, −13), 34×14 is out, and it
hits the same fighter again every 8 ticks (`hit_interval`): damage 2, base 45, growth 0.15,
angle 25°, FACING — a small hit that keeps them in the flames and walks them forward. It doesn't
make a projectile.

**Burning:** the torch sets whoever it hits on fire. A victim starts burning once the flame has
stopped hitting them: when the torch's active frames end (or the move is cut short), or when the
flame missed its next hit on them (no hit for more than `hit_interval` ticks, so they got out of
it). A shield blocks the flame and doesn't burn. Burning lasts 180 ticks (3 s, `burn_ticks`): every
30 ticks (`burn_interval`) they take 1 % (`burn_damage`), so 6 % in all, with no knockback or
hitstun (skipped while they can't be hit). It **doesn't stack**: a fighter burns only once at a
time, and catching fire again while burning restarts the 3 s. A KO puts it out. The burn is a
`Burn` entity (`burn.gd`); the numbers are on `TorchData`.

Files: `characters/kim/moves/` (`moveset.tres`, `jab.tres`, `side_tilt.tres`, `down_tilt.tres`, `hammer_swing.tres`, `axe_swing.tres`, `screwdriver_swing.tres`, `neutral_special.tres`, `hammer.tres`,
`up_special.tres`, `ladder.tres`, `down_special.tres`, `blower.tres`, `side_special.tres`,
`torch.tres`); scripts `hammer_ability.gd`, `hammer_data.gd`, `hammer.gd`, `ladder_ability.gd`,
`ladder_data.gd`, `ladder.gd`, `blower_ability.gd`, `blower_data.gd`, `torch_ability.gd`,
`torch_data.gd`, `burn.gd`, `tool_swing_ability.gd`, `tool_swing_data.gd`, `hose.gd` (the drawn hose; each with a `.uid`).

## Look

Kim keeps his generated body (`assets/fighters/slot_09/`). His tools are drawn by the game in the
same pixel style, kept slim and small next to his body (1 px handles and shafts inside a 1 px
outline, heads and tanks no bigger than his hand to his shoulder), over the body (`FighterAbility.draw()` and the entities' own `_draw()`), so the
shared sprite generator isn't touched:

- **Tools in hand (normals):** drawn by the game over the body for the move's frames, swinging
  from a resting hold, raised for the windup, through the strike and back: a claw hammer (jab),
  a long-handled axe with a steel blade (side tilt: raised high behind him, then chopped down in
  front), a screwdriver with a yellow handle, red stripe and steel shaft (down tilt: drawn back,
  then thrust forward along the floor).
- **Hammer:** a small claw hammer (wooden handle, grey head) that spins while it flies (a turn
  every 24 ticks); a hammer in his hand during the throw's startup.
- **Ladder:** a wooden ladder (two rails, rungs every 8 px) standing at his feet; he draws in
  front of it.
- **Leaf blower:** a backpack blower like a real one: a red engine with a white fuel tank low on his
  back, a black hose over the shoulder to a long black tube in his hands with a red band near its
  end, drawn for the whole move; during the gust white wind lines stream out along the hitbox.
- **Torch:** a weed burner on a propane tank: a black grip and a long steel wand with a burner
  head and a red tip in his hands, a black hose sagging to a white propane tank (brass valve)
  standing on the floor behind him, or carried on his back while he's in the air; during the
  active frames a flame (orange, yellow core) licks out of the burner along the hitbox,
  flickering.
- **Burning:** small flickering flames (the torch's orange and yellow) on the burning fighter's
  body, with a few sparks rising off them, drawn over the fighter; they shrink in the last half
  second.
