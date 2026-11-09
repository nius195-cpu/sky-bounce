# Cosmetics and Google Play audit

Starting point: existing repository `nius195-cpu/sky-bounce`, main commit `b57d77b83c925d76986e55a59f5c3076d3f3d3f9`, version 1.2.1. Work is isolated on `feature/cosmetics-and-google-play`; main is not modified.

- Engine: Godot 4.6.3 Standard, GDScript, native Compatibility renderer.
- Structure: one `main.tscn` scene; `game.gd` handles menus, touch, rendering, audio and saves. `ball_sim.gd` is the Classic physics model; `play_session.gd` projects it vertically for Reverse Mode. Both physics files remain unchanged.
- Scoring: one point for each swept platform collision. Ball speed and randomized bounce heights scale with score; platform vertical movement begins after five points. No score currency or consumable economy exists.
- Rendering: lightweight procedural CanvasItem shapes; original ball changes color every ten points, mint paddle, moving star field. No external art packs, cosmetic ownership, selection, or monetization existed.
- Saves: `user://progress.cfg`, legacy `game/best`, mode-specific `scores/classic` and `scores/reverse`, and `game/sound`. Migration retains all of those keys. New cosmetic state is a separate section. Writes now validate a temporary config, preserve a valid backup, and atomically rename it into place.
- Score verification: new progression is fed by successful collision results from the shared simulation and migrated local best scores, never by a purchase or UI text entry. This is local gameplay validation, not server-authoritative anti-cheat; local saves can be modified on a compromised device.
- Android: stable ID `org.skybounce.keepitup`, target/compile API 36, min API 24, ARM64 and debug x86_64, official Godot Gradle template, wrapper 8.11.1 / AGP 8.6.1 / Kotlin 2.1.21. Existing Android and future Play presets; iOS project preset is retained.
- CI: `.github/workflows/android.yml` validates/imports, runs the test suite, builds a signed debug APK, checks its content/signature and uploads it. It is retained and extended, not replaced by an unrelated framework.
- Dependencies: original Godot engine/template and its AndroidX dependencies; no ads, analytics, accounts or billing plugin at baseline. Original baseline tests: 133 checks passed locally.

## Progression assessment

The exact requested 10–1,000 reward thresholds are the current default. A deterministic perfect-play simulation reached 1,000 in 917.2 seconds (about 15 minutes); this is an expert endurance target, not a measured human completion time. An alternative schedule was proposed before changing the requested progression: 10, 20, 30, 40, 50, 65, 80, 100, 125, 150, 175, 200, 250, 300, 350. No balancing change is made without the owner's choice.

## Free-system validation milestone

182 automated checks pass, including the original gameplay/mirror/menu checks, all exact unlock boundaries, locked equipment rejection, save migration and restart persistence, atomic save replacement and corrupt-primary backup recovery, customization controls, and immediate ball appearance. The corrupt-save recovery test intentionally exercises Godot's config parser error diagnostic.
