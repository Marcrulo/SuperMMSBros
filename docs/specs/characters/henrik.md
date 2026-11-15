# Henrik

Henrik's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Henrik — guitar

Henrik carries an acoustic guitar on his back (see [art guide](#look)). Three moves swing it and
his down special plays it; everything else is the default move set, with the guitar staying on his
back.

| Move | Frames | Hitbox center, size | Damage | Base, growth | Angle | Direction | Idea |
|---|---|---|---|---|---|---|---|
| Jab | 4 / 3 / 7 (14) | (18, −10), 20×12 | 3 | 120, 0.8 | 30° | FACING | Light, quick low swing, holding the neck halfway down (choked up); a little more reach than a punch |
| Side tilt | 7 / 3 / 10 (20) | (29, −16), 24×12 | 7 | 160, 1.3 | 35° | FACING | Light swing at arm's length, holding the end of the neck: long reach, a bit weaker than the default kick |
| Neutral special | 3 / 4 / 10 (17), charge 60 | (20, −30), 40×24 | 8 + 14 × charge | 200 + 200 × charge, 2.0 | 45° | FACING | Charged overhead swing: he raises the guitar behind his head while charging, then brings it over his head and down in front, hitting above and in front |

The hitboxes cover where the guitar is drawn in each move's strike drawing (jab reaches 28 px,
side tilt 41, the overhead swing 40 and up to 42 px above the feet). His charge glow is on the
raised guitar's body, `charge_glow` (−21, −45).

**Down special — speaker jam** (`down_special.tres` with `ability` → `SpeakerData`): Henrik
swings his guitar round to the front and plays; a loudspeaker pops up on each side of him and
blasts whoever stands next to them away to the side on every beat.

- **On the ground:** 12 frames of startup (the guitar comes round from his back; no hitbox of his
  own). On frame 12 his move becomes the phase `speaker_jam` and two speakers appear, one on each
  side, their centers 26 px (`offset`) left and right of his x, standing on his feet's height.
- **In the air:** the default dive (with its spike); landing turns it into the jam's startup (from
  frame 0) instead of the ground burst.
- **The jam** lasts 72 ticks (`jam_frames`) and then 12 more (`end_frames`, lowering the guitar)
  before he can act. He stands still (slides to a stop) and can be hit; a hit (or a KO) ends the
  jam at once.
- **Beats:** on jam ticks 6, 24, 42 and 60 (`first_beat` 6, then every `beat_every` 18 while
  under `jam_frames`) each speaker blasts for 4 ticks (`blast_frames`): a hitbox from the
  speaker outward (center (20, −12) from the speaker's foot, 52×24, mirrored for the left speaker,
  so it starts 6 px inside the speaker: someone touching Henrik is hit). The hit (`blast`, a
  `MoveData`): damage 3, base 260, growth 0.6, angle 15°, always launched away from Henrik (the
  speaker's side). Each blast hits each fighter at most once; a shield blocks it. Each beat makes
  the `burst` sound (`Match.owner_sound`).
- **The speakers go:** once the jam's 72 ticks are over, or as soon as his jam ends early (hit,
  KO), they stop blasting and sink into the floor over 8 ticks (`sink_frames`). They aren't solid
  and can't be hit. Gone with him on a KO and on `Match.reset()`.
- **Data:** `SpeakerData`: `offset` 26, `jam_frames` 72, `end_frames` 12, `first_beat` 6,
  `beat_every` 18, `blast_frames` 4, `sink_frames` 8, `blast` (`MoveData`, the hitbox and hit
  above). His own `down_special.tres`: startup 12, active 0, recovery 1 (never reached: the jam
  starts on frame 12), `dive_speed` 360 (the air dive's).

Files: `characters/henrik/moves/` (`moveset.tres` + `jab.tres`, `side_tilt.tres`,
`neutral_special.tres`, `down_special.tres`, `speakers.tres`, `speaker_blast.tres`);
`characters/henrik/speaker_data.gd`, `speaker_ability.gd`, `speaker.gd`.

## Look

### Weapon and own drawings

- **Henrik's guitar:** acoustic, natural wood top with a dark sound hole, a brown neck and
  headstock, about 35 px long. On his back it's slung close: the body pressed against his back,
  the neck rising behind his head on the back side. In jab, side tilt and the neutral special his own poses swing it (held
  by the neck); in every other animation it stays on his back.
- His move hitboxes are fitted to where the guitar is drawn in the strike drawing (see
  [moves](#henrik--guitar)).
- **Playing pose** (his own `down_special`, 5 drawings): 0 the guitar swung round in front (startup);
  1 and 2 playing — the guitar across his belly, held with the front (near) fist on the sound hole,
  strumming (1 high, 2 low), the neck pointing forward and up; the far arm reaches forward from
  behind his body, so only its fist shows, fretting the neck past his chest (two arms only);
  3 the beat — a big downstroke, leaning back, head up;
  4 lowering it (the end). In the game: drawing 0 for the startup; in the jam drawing 3 while a
  blast is out, otherwise 1 and 2 swapping every 4 ticks; drawing 4 for `end_frames`.

### Henrik's speakers

`assets/fighters/slot_06/speaker.png`, 2 drawings of 24×32, drawn at ¾ (18×24 game px) with the
bottom center on the speaker's foot: a black loudspeaker cabinet (dark grey with a lighter top
edge and the usual dark outline, small silver corner caps), seen from the front: a small round
tweeter near the top, a big woofer below (dark surround ring, grey cone, dark dust cap in the
middle). Drawing 0 at rest, drawing 1 on the beat (the woofer cone pushed out: lighter and 1 px
bigger). The colors are fixed (not per character). Shown on drawing 1 while a blast is out.

The game draws the sound: while a blast is out, 3 arcs (`)` shapes, white with a dark edge)
spread out from the woofer away from Henrik across the blast's hitbox. Popping up it rises out of
the floor over 4 ticks; sinking, it goes back down. Drawn behind the fighters, in front of the
stage.
