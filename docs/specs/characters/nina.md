# Nina

Nina's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Nina — existentialism

Nina's side special is her own; everything else is the default move set.

**Side special — letter volley** (`side_special.tres` with `ability` → `LetterData`; phase
`letters`): she shoots the letters of **E-K-S-I-S-T-E-N-T-I-A-L-I-S-M-E** (16, `text`) out of her
hands, one after the other, each flying straight ahead.

- **Start:** Side+B on the ground **or in the air**. She turns toward the held direction first,
  and the volley goes that way.
- **Frames:** 10 / 0 / 16 (the move's `startup`, `active`, `recovery`). Letter *k* (0 = E) leaves
  on frame 10 + 6 × *k* (`interval` 6), so the last E is on frame 100 and the move ends on frame
  116. No hitbox of her own.
- **Direction locked:** her facing can't change until the move ends (no turning, however she
  steers).
- **She can still move around:** held left/right steers her the whole time. On the ground she walks
  at half her run speed (`walk_scale` 0.5, with her ground acceleration; walking off an edge makes
  her fall); in the air she steers and falls as usual (air speed, gravity, fast fall). Landing
  from the air doesn't end it. She can't attack until it ends.
- **Jump:** pressing jump launches her without ending the move: a ground jump (full height,
  `jump_velocity`) or, in the air, a double jump while she has one left (`double_jump_velocity`,
  sideways speed from the held direction, one double jump used). She keeps shooting, her facing
  stays locked, and she steers in the air as above. With no double jump left the press does
  nothing.
- **Cancel:** pressing shield (shielding on the ground; an air dodge in the air while it's
  available) **ends the move on that tick** and does what the press asks, as if she had been
  standing free: the shield (from which roll and spot dodge work as usual), the roll or spot
  dodge when pressed together with the shield, or the air dodge. A press that can't do anything
  (air dodge used, shield broken) does nothing and the volley goes on. The letters already out
  keep flying; no more come.
- **Hands:** the letters leave alternately from her front hand (`hand` (14, −16), the move's
  `hitbox_center`) and her back hand (`back_hand` (4, −12)), starting with the front hand. Positions
  scale with her size like any hitbox.
- **Each letter:** 240 px/s (`projectile_speed`), 50 ticks (`projectile_lifetime`), hitbox 8×10,
  damage 2, base 70, growth 0.4, angle 25°, launched in its flying direction. It hits once and is
  gone on a hit, a shield, the blast zone or its time. Letters already out keep flying when she's
  hit (a KO removes them). They fly through the stage.
- **No limit** on letters in the air (a second volley can follow the first).
- **Data:** `LetterData`: `text`, `interval`, `walk_scale`, `back_hand`. The letter's size, damage,
  speed and knockback are the move's own `hitbox_size`, `damage`, `base_knockback`,
  `knockback_growth`, `angle_deg`, `projectile_speed`, `projectile_lifetime`.

Files: `characters/nina/moves/` (`moveset.tres`, `side_special.tres`, `letters.tres`);
`characters/nina/letter_data.gd`, `letter_ability.gd`, `letter.gd`.

## Look

- **Pose:** her default side special strip (4 drawings): drawing 0 then 1 while winding up, 2
  (arms thrust out front) for the whole volley, 3 for the recovery.
- **The letters** are drawn by the game, not a sprite: the letter in white with a dark outline,
  about 10 px tall, in the engine's fallback font, centered on the hitbox. The letter never turns.
