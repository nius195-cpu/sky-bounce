# Sky Bounce Privacy Policy — publisher draft

**Replace the bracketed fields and review SDK practices before publishing this policy at a public HTTPS URL.**

Effective date: [publication date]
Publisher: [your publisher/legal name]
Privacy/support contact: [your public contact email]

Sky Bounce is an offline arcade game with optional cosmetic purchases through Google Play. It contains no advertising SDK, analytics SDK added by the game, social features, chat, or game-account registration.

## Local game data

The game stores Classic and Reverse high scores, highest progression score, permanently earned free cosmetics, equipped styles, a cached premium-ownership flag, and settings on your device. It keeps a local backup to recover a corrupt save. This game data is not sent to a developer-operated server in this implementation. Clearing app storage or uninstalling removes it. There is no cloud backup for free progress; Android data backup is disabled.

## Optional Google Play purchases

Purchases are processed by Google Play under Google's applicable terms and privacy policy. The game does not collect your payment-card details or ask you to enter payment credentials. It receives product information and purchase records from Google Play, including product IDs, purchase state, tokens, signatures, package, quantity, acknowledgement status and transaction-related metadata used to deliver and restore cosmetics. The game processes receipt details in memory and does not write full tokens/signatures/receipt JSON to its save or diagnostic logs. It stores a local ownership cache so purchased styles can work offline.

On startup/foreground and when you choose Restore Purchases, the app queries Google Play to reconcile ownership. Restoring on another compatible Android device requires the same purchasing Google Play account. Google may process purchase/account/service/device or diagnostic data according to its own service and SDK practices. The publisher must review the current Billing Library 9.1.0 and its transitive dependencies when completing Data safety; this draft does not assert that third-party SDKs collect no data.

There is no developer-operated purchase-verification server currently. If one is added later, this policy and Data safety disclosures must be updated before deployment to describe receipt transmission, retention, security, account binding, and deletion practices.

## Permissions and contact

The game does not request camera, microphone, contacts, storage, or location permissions. The final Android build verification report lists the actual permissions, including Google Play billing and any SDK-required network access/internal signature permission. Google Play handles payment-related interactions. If you email support, you choose what information to send and your email provider and publisher process it to answer your request.

Contact [your public contact email] with privacy questions. Changes to the app's data practices require an updated policy before the affected release.
