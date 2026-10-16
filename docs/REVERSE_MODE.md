# Reverse Mode implementation and verification

## Inspection and design

The project has one main scene (`main.tscn`), one game controller/drawing script (`scripts/game.gd`), and one physics model (`scripts/ball_sim.gd`). Gravity, bounce-height variation, score-dependent speed, swept paddle collisions, wall reflection, vertical platform movement, and loss detection all live in the physics model. Saves originally used one `game/best` key in `user://progress.cfg`. Touch input already uses Godot's cross-platform screen-touch and drag events.

The safest implementation keeps `ball_sim.gd` **byte-for-byte unchanged** from version 1.1.1 (Git blob `7b0bdbf74645b3a057cf349ce87ca706095a2cd6`). A small `PlaySession` adapter owns that model and exposes screen coordinates:

- Classic returns the model's positions and velocities directly and delegates simulation unchanged.
- Reverse maps positions with `y = screen_height - y` and velocities with `vy = -vy`. Horizontal positions, velocities, and touch targets stay unchanged.
- The same physics step runs in both modes. World-space gravity is upward in Reverse, rebounds travel downward, the platform floats in the mirrored direction, and the Classic bottom-exit loss becomes a top-exit loss.
- The Reverse platform body is drawn **above** its collision plane, so the ball hits its visible underside. Its normal bottom reflection boundary becomes a lower boundary above the bottom HUD.

There are no duplicate gameplay scenes or second copies of the physics algorithm. Colors, trail, glow, particles, sound, score progression, and background animation remain shared.

## Menus, controls, and scores

Play opens a mode selector with Classic Mode and Reverse Mode. Classic keeps its original in-game HUD positions and touch area. Reverse puts the HUD/pause button at the bottom and accepts drags in the playfield above it, including near the top platform. Horizontal dragging has the same direction in both modes. Restart/replay retains the selected mode; changing modes starts a fresh round and clears old trails/touches.

The config save has `scores/classic` and `scores/reverse` keys. Existing `game/best` migrates to Classic, with Reverse starting at zero. Saving retains `game/best` as the Classic best for backwards compatibility, writes both independent scores, and preserves the shared sound preference. No account, network access, or platform-specific storage API is added.

## Verification

The automated suite passes **85 checks**. It retains the original 43 checks and adds:

- Three-minute comparisons at 480×800, 480×1040, and 768×1024. Classic state is exactly equal to the original physics model at every step; Reverse state mirrors it. Seeded random bounce heights, side-wall impacts, scoring, and higher-score platform movement are included.
- Upward acceleration, underside/edge/fast collisions, downward rebound, no duplicate points, bottom reflection, and top-exit loss.
- Both menu choices, actual Reverse platform movement from touch input, HUD touch exclusion, pause, background pause, restart, and replay.
- Legacy save migration, an actual Reverse bounce updating only its own best, independent scores across mode changes, and persistence/reload.
- Existing level colors and star/pause animation behavior.

Godot's **iOS game-data pack export** succeeds using the iOS preset. This verifies resource packaging, not a native iPhone build. The same core scene and scripts contain no Android-only runtime code. Real Android/iOS touch, safe-area/cutout, audio, and performance tests still need hardware.

See `IOS.md` for the native iPhone/iPad export requirements. Android APK results are in GitHub Actions.
