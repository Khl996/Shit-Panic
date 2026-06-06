# Shift Panic

Shift Panic: Manual Override is a single-player Godot prototype about surviving a late-night maintenance shift in a mysterious building. The current branch builds a local vertical slice with live systems, readable disasters, intervention choices, maintenance tools, win/loss, retry, panic feedback, and procedural audio cues.

Current status: `Milestone 6 - تمشي / Walk The Room` pending manual Godot runtime validation.

Engine requirement: Godot 4 Standard.

## Open Manually

1. Open Godot Project Manager.
2. Import or scan the current folder.
3. Open the project.
4. Run the Main Scene, or press F6/F5 as appropriate.

## Implemented Scope

- Minimal Godot project configuration.
- Valid Main Scene at `scenes/main.tscn`.
- Static console composition.
- Saudi Arabic in-game interface pass.
- Saudi-style action feedback and alarm wording.
- Runtime Situation Panel that explains the current problem and suggested inputs.
- Faster first readable incident: AC drip starts early in the round.
- Random system events are delayed so the first moment teaches one clear choice.
- 90-second live countdown.
- Deterministic live facility simulation.
- Dynamic Temperature, Pressure, and Power Load.
- Dynamic meters, states, and trends.
- Dynamic Facility Integrity.
- Internal panic-level calculation.
- Internal reset foundation.
- Running and time-expired states.
- Functional intervention buttons.
- Physical keyboard shortcuts 1-5.
- Five intervention tradeoffs.
- Independent cooldowns.
- Temporary Reroute cooling penalty.
- System Reset foundation.
- Manual Override with two uses.
- Global control lock.
- Action feedback.
- Reset foundation for intervention state.
- Deterministic event director with fixed seed support.
- Shift phase event scheduling.
- Cooling failure, pressure spike, and power surge events.
- Sensor signal loss events.
- Temporary jammed control events.
- Dynamic alarm feed with active and recently resolved entries.
- System Reset clearing resettable control faults.
- Survival and facility-loss outcomes.
- Result overlay with final round statistics.
- Retry without reloading the scene.
- Restrained panic visual feedback.
- Procedural local audio cues.
- Development-only validation controls behind `development_controls_enabled`.
- Maintenance Desk tool tray.
- AC drip over server incident.
- Duct tape quick patch with delayed failure risk.
- Bucket safe response for the first leak incident.
- Post-shift report lines for maintenance tools.
- Updated project rules for Saudi Arabic interface direction.
- Permanent project rules in `AGENTS.md`.
- Godot-appropriate `.gitignore`.
- Procedurally drawn maintenance desk background with warm wood surface, wood grain, coffee stains, cable clutter, corner screws, and scattered sticky notes.
- Procedurally drawn desk decorations layer with tape strips on corners and side margins.
- Warmer panel and button palette with intentionally uneven borders and corner radii to sell the patchwork feel.
- Animated paper-style alarm slots with scale and fade slide-in on each new bulletin.
- Animated intervention buttons with squish on accept and wobble on reject.
- Animated maintenance tools with tape rip rotation and bucket squash on use.
- New top-down 2D maintenance room with procedural floor planks, walls, stains, and an embodied player character.
- Player avatar walks with WASD or arrow keys, animates while walking, and slips when stopping suddenly.
- Wall colliders and desk collider stop the player from passing through furniture.
- Physical furniture in the room: maintenance desk console, tool rack with tape and bucket, blinking radio, wall clock, three wall meters (temp/pressure/power), and the manager door with its sign.
- Proximity prompts (E key) for the desk console, tool rack, radio device, and manager door.
- Action console panel appears automatically when the player stands near the desk and hides when they walk away.
- Tools become physical: pick up tape or bucket at the rack with E, then press F near the leak to apply.
- HUD shrinks to the essentials: integrity, shift clock, carried tool, alarm feed strip, and a context-sensitive interaction prompt.
- Manager door tease with rotating sleep-related lines on knock attempts.
- All existing simulation systems (facility state, event director, intervention controller, alarm feed, audio) are reused unchanged by the new scene.

## Not Implemented Yet

- Automated tests.
- External assets.
- Main menu.
- Settings.
- Additional game modes.

Next unapproved epic or milestone: not approved.
