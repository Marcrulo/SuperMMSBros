# Nina

Nina's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Nina — existentialism

Nina's side special and down special are her own; everything else is the default move set.

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

## Down special — lullaby

**Down special — lullaby** (`down_special.tres` with `ability` → `SongData`; phase `song`): she
sings, and everyone near her falls asleep.

- **Start:** Down+B on the ground **or in the air** (it replaces the default burst and dive).
- **Frames:** 20 / 60 / 20 (the move's `startup`, `active`, `recovery`): 100 ticks in all. No
  hitbox, no damage.
- **She stands still:** no walking, turning, jumping or cancelling until it ends. On the ground she
  slides to a stop (ground friction); in the air her sideways speed slows the same way and she
  hovers, sinking at most `hover_fall_speed` (30 px/s; gravity brings her to it). Landing doesn't
  end it.
- **The song:** on each of the active frames (20…79), every other fighter whose hurtbox touches the
  circle of radius `radius` (56 px) around her `voice` point ((0, −16) from her feet; both scale
  with her size) falls asleep, if it can be hit at all (not KO'd, held, invulnerable or
  intangible — a dodge through it is safe). **A shield doesn't protect.** Each fighter falls
  asleep at most once per song.
- **Asleep:** the shared stun (`Fighter.stun()`): dizzy (`SHIELD_BREAK`) for `sleep_ticks` (120,
  2 s), whatever it was doing ends, its shield stays as it was. A hit wakes it (hitstun takes
  over). Asleep in the air, it falls.
- **Data:** `SongData`: `radius`, `voice`, `sleep_ticks`, `hover_fall_speed`.

Files: `characters/nina/moves/down_special.tres`; `characters/nina/song_data.gd`,
`song_ability.gd`, `sleep_mark.gd`.

## Look

- **Pose:** her default side special strip (4 drawings): drawing 0 then 1 while winding up, 2
  (arms thrust out front) for the whole volley, 3 for the recovery.
- **The letters** are drawn by the game, not a sprite: the letter in white with a dark outline,
  about 10 px tall, in the engine's fallback font, centered on the hitbox. The letter never turns.
- **Singing:** her down special strip (5 drawings): 0 a breath in (hands rising to her chest,
  eyes open) for the startup, then 1, 2, 3 swaying back, upright, forward (hands clasped at her
  chest, head up, eyes shut, mouth a round "O"), shown 1, 2, 3, 2, … 10 ticks each for the active
  frames, and 4 (hands lowering) for the recovery.
- **Notes** (drawn by the game, over her): during the active frames little pixel music notes (♪,
  a head, a stem and a flag, in four soft colors, dark outline) float out of her mouth upward and
  to both sides (never down into the floor), drifting and bobbing out to the song's radius and fading there, so you can see how
  far it reaches. A new note every 5 ticks.
- **Asleep:** the sleeper's own dizzy animation, with a `SleepMark` (an entity drawn by the game)
  over its head: three "z"s, one after another, each drifting up and to the side, growing and fading, white with
  a dark outline, for as long as it sleeps.
