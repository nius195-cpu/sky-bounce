# Testing evidence — cosmetics development branch

Local Godot 4.6.3 suite: **235 checks, zero failures**. Coverage includes original gameplay and Classic/Reverse symmetry, score thresholds, locked equipment, legacy migration, permanent unlocks, equipment persistence, atomic-save recovery, all premium variants, simulated purchase completion/cancellation/pending/errors, restore/revocation, acknowledgement deduplication/retries, strict backend approval and menu layouts at 320×568, 480×800 and 768×1024.

A corrupt primary save is deliberately created in the recovery test; Godot prints a ConfigFile parsing error and the test verifies successful backup recovery. This diagnostic is expected.

Desktop OpenGL rendering was exercised with Mesa software rendering and Xvfb. Gallery, menu, customization and both game modes were captured for inspection. These are development previews, not Android store screenshots. Preview clipping was corrected after visual review.

Godot's physics scripts `ball_sim.gd` and `play_session.gd` remain unchanged from the baseline. Plugin checksum verification and workflow actionlint checks pass. The signed release path was tested to refuse missing credentials without falling back to a debug key.

Final [GitHub Actions run 42700284933](https://github.com/nius195-cpu/sky-bounce/actions/runs/42700284933) passed both Android debug and release jobs on source commit `1e38b70`. Both ran the 235-check suite successfully. The installable debug APK and unsigned release AAB were built and uploaded. The release passed bundletool and project checks for package identity, API target, permissions, billing dependency, release flags and excluded development files. Artifacts include checksums and the release verification report. No production signing credentials were supplied; the unsigned AAB cannot be submitted to Play until signed.

An earlier run exposed an overly strict verifier assumption about AndroidX's signature-only internal permission and Godot's install-time asset pack. Those checks were corrected before this successful run.

Not verified: physical Android touch/audio/performance, actual Google Play test transactions, signed AAB with the owner's upload key, Play Console acceptance, native iOS installation. Fake billing tests exercise application state transitions and do not substitute for real license-tester purchases. No real-money purchase or Play upload was initiated.

Use the [Console checklist](play-store/CONSOLE_SETUP.md) before publication. Client-side entitlement checks are not fraud-proof; server verification is an optional integration point, not a deployed service.
