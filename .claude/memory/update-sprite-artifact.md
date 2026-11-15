---
name: update-sprite-artifact
description: After any sprite or in-game visual change, rebuild and republish the "Super MMS Bros Sprites" artifact without being asked — show visuals there, not as scratchpad PNGs
metadata:
  type: feedback
---

Whenever fighter sprites change — or anything the game draws itself that the user should see (e.g. Sjippepigen's ropes) — rebuild the sprite viewer and republish it to the existing artifact (https://claude.ai/artifact/XRYHSjknF5r3s7bXcQWqgt) in the same turn. Don't wait to be asked, and don't point the user at scratchpad PNG mock-ups instead.

**Why:** the user reviews visuals in that artifact ("you should update artifact when changing sprites"; "update claude artifact if you want to show me sprites").

**How to apply:** `python3 -I tools/sprite_viewer/rope_strips.py super-mms-bros <scratch>/previews` (game-drawn previews: rope_preview_short/long.png), then `python3 -I tools/sprite_viewer/build.py super-mms-bros/assets/fighters <scratch>/sprites.html <scratch>/previews`, then publish (same file path / url). For new game-drawn effects, add a preview generator + an EXTRAS entry in build.py. Pairs with [[check-every-frame]].
