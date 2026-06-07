# Agent Instructions

## Project Identity

- Project: Shift Panic
- Prototype: Manual Override
- Engine: Godot 4 Standard
- Language: GDScript
- Initial platform: Windows desktop
- Design viewport: 1280 x 720

## Development Rules

- Work only inside the repository.
- Implement only the explicitly approved milestone.
- Stop after every milestone.
- Never continue automatically.
- Prefer typed GDScript.
- Do not use C# or Godot .NET.
- Do not add plugins or editor-extension dependencies.
- Network access and downloads are limited to fetching documented CC0 or public-domain art/audio assets; no other online use.
- Do not add Autoloads unless explicitly approved.
- Do not add backend, analytics, telemetry, accounts, or online services.
- Do not create architecture for unapproved future features.
- Prefer simple composition.
- Keep gameplay state separate from presentation when gameplay work begins.
- Keep the prototype understandable to a non-specialist project owner.

## Git Safety

- Do not push or pull.
- Do not add remotes without explicit approval.
- Do not commit without explicit approval.
- Do not use reset, clean, history rewriting, or destructive checkout commands.
- Always show `git status` and a change summary at the end of a milestone.

## Product Constraints

- Single-player.
- Single-screen top-down maintenance room (the one-screen panic console was the early prototype and has been superseded).
- Saudi Arabic in-game interface by default.
- Arabic planning and discussion are allowed.
- English project names, key labels, and internal identifiers are allowed when useful.
- 2D only. No 3D.
- No multiplayer.
- External art/audio assets are allowed only when CC0 or public-domain, with the source and license recorded in `assets/CREDITS.md`. Prefer in-engine procedural art when it reaches the needed quality.
- Do not let the interface resemble a SaaS dashboard.
- Readability must remain intact during visual panic effects.

## Stop Condition

- The exact next milestone must be explicitly approved by the user.
- Never treat acceptance of one milestone as acceptance of the next.
