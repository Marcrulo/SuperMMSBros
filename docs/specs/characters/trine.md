# Trine

Trine's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

Trine's neutral, side and down specials are her own; everything else is the default move set.

## Trine — bun pitch

**Neutral special — bun pitch** (`neutral_special.tres` with `ability` → `BunData`): she winds up
like a baseball pitcher and throws a bun (bolle) straight ahead; the longer she winds up, the
faster and harder it flies.

- **Windup:** the default [charge](../moves.md#neutral-special--charged-punch) (phase
  `neutral_special_charge`), but up to **120 ticks** (2 s, `charge_frames`). On the ground she
  slides to a stop; in the air she keeps falling and steering. The bun in her hand glows brighter
  as the charge grows (`charge_glow` on the bun). Getting hit loses the charge.
- **Throw:** releasing K, or reaching the full charge, starts the throw with
  `charge = ticks charged / 120` (0…1): 4 / 0 / 13 (17) frames, no hitbox of her own. On frame 4
  the bun leaves her hand at (14, −16) (`hitbox_center`), flying straight toward her facing side
  (no gravity) at 200 + 320 × charge px/s (`BunData.speed_min` 200, `speed_max` 520).
- **The bun:** 8×8 (`hitbox_size`), damage 4 + 12 × charge (`damage`, `charge_damage`), base
  knockback 60 + 200 × charge (`base_knockback`, `charge_knockback`), growth 1.4, angle 35°,
  launched in its flying direction. It hits once and is gone on a hit, a shield, the blast zone
  or after 120 ticks (`projectile_lifetime`). It flies through the stage and platforms. A KO of
  Trine removes it.
- **One bun at a time:** while hers is still out, the neutral special can't be started (the K
  press does nothing).
- **Data:** `BunData` (`speed_min`, `speed_max`); everything else is the move's own fields.
  Files: `characters/trine/bun_data.gd`, `bun_ability.gd`, `bun.gd`.

## Trine — banana peel throw

**Side special — banana peel throw** (`side_special.tres` with `ability` → `PeelThrowData`): she
tosses a banana peel in a short arc. It hits like a light projectile; if it misses and lands, it
lies there as a trap, exactly like [Fidusen's peel](fidusen.md#fidusen--banana-book-vine).

- **Start:** Side+B on the ground or in the air; she turns toward the held direction first.
  10 / 0 / 12 (22) frames, no hitbox of her own. On frame 10 the peel leaves her hand at (14, −16).
- **Flight:** 150 px/s at 40° upward (`projectile_speed`, `projectile_angle_deg`), gravity
  700 px/s² (`projectile_gravity`), spinning; on flat ground it comes down about 60 px in front of
  her. Rising it passes through everything; falling, it lands on the first floor it reaches (the
  main platform or a pass-through platform).
- **A hit in flight:** hitbox 10×8, damage 4, base 80, growth 0.4, angle 30°, launched in its
  flying direction (a normal hit, no trip). A hit or a shield uses the peel up (no trap).
- **Landing:** where it lands it becomes a trap peel (a `Peel`, Fidusen's): lasts 600 ticks,
  trips the first other fighter on the ground who touches it (3 %, `TRIPPED` 45 ticks), never
  trips Trine, and airborne fighters are safe. Its numbers are Trine's own `PeelData`
  (`moves/peel.tres`).
- **Limits:** one thrown peel in the air at a time (side special can't start while it's out);
  **up to 2** trap peels of hers (`max_out`): a third removes her oldest. Out of the blast zone
  or after 180 ticks in the air (`projectile_lifetime`) it's gone. A KO of Trine removes a peel in
  flight; her traps stay.
- **Data:** `PeelThrowData` (`trap` → a `PeelData`); flight and hit are the move's own fields.
  Files: `characters/trine/peel_throw_data.gd`, `peel_throw_ability.gd`, `thrown_peel.gd`.
  The trap is Fidusen's `Peel` (`characters/fidusen/peel.gd`), so that file is shared by both.

## Trine — iPad break

Trine's down special: she sits down on the floor and watches her iPad, and her % slowly goes
down.

- **On the ground only.** In the air the K press (with down held) does nothing.
- **Sitting down** (`down_special`, 10 / 0 / 12 frames, no hitbox): on frame 10 she's seated and
  starts watching (`ipad_watch`).
- **Watching** lasts while down stays held, up to 300 ticks (5 s, `watch_frames`). Every 10 ticks
  of watching (`heal_every`) her % drops by 1 (`heal`), not below 0, so one full sit heals 30 %.
- **Getting up** (`ipad_stand`): releasing down, or reaching 300 ticks, starts the move's 12
  recovery frames; then she's free.
- While sitting, watching and getting up she can't move, turn, attack, jump or shield (on the
  ground she only slides to a stop). That's the price for healing.
- **A hit ends it** at once (like any move: the hit lands normally); so does slipping on a banana
  peel. Should the floor go from under her, she falls (`AIR`).
- **Data:** `MoveData.ability` → `IpadData` (`watch_frames` 300, `heal_every` 10, `heal` 1.0).
  Files: `characters/trine/moves/` (`moveset.tres`, `down_special.tres`, `ipad.tres`).
- **Look:** see [art guide](#look). While watching, a small green "+" floats up
  above her head after each heal.

## Look

### Weapon and own drawings

- **Bun pitch** (her `neutral_special_charge`, 2 drawings, and `neutral_special`, 4 drawings).
  **The bun:** a round Danish bolle, 6×5 in her hand, golden brown with a lighter top and a pale
  floury bottom edge. **Windup** (a pitcher's set stance): side-on, leaning back, her front knee
  lifted, the bun cocked back behind her head in the front hand, the back arm reaching forward
  for balance; the two drawings differ by a pixel (knee higher, arm further back) and alternate
  every 6 ticks. **Throw:** 0 still cocked (the bun in hand); 1 arm whipped forward and down,
  leaning in, front foot planted (the bun gone); 2 follow-through; 3 standing. The charge glow is
  on the bun (`charge_glow`).
  `assets/fighters/slot_03/projectile.png`: the flying bun, 3 drawings of 10×10, turned 120°
  further each (it spins).
- **Banana peel throw** (her `side_special`, 4 drawings): 0 the arm down and back with a peel
  dangling from the fist; 1 the same, swung further back; 2 an underhand toss, arm forward and up
  (the peel gone); 3 standing. `assets/fighters/slot_03/peel.png`: the trap peel, Fidusen's
  drawing (16×8). The peel in flight is that same picture, spinning.
- **Trine's iPad and coffee** (her `down_special`, 5 drawings; no weapon otherwise, frames stay
  64×64). **The iPad** stands on the floor in front of her feet on a kickstand, leaning back away
  from her, its screen turned to her, so we see its back: a 6×11 aluminium slab (lit top right,
  shaded bottom left), a dark camera dot near the top, a 1 px line of pale blue screen light along
  the edge facing her, the kickstand a thin line down behind it. **The screen's light** tints her
  face and hair blue (90, 175, 255), strongest near the screen and fading out over ~28 px
  (outlines untouched), a little stronger in the watching drawings. **The mug:** white, 4×5 with
  a shaded side and bottom and a handle toward her, in her front hand; at her chest it shows the
  coffee on top and a 2-pixel wisp of steam (the wisp shifts between the two watching drawings);
  for a sip it's tipped up to her lips (rim at her mouth, foot down and forward, a 7×6 tilted
  shape), her fist under its foot and her arm raised in front of her face, eyes closed. Her back hand rests on the floor behind
  her. Drawings: 1 bending down (mug in hand); 2 seated, legs out in front, watching, mug at her
  chest; 3 the same, the steam and light shifted, leaning a pixel; 4 sipping (head up a pixel, eyes closed);
  5 getting up (like 1). Sitting down shows 1 then 2 (5 ticks each). While she watches: 2 and 3
  alternate every 15 ticks for 30 ticks, then 4 for 30 ticks (a sip), round after round (a sip
  every second, half the time). Getting
  up shows 5.
  The heal "+" (presentation only): green (99, 199, 77) with a dark outline, 5×5 px, rising
  12 px above her head and fading over 20 ticks after each heal.
