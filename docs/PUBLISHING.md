# Publication checklist for the owner

The debug APK now builds with the checked-in Android Gradle project; see ANDROID.md and BUILD_RESULTS.md. Gameplay tests, APK content checks, and signature verification pass. Real-device testing and the Google Play release/AAB path remain unverified. The debug workflow does not create a production signing key or upload to Google Play.

## 1. Install and test first

Follow the README to build a debug APK and install it on a phone. On at least one real Android phone and one different screen size:

- Start, drag with one finger, and verify the platform follows smoothly without jumping when a drag starts. Check the phone's touch edges and gesture navigation area.
- Score five or more bounces to see vertical movement; verify speed increases without becoming unplayable.
- Miss the ball, replay, pause, resume, restart, and return to the menu.
- Switch apps and return: the game must stay paused. Try Android Back and the pause button.
- Close and reopen: best score and sound preference should remain. Uninstalling clears them.
- Test sound on/off, silent mode behavior, a 60 Hz and a high-refresh device if available, and a long session for heat/battery behavior.
- Check that the notch/status/navigation areas do not cover buttons. The HUD reserves top space, but real-device validation is required, particularly with Android's enforced edge-to-edge behavior.
- Verify large/tall screens, cutouts, frame pacing, and readable text. Confirm the launcher icon looks correct.

Resolve any build or device findings before distributing a release. Run the automated tests again after changes.

## 2. Set your permanent app identity

In Godot's **Project → Export**, change **Package → Unique Name** in BOTH presets to an identifier you control, e.g. `com.yourstudio.skybounce`. `org.skybounce.keepitup` is a working default, not a reserved store identity. Pick the identifier before your first Play upload; it cannot be changed for that store listing later.

Confirm the title, version name, and version code. Increment the version code for every store update. The current values are version name 1.0.0 and version code 1. The project targets SDK 36 and includes ARM64. Check the Play Console's current target API and device/page-size requirements at submission time; these change. Godot 4.6.3's official templates are intended for modern Android, but inspect the generated AAB and let Play's compatibility checks verify it.

## 3. Make a signed Android App Bundle

Keep credentials outside the project, source repository, and shared ZIP. Back up the key and its passwords privately. Losing an upload key complicates updates.

1. Install JDK 17, Android SDK, and Godot export templates as in the README.
2. In Godot choose **Project → Install Android Build Template**. This installs the Gradle project used by the Google Play export preset.
3. Create an upload keystore. Android Studio's **Generate Signed Bundle / APK** wizard can create one. Alternatively use the JDK command below in a private directory; it asks for passwords interactively:

   ```sh
   keytool -genkeypair -v -keystore sky-bounce-upload.jks -alias skybounce -keyalg RSA -keysize 2048 -validity 10000
   ```

4. Open **Project → Export → Google Play**. Under the keystore settings, select the release/upload keystore, alias `skybounce`, and its password. Never commit `export_credentials.cfg`. If passwords differ, follow Godot's supported signing configuration; using the same store/key password avoids common compatibility issues.
5. Confirm **Gradle Build → Use Gradle Build** is on and **Export Format** is AAB. Export to `builds/sky-bounce.aab` with **Export With Debug unchecked**.
6. Sign up for Play App Signing when Play Console offers it. Use your upload key for subsequent submissions. Install the build delivered through Play's internal test track, since an AAB is not directly installable like an APK.

This release/export path still needs to be built and verified; it could not be exercised without the Android SDK and templates here.

## 4. Complete your Google Play account and listing

- Enroll in Google Play Console, complete identity and any device verification, and pay Google's developer registration fee (commonly US$25 once; confirm the current terms).
- Create the app and complete app access, ads (none), content rating, target audience, Data Safety, and other required declarations. Choose your real intended audience; do not assume a child-directed designation.
- This code has no network permissions, analytics, ads, accounts, or tracking. Scores/preferences are stored locally and Android data backup is disabled. Review the final build before answering Data Safety, especially if you later add services.
- Adapt `docs/PRIVACY.md` with your real publisher name, contact email, and date. Host it at a public URL and put that URL in Play Console. A local Markdown file is not a public privacy-policy URL.
- Use the prepared copy in `docs/STORE_LISTING.md`, the 512px icon, and the 1024×500 feature graphic. Capture real phone screenshots of the finished game for the listing; the project does not include fabricated screenshots.
- Upload the signed AAB to **internal testing** first, resolve bundle/compatibility warnings, and review the pre-launch report.
- Complete any closed testing required for your account. New personal accounts can require at least 12 testers opted in continuously for 14 days; the Console's current requirements are authoritative.
- Request production access if required, select countries/pricing, submit for review, and address any reviewer feedback.

Free software is used throughout. Google enrollment and any optional hosting/service costs are separate from the project.
