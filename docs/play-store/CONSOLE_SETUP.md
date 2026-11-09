# Owner checklist: Google Play Console

This branch is development work, not a published app. No store listing, product, tester enrollment, real purchase, release upload, or production rollout was performed by automation. Follow this checklist only when you are ready; do not use a real card to test purchases.

## 1. Review and build the branch

Review `feature/cosmetics-and-google-play` in the existing repository. Main stays unchanged. Download its debug artifact from GitHub Actions to test gameplay and free styles. Premium previews are available, but purchases from a sideloaded debug APK may be unavailable; use Play's test track for billing validation.

Run the existing **Build Android installer** workflow on this branch. The new `release_mode` input accepts:
- `none`: debug APK + automated tests only.
- `unsigned`: debug APK and an unsigned **release** AAB with a verification report. This cannot be uploaded to Play until signed.
- `signed`: debug APK and an upload-key-signed release AAB, using the secrets described in `RELEASE_SIGNING.md`.

If the GitHub web form still reflects main's old inputs, use the GitHub CLI:

```sh
gh workflow run android.yml --repo nius195-cpu/sky-bounce --ref feature/cosmetics-and-google-play -f release_mode=unsigned
```

Use `signed` after private signing secrets are configured. Artifacts are uploaded for download; there is no publishing step.

## 2. Create/configure the Play app

Enroll/verify your Play Console developer account and create **Sky Bounce** as a game. Confirm the permanent application ID **org.skybounce.keepitup** belongs to this app. The source keeps the existing ID to preserve app identity. If it is unavailable or associated with another owner, resolve that before the first upload; do not casually change it on an existing app.

Use Google Play App Signing: Google manages the distribution signing key, while your private upload key signs future AAB uploads. Set up the upload key from `RELEASE_SIGNING.md`, then upload a signed AAB to **internal testing**, not production. Address all bundle validation and pre-launch report issues. Build success is not store approval.

Changing signing certificates can prevent installing over an earlier debug build. Uninstalling clears local scores/free unlocks. Keep signing consistent for updates; do not promise progress survives an uninstall or debug-to-Play signature change. Premium ownership can be restored through the Play account; free progress has no cloud backup in this implementation.

## 3. Create the permanent product

Under **Monetize → Products → One-time products** (Console labels can change):

1. Create product ID **sky_bounce_style_pack**. This identifier must match the code exactly and should not be changed after testing.
2. Name it **Sky Bounce Ultimate Style Pack**. Describe the ten skins listed in `STORE_LISTING.md`.
3. Configure a permanent **buy** purchase option, not a rental, subscription, consumable, or multi-quantity offer. A simple purchase-option ID such as `buy` is suitable; the app retrieves the actual ID from Play.
4. Set the US base price to **USD $1.99**, choose supported countries, review local prices/taxes, and activate the product/purchase option.
5. The app shows Play's localized formatted price and opens Play's confirmation screen. A hardcoded USD display is not used as a charge amount.

The app never consumes this product. Purchases stay associated with the purchasing Google Play account. Do not create ten separate paid products: one purchase unlocks all ten variations.

## 4. Configure license testers and test track

Add tester Google accounts in Play Console's license-testing settings. Also add/opt them into the internal test track and install the Play-delivered build with the correct Google account. License testing and track membership are separate requirements. Check that the purchase screen clearly shows a **test** payment method and no real charge. If it does not, cancel; do not proceed with real-money testing.

Test all items in [the testing report](../TESTING.md), especially:
- Product lookup/localized price; successful test purchase and acknowledgement.
- User cancellation; decline/failure; pending payment that later completes or cancels.
- Duplicate taps and purchase callbacks; already-owned protection.
- App close/restart before acknowledgement; temporary offline acknowledgement retry.
- Restore on a second compatible Android device using the same Play account.
- Store query errors preserve offline cached styles; a successful empty/refunded account query resets paid equipment to defaults.
- Refund/revoke through Console, account changes, and pending completion while the app is not running.

No end-to-end Google Play purchase tests have been performed here. The automated fake-client tests are not a substitute.

## 5. Complete listing and app content

Use `STORE_LISTING.md` and existing original draft art (512×512 icon and 1024×500 feature graphic). Capture actual phone screenshots as in `SCREENSHOTS.md`; desktop development previews are not final Play screenshots.

Fill in your real publisher name and support email. Adapt `PRIVACY.md` and host it at a public HTTPS URL before submission. Complete Ads (none), app access (no game login), in-app purchases (yes, cosmetic one-time pack), target audience, IARC content rating, and Data safety using the final app and SDK practices. `COMPLIANCE.md` explains verified facts and unresolved owner decisions. Do not copy draft questionnaire suggestions blindly or claim Google SDKs collect no data without review.

## 6. Testing and final submission

Complete closed testing/production-access requirements shown for your account. Google's current guidance for affected new personal accounts is at least **12 testers continuously opted in for 14 days**; internal testing does not replace that requirement. Keep feedback and fix findings.

After reviewing signing, device tests, billing tests, accessibility/cutouts, privacy/disclosures, and pre-launch results, decide whether to merge the feature branch. Production submission, country/pricing choices, and rollout require your explicit action/approval. No workflow uploads to Play or initiates purchases.
