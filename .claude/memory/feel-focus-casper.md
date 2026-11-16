---
name: feel-focus-casper
description: From 2026-11-16 the user's focus is the feel of movement and attacking, tested with Casper (plain default moves)
metadata:
  type: project
---

From 2026-11-16 the user wants to focus on getting the right **feel of movement and attacking** — "just what we are missing". Test and tune with **Casper** (slot_08: default stats `fighter/default_stats.tres` and the default move set, no moves of his own): `godot --path super-mms-bros -- --stage=fc --char=casper --hitboxes` (`--char=<first name|id>` added that day). His opponent stays the default P2 (Gitte) unless the user says otherwise.

**Why:** Casper has nothing character-specific, so changes to shared stats/moves show directly.

**How to apply:** tuning numbers go in resources (FighterStats, MoveData .tres), work on main (not a character branch), ask the user how it feels after each change — Claude can't see the game. See [[project-status]].
