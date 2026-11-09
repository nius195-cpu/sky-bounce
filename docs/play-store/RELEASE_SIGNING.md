# Private release signing

Do not send passwords or signing keys in chat, commit them, or upload them as public artifacts. The repository ignores keystores, `export_credentials.cfg`, `.godot`, and build outputs.

Create an **upload key** privately with JDK `keytool` or Android Studio's signing wizard. Example (asks for passwords interactively):

```sh
keytool -genkeypair -v -keystore sky-bounce-upload.jks -alias skybounce -keyalg RSA -keysize 2048 -validity 10000
```

Use the same store/key password for Godot's supported signing configuration. Back up the key, alias, and password securely. Let Play App Signing manage the distribution key; retain the upload key for future uploads.

In GitHub **repository Settings → Secrets and variables → Actions**, create:

| Secret | Value |
| --- | --- |
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | Base64-encoded bytes of your private upload keystore, entered through GitHub's secret UI |
| `ANDROID_UPLOAD_KEY_ALIAS` | The key alias, e.g. `skybounce` |
| `ANDROID_UPLOAD_KEYSTORE_PASSWORD` | The private keystore/key password |

Base64 is encoding, not encryption: never commit it or paste it into issues/logs. Encode privately using your computer's Base64 tool. GitHub stores the value as an Actions secret.

Run **Build Android installer** on this branch with `release_mode=signed`. The script refuses to substitute a debug key if any required secret is missing. It decodes the key into an ephemeral runner temp folder with mode 0600, uses Godot's supported release-key environment variables, filters signing values from child-process output, and deletes the temp folder. The key is not cached or uploaded. Do not enable shell tracing or verbose credential logging.

The unsigned mode uses release engine libraries and release settings but disables signing in a temporary preset. It restores the tracked presets even after failure. Its output is explicitly named `sky-bounce-unsigned.aab`; this is a build-verification artifact, not a Play-upload-ready bundle. The signed mode produces `sky-bounce-signed.aab` and verifies its JAR signature. The owner still must supply the correct key registered to their Play app.

Both modes use official bundletool validation and inspect the final manifest/content: target API, billing version, permissions, no debuggable/test-only/profileable flags, no development test/tools assets, native ARM64 code, and game assets (including Godot's install-time asset pack). The generated JSON report records what was actually verified.

No private signing credentials were available in this task. Real upload-key signing is prepared but remains unverified until the owner supplies those credentials. The missing-secret refusal path was tested. Workflows never publish to Google Play.
