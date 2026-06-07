# Shift Panic

Shift Panic is a single-player Godot game about surviving a late-night shift as the last maintenance worker in a collapsing building. Visible problems (leaks, fires, electrical sparks) appear faster and faster — run between them, hold to fix the nearest one, and survive as long as you can before the building falls and hands you a screenshot-worthy verdict.

Current status: `Milestone 9 - Design Reset / قلب اللعب الجديد` pending manual Godot runtime validation.

## The Loop (new core, Milestone 9)

The abstract three-meter simulation was replaced with one readable loop:

- **One health bar:** building integrity, drained by the combined danger of every active problem.
- **Visible problems:** leaks, fires, and sparks spawn around the room, each drawn distinctly with particles and a floating "!" that grows with severity.
- **One verb:** run to a problem (WASD) and hold SPACE to fill its fix ring. Walk away and the progress slips.
- **Escalation:** problems spawn faster and skew toward fire/spark the longer you last.
- **Screenshot verdict:** when health hits zero, an end card shows how long you survived, how many you fixed, the worst simultaneous chaos, and a comedic rating.

The earlier dashboard/console build is kept at `scenes/game/desk_room.tscn` for reference but is no longer the main scene.

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
- First leak incident supports an explicit safe-vs-fast choice: bucket with E or duct tape with Q at the tool rack.
- Visible server room with its own partition wall, doorway, and bureaucratic sign so the leak has a readable place.
- HUD shrinks to the essentials: integrity, shift clock, carried tool, alarm feed strip, and a context-sensitive interaction prompt.
- Manager door tease with rotating sleep-related lines on knock attempts.
- All existing simulation systems (facility state, event director, intervention controller, alarm feed, audio) are reused unchanged by the new scene.
- Visible AC unit dripping over the server with GPU-driven water particles and splash, replacing the prototype hand-drawn drip.
- Growing wet puddle on the server room floor that expands while leaking and shrinks once patched or caught.
- Player slips when running through the puddle, drops any carried tool, and triggers a camera shake.
- Camera2D with offset shake on leak start, tape failure, manual override, tool application, win, and loss.
- Layered procedural audio: button clicks, alarms, win and loss now mix fundamental + harmonic frequencies, plus new drip, slip, and clock tick cues.
- Opening cinematic fades in "01:30 صباحاً — استلام المناوبة" with a clock tick before play starts.
- Result screen springs in with a back-eased scale and modulate tween for a printed-paper feel.
- Procedural industrial concrete floor shader with tile grout, mottling, stains, and a yellow-black hazard stripe at the server-room threshold (replaces the flat wooden planks).
- Real 2D lighting: a cool-night CanvasModulate plus PointLight2D fixtures — flickering ceiling fluorescents, a warm desk lamp, cold server-room glow, a tool-rack pool of light, and a dim red over the manager door.
- Concrete walls with cinder-block seams, grime speckles, horizontal pipes with brackets, a metal breaker panel, Arabic safety signs, and wall outlets.
- Server room rebuilt as three believable server racks: mounted units, vent slits, small LCD screens, status LEDs, spinning fan grilles, and an AC box overhead; the damaged centre rack reads red/amber under the leak.
- Console upgraded into a workstation: chunky CRT with scrolling terminal text, a side oscilloscope monitor, keyboard, mouse, coffee mug with steam, scattered papers, and a desk lamp casting a warm pool of light.
- Project rules in `AGENTS.md` updated to allow documented CC0 / public-domain external assets; `assets/CREDITS.md` tracks them (currently none — all art and audio remain procedural).

## Not Implemented Yet

- Automated tests.
- External assets.
- Main menu.
- Settings.
- Additional game modes.

Next unapproved epic or milestone: not approved.
