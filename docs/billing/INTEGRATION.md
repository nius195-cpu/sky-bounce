# Google Play Billing integration

The vendored, MIT-licensed **GodotGooglePlayBilling 3.3.0** is the maintained Godot SDK Integrations plugin (formerly godotengine). It supports Godot 4.2+ and embeds **Google Play Billing 9.1.0**, the version currently documented by Google. The project uses Godot 4.6.3. Provenance, archive SHA256 and file checksums are in `addons/GodotGooglePlayBilling/UPSTREAM.json`; run `python3 tools/check_billing_plugin.py` to verify. Upstream files are unchanged, including its debug/release AARs and Android export hook.

Sources checked 2026-11-09:
- https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/tag/3.3.0
- https://developer.android.com/google/play/billing/release-notes
- https://developer.android.com/google/play/billing/deprecation-faq
- https://developer.android.com/google/play/billing/integrate
- https://developer.android.com/google/play/billing/security

`StyleBilling` owns one plugin client. It connects and queries the non-consumable product and owned purchases at startup, on foreground return, and when Restore Purchases is pressed. Product price and purchase-option ID come from Play, including localized currency; no hardcoded price is passed as a payment amount. The owner must set the US base price to $1.99 in Console.

The buy button is disabled until product lookup AND account ownership reconciliation succeed. Duplicate taps, already-owned state, pending purchases, and in-flight validation block another launch. `ITEM_ALREADY_OWNED` requests an ownership query, never grants solely from an error code.

A successful purchase-screen launch does not grant content. Only the SDK's normalized PURCHASED result for `sky_bounce_style_pack`, package `org.skybounce.keepitup`, quantity 1, nonempty token/signature/original JSON, and non-suspended state can enter entitlement processing. Pending, cancelled, failed, unrelated, wrong-package, or incomplete records stay locked. Acknowledgement happens after delivery, is retried on errors/timeouts, and is idempotent across duplicate callbacks. The pack is NEVER consumed and is not a subscription.

Ownership uses a persistent local cache for offline play but is reconciled from Google Play. Transient errors preserve that cache. A successful empty ownership snapshot revokes stale ownership (including account changes/refunds visible to the query) and resets equipped premium styles to defaults. A reinstall/new compatible Android device restores through the same Google Play account. Free score unlocks remain permanent and unaffected.

## Security boundary and future backend

**No secure verification server is deployed. This is not fraud-proof.** Presence/shape/state checks on an SDK result do not cryptographically validate a signed receipt independently or defeat a modified client. Local saves, including cached premium entitlement and scores, can be edited on a compromised device. Purchase tokens/signatures/original JSON are kept only in memory for processing, never logged or committed. Local settings store ownership/equipment, not payment card details or receipt tokens.

A future async `server_verifier(receipt) -> bool` Callable is supported before entitlement delivery/acknowledgement. Implement it by sending the token to your authenticated HTTPS backend; use the Google Play Developer API there to verify product/package/purchase state, deduplicate globally by token, bind to your account system if added, and acknowledge/reconcile refunds through server APIs/real-time notifications. Keep service-account credentials on the server. Failures/rejections of this hook do not grant content. The provided default uses SDK-result validation only.

No real payment flow has been initiated by development automation. Automated tests inject `tests/fake_billing_client.gd`, with explicitly fake receipts. They verify state handling, NOT communication with Google Play or financial settlement. Real license-tester purchases, pending-payment instruments, cancellation, refund/account reconciliation, and cross-device restore require the owner's Play Console setup and must be tested before production approval.
