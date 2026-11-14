# Henrik

Henrik's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Henrik — guitar

Henrik carries an acoustic guitar on his back (see [art guide](#look)). Three moves swing it;
everything else is the default move set, with the guitar staying on his back.

| Move | Frames | Hitbox center, size | Damage | Base, growth | Angle | Direction | Idea |
|---|---|---|---|---|---|---|---|
| Jab | 4 / 3 / 7 (14) | (18, −10), 20×12 | 3 | 120, 0.8 | 30° | FACING | Light, quick low swing, holding the neck halfway down (choked up); a little more reach than a punch |
| Side tilt | 7 / 3 / 10 (20) | (29, −16), 24×12 | 7 | 160, 1.3 | 35° | FACING | Light swing at arm's length, holding the end of the neck: long reach, a bit weaker than the default kick |
| Neutral special | 3 / 4 / 10 (17), charge 60 | (20, −30), 40×24 | 8 + 14 × charge | 200 + 200 × charge, 2.0 | 45° | FACING | Charged overhead swing: he raises the guitar behind his head while charging, then brings it over his head and down in front, hitting above and in front |

The hitboxes cover where the guitar is drawn in each move's strike drawing (jab reaches 28 px,
side tilt 41, the overhead swing 40 and up to 42 px above the feet). His charge glow is on the
raised guitar's body, `charge_glow` (−21, −45).

Files: `fighter/moves/henrik/` (`moveset.tres` + `jab.tres`, `side_tilt.tres`,
`neutral_special.tres`).

## Look

### Weapon and own drawings

- **Henrik's guitar:** acoustic, natural wood top with a dark sound hole, a brown neck and
  headstock, about 35 px long. On his back it's slung close: the body pressed against his back,
  the neck rising behind his head on the back side. In jab, side tilt and the neutral special his own poses swing it (held
  by the neck); in every other animation it stays on his back.
- His move hitboxes are fitted to where the guitar is drawn in the strike drawing (see
  [moves](#henrik--guitar)).
