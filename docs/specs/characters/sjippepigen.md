# Sjippepigen

Sjippepigen's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Sjippepigen — jump ropes

Sjippepigen fights only with her three jump ropes (one per pair of arms). She has **no attacks**:
the attack button does nothing, and of the specials only neutral special (the frenzy, her
finisher), down special (it switches the rope length) and up special (the lasso, her recovery)
work. She can still move, jump, shield, dodge and
grab ledges.

- **The ropes always spin** while she can act (and while attacking, hanging, helpless): not while
  she's in `HITSTUN`, `TRIPPED`, `SHIELD_BREAK`, `HELD` or `KO`, and not while she shields or
  dodges (`SHIELD`, `SHIELD_DROP`, `SPOT_DODGE`, `ROLL`, `AIR_DODGE`), nor during her up special
  (see below): then they neither spin, hurt nor show. Each rope
  sweeps round her like skipping: over her head, down in front, under her feet and up behind.
  Rope i's angle after `rope_tick` ticks of spinning: θ = 2π × (`rope_tick` / period + i / 3)
  (the three are a third of a turn apart); the far end of its loop (**the tip**) is at her body
  middle (0, −14) + (sin θ × rx × facing, −cos θ × ry). `rope_tick` counts only while the ropes
  spin, and restarts at 0 on every spawn.
- **Short** (her length at every spawn): rx 18, ry 24 px, a turn every 30 ticks. **Long:** rx 34,
  ry 34 px, a turn every 48 ticks.
- **The hit:** only the tip hurts: a 10×10 box centered on it. A tip touching a fighter that can
  be hit hits them (a shield blocks it like any hit); each rope hits a given fighter at most once
  per turn of that rope, and a fighter takes at most one rope hit per tick. **Rope immunity:** a
  fighter hurt by a rope can't be hurt by any rope for 30 ticks, counting the tick of the hit
  (`immune_frames`; counted down by the Match like respawn invulnerability; a blocked rope gives none), so the ropes can't stack hits. Launched away from her
  (by which side of her middle the victim's middle is). The short ropes hit harder, the long ones
  reach further: short damage 3, base 110, growth 1.0, angle 40°; long damage 2, base 60, growth
  0.4, angle 40°.
- **Down special — switch length** (`down_special.tres`, `RopeData.down_special_switches` on): 6 / 0 / 6 (12) frames,
  on the ground or in the air (no dive, no hitbox): on frame 6 the ropes switch between short and
  long (a switch forgets which turns already hit).
- **Data:** `MoveSet.ability` → `RopeData` (`count` 3, `center`, `short_radius`, `long_radius`,
  `short_period`, `long_period`, `tip_size`, `immune_frames`, `short_hit` and `long_hit` as
  `MoveData`, `frenzy_frames`, `frenzy_speed`, `frenzy_hit`, `frenzy_charge_knockback`,
  `down_special_switches` and `neutral_special_frenzy` on, `frenzy_min_charge_frames` 20; her
  `neutral_special.tres` and `frenzy_hit.tres`); the `RopeAbility`. Files: `characters/sjippepigen/moves/`
  (`moveset.tres`, `down_special.tres`, `ropes.tres`, `rope_short_hit.tres`, `rope_long_hit.tres`,
  `up_special.tres`, `lasso.tres`, `lasso_hit.tres`).
- **Look:** the game draws each rope as seen from the side while skipping: **from one hand of its
  pair of arms** (rope 1 the main pair, ropes 2 and 3 the extra pairs) out round its tip and back
  to the pair's other hand: a rounded loop (at u from 0 to π: the point between the hands at
  (1 − cos u) / 2, plus (tip − the hands' midpoint) × sin u, plus sideways half the loop's length ×
  sin u cos u so it swells out either side, plus a lag of 0.4 × (the path point 0.6 rad behind the
  tip − the tip) × sin² u, bowing it back the way it came), 1 px of color inside a 3 px dark
  outline; plus a faint streak (35 % opacity) along the tip's path for 0.9 rad behind it. The hands' positions in every
  drawing come from `assets/fighters/slot_12/hands.json` (written by the sprite generator: per
  animation, per drawing, per pair the front and back fist, game px from the feet facing right).
  Her ropes are her own patina green: rope 1 (120, 128, 80), rope 2 lighter (146, 156, 100), rope 3
  darker (92, 100, 60) (`CharacterData.rope_colors`; a character without them would get red,
  blue, yellow).
- **Neutral special — frenzy** (`neutral_special.tres`, `RopeData.neutral_special_frenzy` on): charged like the
  default neutral special (hold K up to 60 ticks; on the ground she slides to a stop, in the air she
  keeps falling; her ropes keep spinning normally meanwhile), but releasing it doesn't punch: a
  3 / 0 / 8 (11) frame release with no hitbox. **Let go before 20 ticks of charging
  (`frenzy_min_charge_frames`) and nothing more happens; otherwise the frenzy** starts: for 120 ticks
  (`frenzy_frames`; she's free to act after the release) her ropes spin twice as fast
  (`frenzy_speed`; the ropes' turn grows by speed / period each tick, so a speed change doesn't make
  them jump) and every rope hit is the frenzy hit instead: **damage 0**, base 150 + 200 × the charge
  (0…1; `frenzy_charge_knockback`), growth 1.6, angle 40° (`frenzy_hit`), so it's her way to
  knock people off the stage at high %. Rope immunity, shields and both lengths work as usual. No
  new charge while a frenzy is on. **The frenzy meter** (shown on her player card, see
  [HUD](../match-and-stage.md#hud)): empty at every spawn, it refills over 720 ticks (12 s;
  `frenzy_refill_frames`), not during a frenzy; the charge can only be started with a full meter,
  and starting a frenzy empties it (a tap that starts none costs nothing). Drawn: the ropes lit up (each color lightened 45 %). **While
  charging** (not the punch glow): her ropes light up gradually (lightened 45 % × the charge), and a
  ring 5 px in radius 44 px above her feet (3 px dark outline) fills clockwise from the top in her
  first rope color: dimmed and see-through before 20 ticks, lightened after, flashing white (4 ticks
  on, 4 off) when full.
- **Up special — lasso** (`up_special.tres` with `ability` → `VineData`, `lasso.tres`): Fidusen's vine
  (see [Fidusen](fidusen.md#fidusen--banana-book-vine), the same numbers) thrown as a rope, with an air grab
  added. On frame 6 the Match picks, in this order: a free **ledge** in reach (as the vine) → pulled
  to it and hangs; else the nearest **opponent** that can be hit and isn't held, whose center is at
  most 100 px (`grab_range`) from hers and not behind her (behind = more than 8 px on her back side
  and not more than 8 px above her) → **lasso**: they're `HELD` and reeled in, in a straight line
  over 12 ticks (`reel_frames`), to 16 px in front of her feet (`reel_to`), while she hangs in place
  and neither can be hit; then they're hit (damage 7, base 160, growth 1.0, angle 45°, launched
  forward), get 30 ticks of rope immunity, and she pops up at 260 px/s (`pop_speed`) like a launched
  up special (`HELPLESS` once she stops rising); else → **a miss** (no swing from above: it only
  catches a ledge or an opponent; `swing` false): the rope flies out toward 100 px at 45° up and
  forward and back over 18 ticks (`miss_frames`) while she falls and steers as usual; then she's
  free (`AIR`), her up special used until she lands. The rope is drawn like the vine, in her first
  rope color. **Her jump ropes rest** (no spinning, no hits, not drawn) for the whole up special:
  the throw, the pull, the reel and the miss (and while rising from a lasso's pop).

## Look

### Weapon and own drawings

- **Sjippepigen's idle** is skipping on the spot (her ropes always spin): 4 drawings, landing
  (knees bent), a hop (her feet 4 px off the floor, toes down), landing, a hop with the other foot
  leading; her hands down by her hips, where the rope handles are. Her **run** skips along the
  same way: the run's strides with a hop in each (landing, 5 px up, coming down), hands by her hips.

### Sjippepigen's arms

Sjippepigen has **3 pairs of arms** (`arm_pairs=3` in `tools/fighter64_looks.py`). The main pair
is drawn as usual (sleeves of her dress); the two extra pairs are bare (her bronze-green skin),
start just below the shoulders (1.5 px lower per pair) and copy the main arms' pose, evenly
fanned from the main arm toward a limit: out toward the horizontal, or down toward hanging when
the main arm is already out in front; a raised main arm's extras step back down to the
horizontal. An extra arm (and its forearm) never points above the horizontal unless the main arm
is raised, so no arm goes up on its own. Visual only: her hurtbox and moves are the
default ones.
