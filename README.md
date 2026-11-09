# Sky Bounce

Godot **4.6.3 Standard**, GDScript, Android 7.0+. Drag the paddle to keep bouncing in Classic or Reverse Mode. Both modes retain their existing physics, difficulty progression, controls and separate high scores.

## Test on your Android phone

1. Open this repository's **Actions → Build Android installer → Run workflow**.
2. Select **feature/cosmetics-and-google-play**, leave release mode **none**, and run.
3. Download **sky-bounce-android-installer** from the successful run, unzip it, and open **sky-bounce.apk** on your phone. Allow installation from your browser/file manager when asked.

No Play Console or production signing is needed for this debug APK. Install over an older build only if its signing certificate matches; uninstalling deletes local scores and unlocks. Debug builds do not prove Google Play purchases work.

## Cosmetics

Customize from the main menu: five unlockable ball colors, five paddle colors and five backgrounds, plus all original defaults. Permanent free unlocks use the highest score across either mode, with the owner-approved [balanced schedule](docs/play-store/PROGRESSION.md). Equipment is saved immediately; existing scores/settings migrate without reset and saves use a validated temporary file plus backup.

The optional **Sky Bounce Ultimate Style Pack** adds four balls, three paddles and three backgrounds. Product ID: `sky_bounce_style_pack`, intended US base price **$1.99**. The actual purchase button displays the localized Google Play price. No ads, subscriptions, consumables or gameplay advantages. Default ball level colors remain available.

Android uses the maintained GodotGooglePlayBilling 3.3.0 plugin / Play Billing 9.1.0. Completed purchases, pending/cancelled/error states, acknowledgement, ownership reconciliation and restoration are implemented. **Real Play purchases have not been tested.** Product activation, a signed Play-installed test build and license testers are required. Client-side receipt checks are not fraud-proof; an asynchronous server-verification hook is provided. See [billing details](docs/billing/INTEGRATION.md).

Gameplay and previously saved cosmetics work offline. Billing requires Google Play/network access. iOS retains shared gameplay and free cosmetics; Android billing is unavailable there. No Apple in-app purchase implementation is included. Native iOS builds remain untested; see [iOS guide](docs/IOS.md).

## Develop and verify

Import `project.godot` in Godot 4.6.3 Standard and press Play. Desktop supports mouse dragging and arrow keys.

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/run.gd
python3 tools/check_billing_plugin.py
# With JDK 17 and the documented Android SDK:
bash tools/build_android.sh
```

Tests use the application user-data directory: isolate `XDG_DATA_HOME` on Linux to protect desktop play progress. A deliberate corrupt-save test prints a ConfigFile error before successfully recovering from its backup. The final RESULT and exit status determine success.

## Release preparation

Actions supports manual release mode **unsigned** for a release AAB inspection, or **signed** once the three upload-key secrets are configured. Both build the debug APK first. Artifacts include the AAB and verification report. An unsigned AAB cannot be uploaded to Play or installed directly. A signed AAB is for Play; the debug APK is for direct phone installation. Neither workflow publishes anything.

- [Play Console setup and device test checklist](docs/play-store/CONSOLE_SETUP.md)
- [Secure signing and GitHub secrets](docs/play-store/RELEASE_SIGNING.md)
- [Testing evidence and limitations](docs/TESTING.md)
- [Store listing draft](docs/play-store/STORE_LISTING.md), [privacy draft](docs/play-store/PRIVACY.md), [compliance review](docs/play-store/COMPLIANCE.md)
- [Artwork and screenshot instructions](docs/play-store/SCREENSHOTS.md), [release notes](docs/play-store/RELEASE_NOTES.md)
- [Android toolchain details](docs/ANDROID.md), [initial inspection](docs/DEVELOPMENT_AUDIT.md)

Stable application ID: **org.skybounce.keepitup**. Version **1.3.0**, code **6**, target API **36**. Production signing keys/passwords are never committed. Owner review of privacy, SDK data practices, store assets and Play policies is still required; a successful build does not guarantee store approval.

Code MIT; original artwork CC0. See [LICENSE](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md).
