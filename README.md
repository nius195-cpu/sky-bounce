# Sky Bounce

A playable offline mobile game made with **Godot 4.6.3 Standard and GDScript**. Drag to move the platform, keep the ball bouncing, and beat your saved high score. The opening pace is gentle, with varied bounce heights that broaden gradually as your score rises. Speed keeps increasing with successful bounces; after five, the platform starts to float vertically. Every 10 points starts a new level with a smoothly changing ball color and matching trail. The star field gently drifts and twinkles.

Choose **Classic Mode** (bottom platform, downward gravity) or **Reverse Mode** (top platform, upward gravity) from the Play menu. Each mode keeps its own high score.

Includes touch controls, gravity and angled rebounds, scoring, increasing difficulty, menus, pause/resume, restart, sound, background pausing, and local high scores. No ads, accounts, or paid libraries.

## Install on your Android phone

1. In the GitHub repository, open **Actions → Build Android installer → Run workflow** and choose `main`.
2. When the build is green, open the run and download the **sky-bounce-android-installer** artifact.
3. Unzip it, transfer **sky-bounce.apk** to your phone, and open it to install. Allow installation from your file app/browser if Android asks.

The workflow also runs on pushes to `main` and pull requests. No release signing or Google Play setup is required. The APK supports Android 7.0+ on ARM64 phones and x86_64 emulators.

See [the Android build guide](docs/ANDROID.md) for toolchain versions, exact build steps, troubleshooting, and phone tests.

## iPhone and iPad

The shared Godot gameplay supports both modes on iOS. An iOS export preset is included; building/installing a native iOS app requires macOS, Xcode, and your Apple development signing setup. See [the iOS guide](docs/IOS.md). The iOS data export is verified; native iPhone/iPad builds have not been tested here.

## Actual Android project

`android/build/` contains the Gradle wrapper, Android build configuration, manifest, and Java activity from Godot's matching official template. The export preset builds an APK using this Gradle project. Large engine binaries are restored automatically with pinned checksums rather than stored in Git.

Use the provided build entry point so the APK contains the game assets as well as the Android shell:

```sh
# With Godot 4.6.3, JDK 17, and the Android SDK installed and configured:
bash tools/build_android.sh
```

Output: `builds/sky-bounce.apk`, signed with a local debug testing key. The build runs the gameplay tests and verifies APK contents and signing before CI uploads the artifact. This testing key is not a production signing key.

## Play on a computer

Download [Godot 4.6.3 Standard](https://godotengine.org/download/archive/4.6.3-stable/), import `project.godot`, and press the Play triangle. Click and drag in the play area; arrow keys also work. P/Escape pauses and Space opens mode selection from the menu or restarts from the game-over screen.

## Gameplay tests

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/run.gd
```

The suite covers physics and game-flow checks, including fast-ball collisions, score handling, difficulty, touch dragging, pause/resume, background pause, and saving high scores. It includes three-minute Classic/Reverse trajectory comparisons across phone and tablet aspect ratios, legacy-score migration, separate score persistence, and Reverse touch/control tests. See [Reverse Mode implementation notes](docs/REVERSE_MODE.md). The suite writes test scores to its runtime user-data folder; use a separate `XDG_DATA_HOME` on Linux to keep desktop play scores separate. Real-device touch, display, and sound testing remains necessary.

## Files

- `project.godot`, `main.tscn`, `scripts/`: the Godot game.
- `android/build/`: the Android Gradle project.
- `export_presets.cfg`: Android APK, optional future Play, and iOS Xcode-project export presets.
- `tools/`: dependency preparation, APK build, and APK-content verification.
- `.github/workflows/android.yml`: automatic and manual debug APK builds.
- `docs/ANDROID.md`: build/install guide.
- `art/`, `docs/`: artwork and optional future publication materials.

Code: MIT. Original artwork: CC0. Godot and its Android template: MIT plus bundled notices. See `LICENSE` and `THIRD_PARTY_NOTICES.md`.
