# Android debug APK builds

## Framework and build structure

Sky Bounce is a native **Godot 4.6.3 Standard / GDScript** project. `project.godot` defines the game, `main.tscn` launches it, and `scripts/*.gd` implement gameplay. There is no web application, Node dependency tree, Capacitor project, or web wrapper to install.

The real Android project is under `android/build/`:

- `build.gradle`, `settings.gradle`, `config.gradle`, and `gradle.properties` declare the Android app and dependencies.
- `gradlew`, `gradlew.bat`, and `gradle/wrapper/*` provide Gradle **8.11.1**, with the distribution checksum pinned.
- `src/main/AndroidManifest.xml` and `src/main/java/com/godot/game/GodotApp.java` provide the Godot Android activity. Godot updates the manifest, icons, localized title, and other resources from the export preset before compiling.
- `android/.build_version` pins the Android template to `4.6.3.stable`; `android/.gdignore` prevents Android build outputs from being imported into the game.
- `libs/debug/godot-lib.template_debug.aar` is an engine dependency restored by `tools/prepare_android.py`; the >100MB binary is intentionally not committed. The helper also restores the matching release AAR required by the official template's other build variants. Each download has a pinned SHA256.

The Android export preset uses **Gradle**, **APK**, and **debug signing**. Godot stages the actual game files into Android assets and invokes the checked-in wrapper's `assembleStandardDebug` task. Running bare `gradlew assembleDebug` without first staging the Godot assets can create an empty app shell; use `tools/build_android.sh` instead.

The previous supplied project ignored all of `android/` and used a prebuilt-template export. A Gradle-based CI cache or build step therefore could not find wrapper properties or build files. The Android project is now included, and only downloaded binaries, local settings, and generated outputs are ignored.

## Toolchain

The versions come from Godot 4.6.3's official Android template:

| Component | Version |
| --- | --- |
| Godot Standard | 4.6.3 |
| JDK | 17 recommended; newer compatible JDKs can work |
| Gradle wrapper | 8.11.1 |
| Android Gradle Plugin | 8.6.1 |
| Kotlin plugin | 2.1.21 |
| Android compile / target SDK | 36 |
| Android minimum SDK | 24 (Android 7.0) |
| Android Build Tools | 36.1.0 |
| NDK | 29.0.14206865 |
| APK architectures | ARM64 and x86_64 |

AndroidX dependencies are declared by the checked-in official template. `android.suppressUnsupportedCompileSdk=36` acknowledges AGP 8.6.1's tested-SDK warning while preserving Godot's matching toolchain. Release publishing is outside this debug workflow.

## GitHub Actions: download an APK

After these files are on `main`:

1. Open the repository's **Actions** tab.
2. Select **Build Android installer**.
3. Click **Run workflow**, select **main**, then **Run workflow** again. It also builds on pushes to main and pull requests.
4. Wait for the job to turn green. The first run downloads the engine, Android SDK/NDK, and Gradle dependencies; later runs reuse caches.
5. Open the run. Under **Artifacts**, download **sky-bounce-android-installer**.
6. Unzip the download. It contains **sky-bounce.apk** and its SHA256 checksum. Do not try to install the ZIP or checksum file.
7. Transfer `sky-bounce.apk` to your phone and tap it. Permit **Install unknown apps** for the browser or file manager if Android requests it. Open **Sky Bounce** after installation.

No Play Console account, production keystore, release signing setup, or GitHub secrets are needed. The APK is signed automatically with a testing key. The workflow caches that key to support updating testing installs, but cache eviction or cache isolation can still change it. If Android says an update conflicts with an existing package, uninstall the older testing build and install the new APK (uninstalling deletes its saved score). Keep a stable private key later if long-term upgrade continuity matters.

Artifacts expire after 14 days. Run the workflow again if the download is no longer available. Phones must support ARM64; 32-bit-only ARM devices are not included.

## Local Linux build

Install Godot 4.6.3 Standard, a JDK, and Android command-line tools first. Set `JAVA_HOME` to the JDK directory and `ANDROID_HOME` to the SDK directory. Accept the SDK licenses with `sdkmanager --licenses`, then install:

```sh
sdkmanager 'platform-tools' 'platforms;android-36' 'build-tools;36.1.0' 'ndk;29.0.14206865'
bash tools/build_android.sh
```

The output is `builds/sky-bounce.apk`. `GODOT_BIN` may select a non-default Godot executable. `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `ANDROID_USER_HOME`, and `GRADLE_USER_HOME` can point to writable directories in restricted environments. Any required HTTP proxy or custom Java trust store belongs in the local environment, not in the repository.

The preparation helper restores the Android entries from the official Godot template distribution, verifies pinned checksums, restores the engine libraries, and creates a local testing keystore if needed. Downloads stream only the Android portion of the large distribution. A dedicated settings file under `.godot/android-config/` configures export without overwriting the user's normal editor settings. Gradle and native dependencies are downloaded by their normal SDK/Gradle tools.

The build script imports resources, runs gameplay tests, exports the APK, checks for the main scene and Godot engine inside it, verifies its signature, and writes its checksum. It fails instead of uploading an unsigned or empty shell.

For USB installation (USB debugging enabled):

```sh
adb install -r builds/sky-bounce.apk
adb shell am start -n org.skybounce.keepitup/com.godot.game.GodotAppLauncher
```

## Phone smoke test

Start a game, drag left/right, score at least five bounces to see vertical movement, miss and restart, pause/resume, switch apps and return, toggle sound, and close/reopen to verify the high score. Check that buttons are clear of screen cutouts and gesture controls. A compiled and signature-verified APK still requires this real-device test.
