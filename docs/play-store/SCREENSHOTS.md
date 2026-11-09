# Screenshot capture and asset review

Use actual Android screenshots from the final signed/test-track build for Google Play. Desktop previews from `tools/capture_previews.gd` are development QA only, not final production screenshots. The preview tool is excluded from app exports and never performs a purchase or saves its in-memory visual entitlement fixture.

Suggested phone captures:
1. Main menu and Classic/Reverse selection.
2. Classic rally showing normal play and score.
3. Reverse rally with the top platform.
4. Customization tabs showing free progression, locked requirements and equipped styles.
5. Premium pack screen showing Play's actual localized price and one-time-purchase description.
6. An owned style after a successful **license-tester** purchase, if you want to depict premium ownership.

Capture portrait screenshots at native device resolution, without notification banners, private account details, purchase tokens, debug overlays, or misleading promotional claims. Use Android's screenshot buttons or USB debugging:

```sh
adb shell screencap -p /sdcard/sky-bounce.png
adb pull /sdcard/sky-bounce.png
```

Use test accounts; do not include Google payment/account screens or personal information in public screenshots. Do not mark premium content "owned" in a production screenshot unless it reflects a real test entitlement. Review Play Console's current screenshot dimensions/counts and store image policy before upload.

For development desktop QA only, with an X display and Godot 4.6.3:

```sh
godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/capture_previews.gd
```

Outputs under `builds/previews/` are ignored by Git. The gallery uses the same lightweight drawing code as gameplay and previews, allowing visual review without changing production unlocks or making purchases.
