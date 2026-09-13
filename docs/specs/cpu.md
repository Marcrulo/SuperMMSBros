# CPU Opponent

A hand-written, beatable AI. It is also meant to be the first sparring partner for a trained AI
later, so it plays by the same rules a trained agent would.

## Rules the CPU follows

- It is a `Controller` (see [architecture](architecture.md)): each tick it returns a `FighterInput`
  and nothing else.
- It decides using only the `MatchSnapshot`. It never reads fighter nodes, the other controller or
  the keyboard.
- Any randomness uses the Match's seeded RNG, so CPU matches are repeatable.

## Settings (`CpuSettings` resource)

| Setting | Value | Meaning |
|---|---|---|
| `reaction_delay_frames` | 10 | The CPU decides from the snapshot this many ticks old |
| `attack_chance` | 0.7 | Chance to attack when an attack opportunity comes up |
| `hesitation_frames` | 12 | After a failed attack roll, wait this long before rolling again |
| `attack_range_x` | 24 | Opponent center within this many px in front of the CPU's center… |
| `attack_range_y` | 16 | …and within this many px vertically counts as "in range" |
| `chase_dead_zone` | 8 | Don't move if horizontally closer than this |
| `height_threshold` | 20 | Vertical difference that counts as "above" or "below" |
| `edge_margin` | 8 | How close to the main platform edge the CPU is willing to walk |

## Reaction delay

The CPU keeps the last `reaction_delay_frames + 1` snapshots and decides from the oldest one. It
sees everything — including itself — slightly in the past, like a human reacting. Until the buffer
is full (the start of the countdown), it uses the oldest snapshot it has. `reset()` clears the
buffer.

## Decision rules

Each tick, the CPU goes down this list and uses the **first** rule that applies. "Self" and
"opponent" refer to the delayed snapshot. Rules that need the opponent are skipped while the
opponent is `KO`.

1. **Recover.** If self is airborne and off stage (center x outside the main platform, or feet below
   the main platform top):
   - hold toward the stage center;
   - press jump if `jumps_left > 0`, falling (velocity y > 0) and feet below the main platform top.
2. **Attack.** If self can act (`IDLE`, `RUN`, `AIR`), the opponent isn't invulnerable, and the
   opponent is in range in front of self:
   - roll the RNG against `attack_chance` (only if not hesitating);
   - success → press attack; failure → hesitate for `hesitation_frames`.
3. **Turn around.** If self is on the ground and the opponent is in range but *behind* self: tap
   toward the opponent to turn.
4. **Chase.**
   - Horizontal: hold toward the opponent unless within `chase_dead_zone`.
   - Opponent's feet more than `height_threshold` above self and self on the ground → press jump.
     While rising and still below the opponent, press jump again for the double jump.
   - Opponent's feet more than `height_threshold` below self and self standing on a pass-through
     platform → press down.
5. **Don't fall off.** Applied on top of the chosen movement: when standing on the main platform,
   never move past `edge_margin` from its edge (clamp `move_x` to 0 there). The CPU never leaves the
   stage on purpose in v1.
6. **Otherwise** stand still.

Pressing a button means setting its `*_pressed` field for one tick; to press the same button
again, the CPU must release it for at least one tick first (like a human).

## Later

- Difficulty levels (tune `reaction_delay_frames`, `attack_chance`, `hesitation_frames`).
- Edge-guarding: following opponents off stage.
- Using platforms tactically, spacing, shielding once shields exist.
- A trained agent (`AgentController`) plugging into the same slot, trained against this CPU.
