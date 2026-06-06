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
- First maintenance desk tool interaction: duct tape and bucket for an AC leak over a server.
- Saudi Arabic interface and feedback pass is being applied on `vertical-slice-v1`.
- Milestone 4 first fun loop pass adds a runtime Situation Panel that tells the player the current problem, why it matters, and which input to try.
- The first AC leak incident starts early, and random system events wait longer so the first choice is readable.
- Milestone 5 desk visual identity pass replaces the cold dashboard look with a procedurally drawn warm wooden maintenance desk: wood grain, coffee stains, sticky notes, cable clutter, corner screws, and tape strips on the edges.
- Milestone 5 also adds interaction animations: alarm slots slide in like printed paper, intervention buttons squish on accept and wobble on reject, and the duct tape and bucket play tear and squash tweens when used.
- Milestone 5 keeps every existing scene node path and logic intact; only StyleBox palettes, two new decorative scripts, and tween calls in three existing controllers were added.
- Milestone 6 pivots the game from dashboard to embodied 2D space. New `scenes/game/desk_room.tscn` (Node2D root) becomes the new main scene. Old `manual_override.tscn` is retained for reference but no longer loaded.
- The new scene contains a procedurally drawn top-down room with floor planks, walls, stains, and physical furniture (desk console, tool rack, radio, wall clock, three wall meters, manager door).
- New `player_character.gd` is a `CharacterBody2D` with WASD/arrow movement, walking bob animation, carry pose, and a slip animation when stopping fast.
- New furniture scripts each `extends Node2D` with `_draw()`: `room_visuals.gd`, `desk_console_object.gd`, `tool_rack_object.gd`, `radio_device.gd`, `wall_clock.gd`, `wall_meter.gd`, `manager_door_object.gd`.
- New `desk_room_controller.gd` orchestrates everything: it owns the existing `FacilityState`, `EventDirector`, `InterventionController`, `AlarmFeedController`, and `AudioFeedbackController` instances, builds the HUD programmatically (integrity, shift clock, carry indicator, alarm feed strip, interaction prompt, action console panel, situation panel, radio popup, result overlay), and handles proximity prompts for the four interactable furniture pieces.
- Input model: WASD / arrows move the player; E interacts with the nearest object in range; F uses the currently carried tool; 1–5 still trigger interventions globally; CTRL+R/W/L/D/A still work as dev shortcuts.
- The old `maintenance_desk_controller.gd` is no longer wired in the new scene; its tool-use logic was inlined into `desk_room_controller.gd` so the tools become physical (pick up at rack with E, use with F). The script is kept in the repo in case future milestones need it.
- `PanicFeedbackController` is intentionally not used in the new scene yet; the CRT-flavored shake and scanlines were dashboard-specific and a redesign is owed before they re-appear.

The user manually reported one Godot parse issue after Epic 1 implementation. It was fixed in:

`a9e315d fix: use Godot control text direction enums`

The user later confirmed the project ran correctly after the maintenance desk preload fix.

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
- Prioritize the Situation Panel as the player's main read. Meters should feel like pressure behind the decision, not the main game.
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
- The in-game UI target has now changed to Saudi Arabic. Keep key labels readable and concise.

## Git Safety

- No destructive Git operations.
- No force push.
- No merge into master without explicit approval.
- Godot `.gd.uid` files should be tracked.
- `.godot/` should remain ignored.
