# Mads

Mads's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Mads — grappler

Mads is a grappler: most of his specials are **command grabs**, moves that catch the opponent
instead of hitting them. A grab goes through a shield (that's what it's for), but it's slow to
come out and has a long end lag if it misses. Everything not listed here is the default move set.

**How a command grab works** (shared by all his grabs):
- The move's hitbox is a **grab box**: on its active frames, the first fighter whose hurtbox it
  touches is caught, even while shielding — unless they can't be hit (KO'd, invulnerable,
  intangible) or are already held. A grab box never hits like an attack.
- The caught fighter goes into the `HELD` state (see [fighter](../fighter.md#states)): they can't act,
  aren't moved by physics, and the Match places them each tick. Mads goes into the move's throw
  phase. **Neither of them can be hit** while the throw lasts.
- A miss plays the move out to the end of its recovery.

**Side tilt — lollipop swing** (`side_tilt.tres`): Mads carries a school crossing guard's stop
sign, a "lollipop" (see [art guide](#look)), on his back, and swings it in his side
tilt like Henrik's guitar: 7 / 3 / 10 (20) frames, hitbox (31, −15), 22×14 (fitted to where the
sign is drawn in the strike drawing: it reaches 42 px in front), damage 7, base 160, growth 1.3,
angle 35°, FACING. His other normals are the default ones (the sign stays on his back).

**Down special — stop smash** (`down_special.tres`, `down_special_dive.tres`): Stig's cross smash
(see [Stig](stig.md#down-special--cross-smash)) with his lollipop: the same frames, hitbox, hit, air drop
and burst timing (own copies of the files, so the two can be tuned apart). The lollipop turns into
a stop sign for the smash, and the burst is stop-sign red (see [art guide](#look)).

**Side special — over-the-head slam** (`side_special.tres` with `ability` → `GrabData`):
- **On the ground and in the air.** It turns toward the held side first, like every side special.
  It throws no projectile. In the air he keeps falling while reaching.
- **Reach:** 9 / 4 / 24 (37) frames; he stays put. Grab box (16, −14), 18×24: about one body
  length in front.
- **The throw** (`grab_throw`, 40 frames from the catch): he stands still (in the air he hangs in
  place) and swings the victim over his head, **in his hands the whole way**: the middle of the
  victim's body (16 px above their feet, `held_middle`) follows `path`, keyframes at throw frames
  0, 6, 12, 18 and 24 relative to his feet (x toward the side he faced at the catch), in straight
  lines between them: (12, −16) the catch, (11, −28) lifted in front, (0, −34) overhead, (−9, −30)
  coming down on the far side, (−13, −10) at the slam. These are where his hands are in his throw
  drawings. On frame 15 (`turn_frame`, the victim overhead) **he turns round**, so he slams them
  down in front of him. On frame 24 (`slam_frame`) the victim lands on his feet line, 13 px from
  him on that far side, and is hit by the slam: damage 12, base 220, growth 1.3, angle 60°,
  launched **away from Mads** (they bounce up off the floor and fly). He is free after frame 40.
- **Data:** `MoveData.ability` → `GrabData` (`throw_frames` 40, `turn_frame` 15, `slam_frame` 24,
  `path`, `held_middle` 16, `slam_hit` → a `MoveData` with the slam's hit values). Files:
  `characters/mads/moves/` (`moveset.tres`, `side_special.tres`, `slam.tres`, `slam_hit.tres`).
- **Look** (see [art guide](#look)): his own throw drawings; the victim is drawn in
  their hurt pose behind him (his hands and head in front), turning over round the middle of their
  body as they go (half a turn by the slam, head first onto the floor).

## Look

### Weapon and own drawings

- **Mads's lollipop:** a school crossing guard's stop sign: a white pole (about 2 px thick,
  shaded) with a round sign on top, about 15 px across, yellow-green (214, 226, 74), lit top left
  and shaded bottom right, with a white rim; about 36 px from the foot of the pole to the far edge
  of the sign. He holds it 4 px up from the foot of the pole. On his back it slants like Stig's
  cross (the sign up behind his head). Only his side tilt swings it (Henrik's side tilt poses, never
  pointing below level). His frames are 112×80 like the other weapon carriers.
- **Mads's stop smash** (his `down_special`, 5 drawings, Stig's cross smash poses with the
  lollipop): drawing 1 the lollipop held upright in both hands; 2 lifted, and it has turned into a
  **stop sign**: a red octagon (214, 40, 40), shaded bottom right (166, 26, 30), 21 px across with
  a white rim and **STOP** in white 3×5 pixel letters (1 px apart; the game draws each art pixel
  about 2 screen pixels wide, so they stay readable); 3 and 4 planted, its pole 10 px longer so the
  sign stands above his head; 5 getting up, the lollipop again. His burst (`burst.png`, as Stig's)
  is in stop-sign colors: white core, pale red glow (255, 156, 146), red rim.
  **Facing left:** the game mirrors drawings for facing left, which would mirror the lettering, so
  Mads has a second strip, `fighter_down_special_left.png`: the down special already mirrored but
  with STOP (and the sign's shading) the right way round. Any character may have such a
  `<animation>_left` strip; facing left the game draws it as it is instead of mirroring the usual
  one.
- **Mads's slam** (no weapon, frames stay 64×64). The reach (his `side_special`, 4 drawings):
  reaching forward with both arms out, leaning in (drawings 1–3, so the reach and a miss look the
  same); 4 straightening up. **The throw** has its own strip, `fighter_grab_throw.png` (6
  drawings, only for grapplers): 1 the catch, arms out in front (throw ticks 1–3); 2 lifting, both
  arms up in front (4–8); 3 overhead, leaning back, both arms up beside his head (9–14); 4 turned
  round (he now faces the other way), arms overhead, leaning toward the victim (15–18); 5 the slam,
  bent forward, both arms driven down in front (19–30); 6 straightening up (31–40). The victim's
  `path` (see [moves](#mads--grappler)) is fitted to his front fist in these drawings. The
  victim is drawn in their own `hurt` drawing behind him (`z_index` −1), turned round the middle of
  their body (π × t, head first over him), upright again once thrown.
