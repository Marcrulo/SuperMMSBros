# Michael Bech

Michael Bech's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Michael Bech — football

Michael's side special kicks a football (soccer ball) instead of the default projectile. It
works like the [side special](../moves.md#side-special--projectile) (same frames 10 / 0 / 12, one projectile
at a time, passes through platforms and floors, disappears on a hit, a shield, the blast zone or
after 120 ticks), with these differences:

- **It flies at an angle**, in a straight line, toward his facing side: angle 0 is straight ahead,
  positive is upward, between −45° and 45° (`MoveData.aim_cone_deg` = 45).
- **Aimed at the nearest enemy he can see:** on the tick the ball appears, every other fighter
  that isn't KO'd and whose center is on his facing side, within the ±45° cone from the ball and
  at most 200 px from it (`MoveData.aim_range`) counts; the ball flies straight at the nearest
  one's center.
- **Otherwise a random angle** between −45° and 45°, from the Match's seeded RNG.
- It appears at (14, −8) from his feet (at his kicking foot), 240 px/s, hitbox 8×8. Damage 6,
  base 110, growth 0.6, angle 30°, launched in the ball's direction (left or right).
- It spins while flying (its own picture: [art guide](#michaels-football)).
- File: `fighter/moves/michael/side_special.tres`.

A projectile's flight angle is 0 for every other side special (straight ahead, as before).

## Michael Bech — big hand

Michael's neutral special summons a giant white-gloved hand that
hovers in front of him for a second, then slams down. Everything else is the default move set.

- **Summon** (`neutral_special`, no charge): 10 / 0 / 7 (17) frames, on the ground or in the air.
  On frame 10 the hand appears. Then Michael is free again (7 frames of recovery); the hand
  carries on by itself.
- **One hand at a time:** while his hand is out, the K press does nothing (like the projectile).
- **Where:** the hand's palm (the bottom center of its hitbox) appears at (60, −50) from his feet,
  facing side mirrored, and stays at that spot however Michael moves.
- **Hover:** 60 ticks (1 second) in place. Touching it hurts a little: hitbox 28×20 above the
  palm, damage 4, base 100, growth 0.4, angle 45°, AWAY (from the hand's center). It hits each
  fighter at most once while hovering.
- **Slam:** then it drops straight down at 600 px/s, through the pass-through platforms, until
  its palm reaches the main platform (`Stage.floor_below()`), and stays there 8 ticks (the
  impact). While dropping and during the
  impact: damage 14, base 280, growth 1.5, angle 90° (straight up), AWAY. It hits each fighter
  at most once during the slam (a fighter hit by the hover can be hit again by the slam).
- With no main platform under it, it keeps falling and disappears when it leaves the blast zone.
- It disappears after the impact, when Michael is KO'd, or on `Match.reset()`. A shield blocks it
  like a projectile hit (the hand keeps going). It can't hit Michael.
- **Data:** the summon is a `MoveData` whose `hand` points at a `HandData` resource (offset, size,
  hover frames, slam speed, impact frames, `hover_hit` and `slam_hit` as `MoveData` for the hit
  values). Files: `fighter/moves/michael/` (`moveset.tres`, `neutral_special.tres`,
  `hand.tres`, `hand_hover_hit.tres`, `hand_slam_hit.tres`).

## Look

### Michael's football

`assets/fighters/slot_05/projectile.png` (a character's own projectile picture; without one, the
shared `assets/fighters/projectile.png` is used): a black-and-white football, 16×16 per drawing,
3 drawings side by side, each turned a little further (it spins, 4 ticks per drawing, toward its
flight direction). In the 64 px style (outline, shading), drawn at ¾ (12 game px), centered on the
ball's position.

Michael's kick (`side_special`, 4 drawings) is his own: kicking leg back, swinging through,
leg up high in front (the follow-through), back to standing.

### Michael's hand

`assets/fighters/slot_05/hand.png`: his summoned hand, a giant **white glove** drawn by the 64 px
generator (white with grey shading, a rolled cuff, the same outline as the bodies), seen from the
side, palm down, fingers pointing forward, cuff at the back. Two drawings side by side, 56×44
each: **open** (hovering: fingers close together, fanning out slightly, knuckle creases, the
thumb hanging below) and **flat** (slamming: fingers together, palm flat on the bottom row). The palm's bottom center
is at the bottom center of the drawing; drawn at ¾ like the fighters, mirrored to Michael's
facing. While hovering it bobs 1 px every 8 ticks, and a shadow (a dark ellipse) on the floor
below it shows where it will land.

Michael's summon pose (`neutral_special`, 4 drawings) is his own: arm thrown forward and up,
palm open.
