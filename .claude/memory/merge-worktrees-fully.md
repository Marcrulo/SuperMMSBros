---
name: merge-worktrees-fully
description: When asked to merge worktrees/branches to main, commit any uncommitted work in them and merge it too — don't stop to ask
metadata:
  type: feedback
---

When the user asks to make sure worktrees/branches are merged to main (and then cleaned up), uncommitted work found in a worktree is part of the request: commit it on its branch (shared files in a `shared:` commit), merge main into it, regenerate sprites, run the full suite, merge into main, push — then remove the worktree.

**Why:** on 2026-11-15 I found Nina's uncommitted lullaby and asked what to do; the user answered "That is why i ask you to merge it first!"

**How to apply:** only stop if the merge truly can't be done safely (conflicts you can't resolve, failing tests) — then report that instead of asking up front. See [[project-status]].
