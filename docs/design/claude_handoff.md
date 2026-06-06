# Claude Code Handoff - Shift Panic

## Current Branch

Work is currently on:

`vertical-slice-v1`

Do not merge into `master`.
Do not push unless the user explicitly approves.

## Current State

The repository contains a Godot 4 Standard prototype for Shift Panic.

Completed locally on the feature branch:

- Godot bootstrap.
- Static panic console.
- Deterministic facility simulation.
- Intervention buttons and cooldowns.
- Event director and dynamic alarm feed.
- Playable round loop with survival/loss result overlay.
- Retry support.
- Procedural local audio cues.
- Restrained visual panic feedback.

The user manually reported one Godot parse issue after Epic 1 implementation. It was fixed in:

`a9e315d fix: use Godot control text direction enums`

Runtime validation after that fix is still pending unless the user reports otherwise.

## Important Vision Update

The old prototype goal was "one-screen panic console."

The stronger product vision is now:

Shift Panic is a comedic late-night maintenance panic game about surviving a shift inside a mysterious, badly patched building. The player uses proper repairs, quick patches, unreliable coworkers, and simple tools to handle readable disasters.

Read first:

`docs/design/game_vision_v1.md`

## Product Direction

Do not treat the current console as the final game.

Treat it as a useful systems prototype that should evolve toward:

- A late-night maintenance desk.
- Physical-feeling tools.
- Building systems that non-engineers understand.
- Funny but readable problems.
- A post-shift report worth screenshotting.

## Key Design Principles

- The game should be easy to understand and hard to master.
- Comedy comes from timing, consequence, and bureaucracy, not long jokes.
- Every quick patch should create a readable later risk.
- Avoid dashboard-like gameplay.
- Avoid engineering jargon.
- Avoid large scope expansion before the core loop is fun.
- Active play should feel smarter than passive play.
- The player should believe they can do better next run.

## First Real Vertical Slice Direction

Recommended next design/implementation target:

- 2 to 3 minute shift.
- Keep retry and result loop.
- Add one physical tool such as tape or bucket.
- Add one readable event such as AC leak over server.
- Add one interruption or coworker such as sleepy guard or landline call.
- Add post-shift report lines that remember what happened.

Do not add:

- Full shop.
- Currency economy.
- Large upgrade tree.
- Many coworkers.
- Many tools.
- Main menu.
- Save system.
- Multiplayer.
- External assets.

## Collaboration Notes

The user is not an experienced game developer. They test builds in Godot and provide runtime observations.

When implementing:

- Keep steps testable.
- Report exact manual test instructions.
- Do not claim visual or runtime validation unless the user reports it.
- Prefer small, high-confidence changes.
- Keep Arabic planning acceptable, but in-game UI remains English unless explicitly changed.

## Git Safety

- No destructive Git operations.
- No force push.
- No merge into master without explicit approval.
- Godot `.gd.uid` files should be tracked.
- `.godot/` should remain ignored.

