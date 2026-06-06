# Shift Panic - Game Vision v1

## One-Line Pitch

Shift Panic is a comedic late-night maintenance panic game where the player survives a shift inside a mysterious, badly patched building by choosing between proper repairs, quick hacks, unreliable coworkers, and increasingly ridiculous disasters.

## Arabic Pitch

أنت موظف مناوبة ليلية في مبنى رسمي غامض ومتهالك. كل شيء فيه مرقع: الكهرباء، التكييف، المياه، المصاعد، الكاميرات، الزملاء، والإدارة. تظهر مشاكل مفهومة ومضحكة تحت ضغط الوقت، واللاعب يحاول ينهي الشفت بأقل خسائر عبر قرارات سريعة: يصلح صح ببطء، أو "يسلك" بسرعة ويدفع الثمن لاحقا.

## Core Promise

The player should look at a situation and think:

> "I know what I should do. I can do this better next time."

Then the building should complicate that decision in a funny, readable way.

## What The Game Is

- A single-player 2D panic-management game.
- A late-night shift simulator with comedy, pressure, and readable chaos.
- A game about temporary fixes, bad tradeoffs, weird coworkers, and post-shift consequences.
- A small but expressive game that can grow through systems, events, tools, and building areas.

## What The Game Is Not

- Not a serious engineering simulator.
- Not a clean SaaS dashboard.
- Not a spreadsheet of meters.
- Not a realistic facility-management tool.
- Not a text-heavy narrative game during active crises.
- Not a huge open-world building exploration game.

## The Fantasy

The player is not saving the planet. The player is trying to survive until morning, keep the building standing, avoid blame, and maybe keep enough dignity to collect the shift pay.

The building should feel:

- Official, mysterious, and underfunded.
- Full of old CRTs, bad wiring, sticky notes, handmade labels, and mismatched systems.
- Like it has been repaired for years by people who had ten seconds and a roll of tape.
- Funny without becoming pure parody.

Working title for the building:

- The Bureau of Unclear Operations
- The Department of Unspecified Tasks
- The General Authority for Unexplained Maintenance

Arabic working flavor:

- مبنى الهيئة العامة للمهام غير المفهومة
- مبنى التشغيل الليلي
- إدارة الأشياء التي لا أحد يعرف مسؤولها

## The Core Mechanic

### Patchwork Decisions

Every meaningful problem should offer a pressure tradeoff:

- Proper repair: slow, safer, often requires a coworker or tool.
- Quick patch: fast, funny, temporary, creates risk later.
- Ignore: saves attention now, but raises panic or creates a larger incident.

The game should not ask "which button fixes this meter?"

It should ask:

> "Do I spend time fixing this correctly, or do I tape it and pray?"

## Core Game Loop

Target full round length: 3 to 5 minutes.

1. Start the night shift.
2. The building begins calm enough to understand.
3. Problems appear in readable clusters.
4. Player inspects, prioritizes, and chooses repairs or patches.
5. Events create domino effects across building systems.
6. Coworkers and interruptions complicate decisions.
7. The final hour becomes a controlled peak of chaos.
8. The shift ends in survival or failure.
9. A funny post-shift report summarizes what happened.
10. Player retries because they believe they can do better.

## Round Structure

### Early Shift

- Teach the current tools and systems.
- One problem at a time.
- Mistakes are recoverable.
- Comedy is small and observational.

### Middle Shift

- Two problems overlap.
- A quick patch from earlier can return as a worse issue.
- Coworkers become useful but imperfect.
- Player starts making priority calls.

### Late Shift

- The building behaves like a stack of bad decisions coming due.
- One larger "peak event" can appear.
- Panic effects rise, but readability remains intact.
- End state should feel earned, not random.

## Systems To Keep Simple

Start with three readable building domains:

- Power: breakers, lights, screens, elevators.
- Cooling: AC, vents, server heat, airflow.
- Water: leaks, buckets, pumps, wet electronics.

These are understandable to non-engineers and create strong domino relationships.

## First Signature Tools

Start with only three physical-feeling tools:

- Duct tape: fast patch, temporary, increases later risk.
- Bucket: catches leaks, must be emptied or moved.
- Hammer / firm knock: fast reset, noisy, may create another fault.

Future tools:

- Screwdriver
- Walkie-talkie
- Manual binder
- Desk fan
- Sticky note
- Spare fuse
- Mop

## First Coworkers

Start with two or three:

- The sleepy guard: handles intruders or external doors, but must be called repeatedly.
- The old plumber: great with water, slow and talks too much.
- The enthusiastic trainee: fast, but may cause collateral damage.

Coworkers should be gameplay modifiers, not long-dialogue characters.

## Event Design Rules

Events should be:

- Understandable in one line.
- Visually or aurally distinct.
- Solvable in more than one way.
- Connected to at least one other system.
- Funny because of timing and consequence, not because of long jokes.

Good event examples:

- AC leak over server rack.
- Forced control-system update.
- Elevator stuck with someone yelling.
- False fire alarm from a bad sensor.
- Water leak creeping toward lower buttons.
- Broken chair causing screen shake.
- Dumb thief stealing copper wires on camera.
- Coffee machine flood slowing a corridor.
- Landline call during a major crisis.

## Comedy Rules

Use:

- Bureaucratic seriousness applied to ridiculous problems.
- Short radio lines.
- Bad labels on buttons and tools.
- Post-shift reports.
- Consequences that feel like the building "remembered" your bad patch.

Avoid:

- Long jokes during active play.
- Meme spam.
- Mean-spirited personal jokes.
- Overly local jokes that block global readability.
- Random chaos that makes the player feel helpless.

## Viral Moments

The most shareable moments should come from gameplay:

- The player patches an AC leak with tape, then it floods the server later.
- The control screen tries to update mid-crisis.
- A family call interrupts a disaster.
- A post-shift report lists absurd achievements.
- The player survives with 1% building integrity and a ridiculous damage bill.

The post-shift report is a core marketing feature, not just a result screen.

## Post-Shift Report Direction

The result screen should eventually look like an official maintenance report or damage invoice:

- Shift status
- Building condition
- Damage bill
- Tools consumed
- Bad decisions remembered
- Coworkers blamed or praised
- One funny administrative note
- Retry button
- Screenshot-friendly layout

Example tone:

> The building remains legally upright. Payroll has approved your shift bonus and deducted six meters of unauthorized tape.

## Progression Philosophy

Progression should be light and expressive.

Do not start with a full shop, currency economy, or large upgrade tree.

Preferred progression path:

1. Add new event types.
2. Add one new tool.
3. Add one coworker.
4. Add one new building area/camera.
5. Add light between-hour perk cards only after the core loop is fun.

Perks should create interesting tradeoffs, not only stat upgrades.

Examples:

- Better tape lasts longer, but leaves residue that blocks sensors.
- New hammer repairs faster, but wakes the guard.
- Strong tea improves focus, but causes more family calls.

## Visual Direction

The current console is only a baseline.

The stronger direction is a late-night maintenance desk:

- Main system screen.
- Small camera/map panel.
- Phone or radio panel.
- Tool tray.
- Alarm feed.
- Result report printer.

The game can use more than one panel or screen if it improves the fantasy. The goal is not "one screen forever"; the goal is controlled readability.

Art style targets:

- Stylized 2D.
- Industrial, worn, humorous.
- Clear silhouettes and icons.
- CRT/terminal flavor without hiding information.
- Physical desk elements that make the UI feel touchable.

## Audio Direction

Audio should sell personality:

- Old phone ring.
- Radio squawk.
- Tape rip.
- Bucket plop.
- Hammer knock.
- Bad printer grind.
- Distant elevator ding.
- Low hum that rises with panic.

Audio cues should be useful first, funny second.

## Current Prototype Role

The current Godot prototype is useful as a pressure and systems baseline:

- Timer
- Meters
- Event director
- Interventions
- Alarm feed
- Result loop
- Retry
- Panic feedback

But it is not the final game identity.

The next work should bend the prototype toward the maintenance-desk fantasy rather than add more abstract meters.

## Next True Vertical Slice

Goal: prove the real game fantasy with a tiny playable slice.

Recommended scope:

- 2 to 3 minute shift.
- Keep current power/cooling/water-like meters or rename them into building systems.
- Add one physical tool: bucket or tape.
- Add one funny event: AC leak over server or forced system update.
- Add one coworker or interruption: sleepy guard or landline call.
- Add post-shift report with one or two generated funny lines.
- Preserve retry.

Success criteria:

- A new player understands what is happening without engineering knowledge.
- At least one decision creates a later consequence.
- The result screen is worth screenshotting.
- The player wants to retry because they see a better plan.

## Design Guardrails

- Every feature must increase either clarity, tension, comedy, or shareability.
- If a feature only adds complexity, cut it.
- Keep text short during active play.
- Let the report screen carry longer comedy.
- Do not add progression before the core shift is fun.
- Do not add more meters before adding physical-feeling actions.
- Do not make chaos random without player-readable causes.

## North Star

Shift Panic should feel like:

> A late-night maintenance desk where every quick fix becomes tomorrow's problem, except tomorrow arrives in thirty seconds.

