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
- Milestone 6 follow-up (commit `07ffba3`) added `server_leak_object.gd`, made the AC leak readable in space, gated console keys 1-5 by desk proximity, and split tool pickup into E for bucket / Q for tape so the safe-vs-fast tradeoff is explicit.
- Milestone 7 strips the tutorial UI excess from the previous pass (mission panel, on-floor objective arrow, pulsing ring, labelled tool/desk zones) and replaces it with game feel. The world now narrates itself instead of overlay text.
- Milestone 7 adds a `Camera2D` and an offset-based shake controller wired into leak start (medium), tape failure (strong), patch/bucket use (light), manual override (strong), normal intervention (light), win (light) and loss (heavy).
- Server leak now uses two `GPUParticles2D` instances — falling drip from the AC unit and an upward splash on the rack base — driven by a single procedurally generated soft-circle `ImageTexture`. The hand-drawn drip in `_draw_ac_unit` and the duplicate drop loop in `_draw_puddle` were removed.
- A growing wet puddle now lives on `server_leak_object`. Radius grows while leaking, shrinks otherwise, and the controller polls `is_in_puddle(world_pos)` each frame. When the player enters the puddle at speed they slip via `PlayerCharacter.apply_external_slip()`, drop any carried tool, and trigger a shake plus the new SLIP audio cue.
- `audio_feedback_controller.gd` gained `_make_layered_tone` and `_make_layered_two_tone` and rebuilt every cue as fundamental + harmonic mixes. New cues: `DRIP` (loops every ~0.62 s while a leak is active), `SLIP` (descending whoop), and `CLOCK_TICK` (used by the intro cinematic).
- Opening cinematic (`_build_intro_overlay` + `_play_intro_cinematic`) fades a "01:30 صباحاً — استلام المناوبة" title in/out over ~3 s while pausing the simulation; uses a `Tween` chain for sequence + parallel fade.
- Result screen pops in with a `Tween` that scales the panel from a squashed 5 % height to 100 % with `TRANS_BACK` ease and fades alpha from 0 to 1 over 0.45 s, then focuses the retry button.

## Milestone 8 — Industrial Rebuild (visual overhaul)

- `AGENTS.md` was updated with the user's explicit permission: external CC0 / public-domain assets are now allowed when recorded in `assets/CREDITS.md`, the "one-screen panic console" constraint is marked superseded by the top-down room, and the network rule is narrowed to "downloads limited to documented CC0 assets". `assets/CREDITS.md` was created and currently lists no external assets — all art and audio remain procedural.
- The user's direction: the wooden floor felt depressing and the server room did not read as a server room; they asked for a stronger, more realistic visual level and gave broad freedom to redesign. After testing, in-engine downloads of Kenney packs proved unreliable (protected behind itch.io/JS), so this milestone delivers the jump with procedural shaders + real 2D lighting under full control. Bringing in CC0/AI sprite assets is deferred to a possible M9 if the procedural result is not enough.
- New `shaders/concrete_floor.gdshader`: a `canvas_item` shader with value-noise FBM concrete, tile grout grid, per-tile shade variance, dirt stains, and a yellow-black hazard band at `hazard_x` (server-room threshold). Applied via a `ShaderMaterial` on a new `FloorShader` ColorRect at `z_index = -20`.
- New `scripts/lighting_rig.gd` (`Lighting` node): builds a `CanvasModulate` (cool night tint `0.52, 0.54, 0.66`) plus seven `PointLight2D` fixtures sharing one procedurally generated radial `GradientTexture2D`. Three ceiling fluorescents flicker via `_process` (slow sine + buzz + occasional dip). HUD is on a separate `CanvasLayer`, so it is unaffected by the tint and lights.
- Shadows: chose painted blob shadows under furniture over `LightOccluder2D` to keep the look clean and low-risk; the occluder task was intentionally folded into existing per-object shadows.
- `room_visuals.gd` fully rewritten: no longer paints the floor (the shader does). Now draws concrete walls with cinder-block seams, grime speckles, ceiling pipes with brackets, a left-wall breaker panel, Arabic safety signs, wall outlets, and the server-room partition + cooler floor tint. `z_index = -10`.
- `server_leak_object.gd` rebuilt: three server racks (`_draw_rack`) side by side with mounted units, vent slits, LCD screens, status LEDs, and spinning fan grilles. The centre rack sits under the AC box and is the damaged one — its screens/LEDs turn amber while leaking and red after tape failure. Particle, puddle, slip, and state logic are preserved; offsets were retuned for the new layout.
- `desk_console_object.gd` rebuilt into a workstation: 3/4-view CRT with scrolling terminal bars, a side oscilloscope screen, keyboard, mouse, steaming mug, a stack of papers, and a desk lamp that paints a warm light pool. The tool rack was left as-is for now.
- Renderer note: the project uses `gl_compatibility`. 2D lights, `CanvasModulate`, and canvas-item shaders are supported there. Light/CanvasModulate balance (the `NIGHT_TINT` value and per-light `energy`) is the most likely thing to need runtime tuning — readability must stay intact per the project rules.

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
