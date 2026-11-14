# Gitte

Gitte's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Gitte — scissors and stances

Gitte carries a large pair of scissors on her back (see [art guide](#look)). All
four of her specials are her own; everything else is the default move set.

**Neutral special — scissor cut** (`neutral_special.tres`): charged like the default one (hold K up
to 60 ticks; she holds the scissors out in front, open, while charging), then she snaps them shut:
3 / 4 / 10 (17) frames, hitbox (26, −16), 24×14, damage 8 + 14 × charge, base 200 + 200 × charge,
growth 2.0, angle 38°, FACING. Her charge glow is on the open blades (`charge_glow` (24, −18)).

**Side special — scissor volley** (`side_special.tres`): 10 / 0 / 12 (22) frames; on frame 10 three
small scissors fly out at once from (16, −14), straight, in a fan: 0°, +12° and −12°
(`projectile_count` 3, `projectile_spread_deg` 12), 260 px/s, 90 ticks, hitbox 8×6, each damage 4,
base 90, growth 0.5, angle 30°, launched in their direction. Each can hit once and is gone on a
hit, a shield, the blast zone or its time. No new volley while any of hers is still out. They
spin while flying (her own picture).

**Down special — stance switch** (`down_special.tres` with `stances` → `StanceData`): 15 / 0 / 0
(15) frames, on the ground or in the air (no dive, no hitbox). On frame 8 she switches to the next
stance: `+` → `−` → `÷` → `×` → `+`. She starts every match and every stock in `+`
(`spawn_at()`). The stance shows on her player card ([HUD](../match-and-stage.md#hud)).

| Stance | Effect |
|---|---|
| `+` plus | Her projectiles (the volley) do ×1.5 damage (fixed when thrown). |
| `−` minus | Her normal attacks (jab, tilts, aerials; not B moves) heal her: her % drops by 50 % of the damage each hit deals (not below 0; blocked hits don't heal). |
| `÷` divide | Small: size ×0.75 — sprite, body, hurtbox, move hitboxes (center and size), ledge grab box and hang offset all scale from her feet. Faster: run speed and air speed ×1.25. |
| `×` multiply | Large: size ×1.25 (the same things scale). Her specials (neutral, side, up) do ×1.3 damage and ×1.3 base knockback. |

The numbers live in `StanceData` (`projectile_damage` 1.5, `lifesteal` 0.5, `small_scale` 0.75,
`small_speed` 1.25, `large_scale` 1.25, `large_special` 1.3).

**Up special — pyramid** (`up_special.tres` with `pyramid` → `PyramidData`): a sandstone pyramid
rises out of the ground under her and lifts her up. It needs ground: a strong move on the stage, a
poor recovery off it.

- 4 frames of startup (no launch), on the ground or in the air; once per stay in the air like the
  default up special.
- On frame 4 the Match looks for the floor below her feet (the main platform or a pass-through
  platform: `Stage.floor_below(feet − (0, 1), true)`). If its top is at most 64 px below her feet
  (`reach`) → **pyramid**; otherwise (no floor, or too far) → **hop**.
- **Pyramid:** a pyramid appears at her x on that floor and rises out of it: its tip goes from the
  floor top straight up to 96 px above it (`height`) over 18 ticks (`rise_frames`), at a steady
  speed. She stays at her x; her feet are at the tip, or where they were if the tip hasn't reached
  them yet (in the air she waits, not falling, until it does). She's moved with physics, so a
  solid ceiling would stop her. At the top she pops off: vertical speed −180 px/s (`pop_speed`),
  horizontal `move_x × 80` (drift speed), and carries on like a launched up special: air steering,
  gravity, `HELPLESS` once she stops rising, ledges can be grabbed while rising.
- **The tip hits:** while it rises, a hitbox on the tip: center (0, −10) from the tip, 32×28 (the
  pyramid's, so it doesn't change with her stance size); damage 7, base 160, growth 0.8,
  angle 85°, AWAY (from Gitte's center); each fighter once. × boosts it like her other specials.
- **Hop** (no ground in reach): vertical speed −200 px/s (`hop_speed`), no hitbox, then like the
  launched up special (`HELPLESS` once she stops rising).
- **The pyramid goes:** once she pops off — or when the rise ends early because she's hit or
  KO'd — it sinks back into the floor over 20 ticks (`sink_frames`) and is gone. While sinking it
  has no hitbox and nobody stands on it (it isn't solid at any time; it only carries her). It's
  also gone on `Match.reset()`.
- **Data:** `PyramidData`: `reach` 64, `height` 96, `rise_frames` 18, `pop_speed` 180,
  `hop_speed` 200, `sink_frames` 20, `tip_hit` (a `MoveData`: startup 0, active 18, the hitbox and
  hit values). Her own `up_special.tres` keeps the default's 4 startup frames and drift speed 80,
  with no hitbox of its own (active 0).

Files: `fighter/moves/gitte/` (`moveset.tres`, `neutral_special.tres`, `side_special.tres`,
`down_special.tres`, `stances.tres`, `up_special.tres`, `pyramid.tres`, `pyramid_tip_hit.tres`).

## Look

### Weapon and own drawings

- **Gitte's scissors:** a large pair, about 30 px long: two steel blades (light grey, shaded) on a
  pivot screw, two big red handle loops (about 8 px across, with a visible hole) so they read as
  scissors even small. Her frames are a 112×80 canvas too. On her back they hang closed, diagonally like
  a sword in a back sheath: the handles stick out behind her neck (both loops clearly visible), the
  blades slant down and forward behind her body, and just the tip pokes out in front of her hip. In her neutral special she holds
  them out in front: open while charging (the blades about 40° apart), snapped shut in the strike
  drawing. Her stance switch (`down_special`, 5 drawings) is her own pose: hands crossed in front,
  then flung out wide. Her volley's picture (`projectile.png`): a small pair of scissors, 3
  drawings of 16×16 turned 120° further each.
- **Stances ÷ and ×** draw her frames at ×0.75 / ×1.25 of the usual ¾ size, feet at the origin.

### Gitte's pyramid

`assets/fighters/slot_02/pyramid.png`, one drawing, 168×128, drawn at ¾ (126×96 game px) by the
64 px generator: a **stepped pyramid of sandstone blocks**, not a plain triangle. 8 courses
(rows) of 16 px, each 10 px narrower on both sides than the one below it, with a single capstone
block on top (28 px wide; its top row is the tip she stands on). Every course is a row of
rectangular blocks (about 20–30 px wide, joints staggered from the course below like brickwork),
each block a slightly different sand tone with grainy speckles (lighter and darker pixels), a
light top edge, a darker bottom edge, a 1 px dark-sand joint between blocks, and chipped
(missing) corner pixels so they read as rough-cut stone. The step tops catch the light. The usual
dark outline goes around the whole pyramid. The colors are fixed (sand, not per character).

In the game the drawing's bottom center sits on the floor top, and only the part above the floor
is drawn: rising, it comes up out of the floor, and sinking, it goes back down into it, shaking
1 px left and right every 2 ticks. Drawn behind the fighters, in front of the stage.

Her own **up special** pose (3 drawings): a crouch with the front hand out low over the ground
(calling the pyramid up), then standing with her fist raised forward and up (riding the tip; shown
for the whole rise), then the same with the legs tucked (the pop). Her back arm stays hidden
behind her body in this view, so the poses read through the front arm.
