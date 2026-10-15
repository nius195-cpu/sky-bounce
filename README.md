# Sky Bounce

A complete, offline portrait game for Android, built with **Godot 4.6.3 Standard** (free, no paid libraries). Drag anywhere below the score to slide the platform. Keep the ball alive. Edge hits steer it; every bounce adds a point and increases speed. After five bounces, the platform begins moving vertically. Speed and movement are capped to keep the game playable.

Includes menus, pause/resume, replay, sound toggle, automatic pause when backgrounded, local high scores, original vector art, synthesized audio, Android export presets, and an Android build workflow.

## Start here — no programming required

**What you have:** the full game source and Android build configuration. **What you do not yet have:** a compiled APK or a signed Play Store bundle. This environment had Godot but no Android SDK/export templates; a network permission request was cancelled. Android compilation and real-device testing could not be completed here. The included cloud build is configured but has not been run here.

### Play on your computer now

1. Download **Godot 4.6.3 Standard** for your computer from https://godotengine.org/download/archive/4.6.3-stable/ (not the .NET edition).
2. Unzip this project. Open Godot, choose **Import**, select `project.godot`, then **Import & Edit**.
3. Press the **Play triangle** at the upper right (or F6/F5 as offered by the editor). Click Play inside the game.
4. Click and drag in the play area to move. Arrow keys also work; P or Escape pauses. Space starts a game from the menu or game-over screen.

### Get an Android installer without setting up Android Studio

Use the included GitHub Actions workflow. This requires a GitHub account; standard Actions allowances generally cover a small public project. Check your account's usage limits.

1. On GitHub, create an empty repository named `sky-bounce`. Choose a public repository if you want to use the public free build allowance. Do not put signing keys or private information in it.
2. In the repository choose **Add file → Upload files**. Upload the **contents** of the unzipped project, including `project.godot`, `main.tscn`, `scripts`, `art`, `tests`, and `export_presets.cfg` at the repository root. The outer `sky-bounce` folder itself should not be at the root.
3. Hidden folders can be missed by file pickers. Ensure `.github/workflows/android.yml` exists in the repository. If necessary, choose **Add file → Create new file**, enter `.github/workflows/android.yml` as the filename, paste the contents of the supplied workflow file, and commit it. This is a file-copy step; no programming changes are needed.
4. Open **Actions → Build Android installer**. The commit starts a build automatically; you can also use **Run workflow**. The first build downloads Godot and the Android tools and may take several minutes.
5. When the run is green, open it and download the **sky-bounce-android-installer** artifact at the bottom. Unzip it to get `sky-bounce.apk`.
6. Send that APK to your Android phone, open it, and allow **Install unknown apps** for that file app/browser when Android prompts. Install and play. The build supports Android 7.0+ on ARM64 phones and x86_64 emulators; old 32-bit-only phones are excluded.

This is a debug APK for testing, not the file to upload to Google Play. Each cloud build generates a new debug signing key. To install a later debug build, you may need to uninstall the previous one first, which deletes its saved score. A stable release signing key is needed for real updates.

If the cloud build fails, its red step contains the error; the cloud build has not been validated in this environment. The local export option below avoids dependence on GitHub Actions.

### Local Android export option

1. Open the project in Godot 4.6.3 Standard. Use **Editor → Manage Export Templates → Download and Install** for the matching 4.6.3 templates.
2. Install Android Studio (free) and JDK 17. In Android Studio's SDK Manager, install Android SDK Platform 36, Platform Tools, Command-line Tools, and Build Tools 35.0.1 (also 36.0.0 for the release Gradle build). Accept the SDK licenses.
3. In Godot **Editor → Editor Settings → Export → Android**, select your Java SDK and Android SDK directories. Use Godot's current Android export instructions if the editor reports a missing dependency: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
4. **Project → Export → Android → Export Project**. Leave **Export With Debug** checked and save to `builds/sky-bounce.apk`. Godot can generate a debug keystore if needed; see its Android export instructions for the debug signing setup.
5. Transfer the APK to your phone and install it as above.

## Before Google Play publication

See [docs/PUBLISHING.md](docs/PUBLISHING.md). Publication requires an account owner and a private signing key. Neither was created here. No store upload, account enrollment, or paid service was performed.

## Tests and verification

From this folder, with Godot 4.6.3 installed:

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/run.gd
```

The suite passed **25 checks** on Godot 4.6.3, including wall and fast-ball collisions, angled rebounds, single-point scoring, bounds, misses, reset, capped speed, vertical motion, menu flow, touch dragging, pause/resume, background pause, and saved scores. A three-minute simulated rally reached 94 bounces after the final physics adjustment. Headless startup also passed. The tests use a synthetic player and do not replace hands-on touch, visual, audio, or Android compatibility testing. Tests write a score of 123 in the test runtime's user data; run with a separate `XDG_DATA_HOME` on Linux to keep desktop play scores separate.

## Project layout

- `scripts/ball_sim.gd`: fixed-step gravity, moving-frame swept collision, difficulty, and scoring.
- `scripts/game.gd`: drawing, touch/keyboard input, menus, audio, and persistence.
- `tests/run.gd`: physics and game-flow checks.
- `export_presets.cfg`: APK testing and Google Play AAB export configurations.
- `.github/workflows/android.yml`: automated debug APK build.
- `art`: original icon and store artwork.
- `docs`: privacy policy draft, store copy, and release checklist.

Code: MIT. Original artwork: CC0. Godot engine: MIT plus its bundled third-party notices; see `THIRD_PARTY_NOTICES.md`.
