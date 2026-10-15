# Android build verification — 2026-10-15

Verified locally with Godot 4.6.3 Standard, Temurin JDK 17.0.20.1, the checked-in Gradle 8.11.1 wrapper, Android SDK 36, Build Tools 36.1.0, and NDK 29.0.14206865.

- `bash tools/build_android.sh`: passed; Gradle `assembleStandardDebug` and the Godot export completed.
- Clean-source verification: a fresh `git archive` containing only committed files also rebuilt and passed APK content/signature validation. Downloaded AARs, generated icons/manifests, and game assets were recreated automatically; the build does not depend on untracked project files.
- Gameplay tests: **25 checks, 0 failures**, including a three-minute rally of 94 bounces.
- APK content validation: passed; includes the actual main scene, game assets, and ARM64 Godot native library.
- `apksigner verify --verbose`: passed, APK Signature Scheme v2.
- `zipalign -c -P 16 4`: passed.
- Android manifest inspection: package `org.skybounce.keepitup`, label `Sky Bounce`, version 1.0.0 (code 1), min SDK 24, target SDK 36, launcher activity present, ARM64 and x86_64 libraries. No requested Android permissions.
- Workflow lint: `actionlint` 1.7.7 passed.
- Python compilation, shell syntax, and Git whitespace checks passed.
- Pinned template installer exercised against the official Android entries; all three template hashes verified.

The generated debug APK is approximately 154 MiB. Its checksum is distributed alongside it. The APK and downloaded engine dependencies are build artifacts, not committed source.

This environment's read-only home directory produces an ADB device-discovery warning and disables Android build metrics. Neither prevented compilation, signature verification, or APK export. No phone is connected, so installation, touch feel, display cutouts, and audio still require a real-device smoke test.

Remote inspection update: the GitHub repository became publicly readable. Its main branch at `f34effc` contained only six root files; gameplay scripts, artwork, tests, Android sources, and the workflow were absent. The complete verified project has been restored on top of that actual main history. GitHub write access was subsequently connected. Hosted build results are available in the repository’s Actions tab; the checks listed above record the local verification.
