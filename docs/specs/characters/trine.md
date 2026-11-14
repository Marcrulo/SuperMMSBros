# Trine

Trine's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Trine — iPad break

Trine's down special: she sits down on the floor and watches her iPad, and her % slowly goes
down. Everything else is the default move set.

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
