# Testing evidence — cosmetics development branch

Local Godot 4.6.3 suite: **235 checks, zero failures**. Coverage includes original gameplay and Classic/Reverse symmetry, score thresholds, locked equipment, legacy migration, permanent unlocks, equipment persistence, atomic-save recovery, all premium variants, simulated purchase completion/cancellation/pending/errors, restore/revocation, acknowledgement deduplication/retries, strict backend approval and menu layouts at 320×568, 480×800 and 768×1024.

A corrupt primary save is deliberately created in the recovery test; Godot prints a ConfigFile parsing error and the test verifies successful backup recovery. This diagnostic is expected.

Desktop OpenGL rendering was exercised with Mesa software rendering and Xvfb. Gallery, menu, customization and both game modes were captured for inspection. These are development previews, not Android store screenshots. Preview clipping was corrected after visual review.

Godot's physics scripts `ball_sim.gd` and `play_session.gd` remain unchanged from the baseline. Plugin checksum verification and workflow actionlint checks pass. The signed release path was tested to refuse missing credentials without falling back to a debug key.

GitHub Actions run 42694561339 successfully built the native debug APK with Play Billing 9.1.0 and ran the then-current 210-check suite. Its release AAB compiled and passed bundletool validation; the additional project verifier initially rejected AndroidX's signature-only internal permission. That checker was corrected and updated for Godot's install-time asset pack. A fresh full run is required for the final revision; use the branch's latest Actions result and generated verification report as the final build evidence.

Not verified: physical Android touch/audio/performance, actual Google Play test transactions, signed AAB with the owner's upload key, Play Console acceptance, native iOS installation. Fake billing tests exercise application state transitions and do not substitute for real license-tester purchases. No real-money purchase or Play upload was initiated.

Use the [Console checklist](play-store/CONSOLE_SETUP.md) before publication. Client-side entitlement checks are not fraud-proof; server verification is an optional integration point, not a deployed service.
