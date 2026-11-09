# Google Play compliance review — checked against primary sources

This is a preparation checklist, not a guarantee of approval or legal advice. Recheck Play Console at submission; policies and account requirements can change.

| Topic | Current source / implementation | Remaining owner verification |
| --- | --- | --- |
| Billing version | Official maintained Godot plugin 3.3.0 uses Play Billing 9.1.0. Google's version table supports v9 for new apps/updates through Aug 31, 2028; v8 through Aug 31, 2027. | Confirm Console detects `com.google.android.play.billingclient.version=9.1.0` in final signed AAB. |
| Target API | Google currently requires API 36+ for new mobile apps/updates. Project compiles/targets 36 with min API 24 and ARM64. | Review current Console warnings and native-library compatibility/pre-launch checks, including 16KB-page devices. |
| Payment product | One non-consumable cosmetic pack, no subscription/consumption/advertising. Dynamic localized price comes from Play. | Create/activate `sky_bounce_style_pack`, permanent buy option, US base price $1.99, territories/taxes and test purchases. |
| Entitlement security | SDK completed-state/schema checks, acknowledgement/retries, startup/foreground restore, offline cache, successful ownership reconciliation. No server deployment. | Client validation is not fraud-proof. Complete license-tester flows; consider a trusted verification backend before production. |
| Signing | Secret-based upload-key workflow, Play App Signing compatible, unsigned release verification supported. | Supply the correct private key/secrets; configure Play signing and verify signed upload. |
| Ads / app access | No ad SDK and no game login added. | Declare no ads, optional IAP, and explain any platform account needed for purchases. |
| Data safety | Game scores/styles/settings local; receipts handled in memory; Play Billing and transitive SDK behavior must be reviewed. | Complete the form from the final build/SDK practices. Do not claim zero data collection just because no developer backend exists. Payment-service exemptions have conditions. |
| Privacy policy | Draft provided; no contact/publisher identity fabricated. | Add real identity/contact, host a public URL, and ensure policy matches actual app and SDK processing. |
| Content / metadata | Arcade game, no user-generated content, chat, violence, gambling, or randomized paid rewards in this code. | Review all imagery/text, audience selection, local requirements, and final IARC questionnaire; only the authority assigns ratings. |
| Testing tracks | Debug tests and build checks are separate from Play testing. Current affected new personal accounts need 12 continuous closed testers for 14 days. | Meet your account's Console requirements, internal billing tests, closed testing if required, production access review, and rollout approval. |

## Suggested content-rating questionnaire responses — verify before answering

For the code/assets in this branch: game category Arcade; no depicted violence, sex/nudity, strong language, horror, drugs, realistic gambling, user interaction/content sharing/chat, or unrestricted web browsing. There **is** an optional real-money cosmetic purchase. There are **no** randomized paid items/loot boxes. Do not invent an "Everyone" rating, select a children's audience automatically, or answer on the publisher's behalf. Review the exact current questions and all final assets; IARC provides regional results.

## Primary references

- Billing deprecation/version policy: https://developer.android.com/google/play/billing/deprecation-faq
- Current billing releases: https://developer.android.com/google/play/billing/release-notes
- Integration/acknowledgement/pending purchases: https://developer.android.com/google/play/billing/integrate
- Purchase security/backend verification: https://developer.android.com/google/play/billing/security
- Billing testing: https://developer.android.com/google/play/billing/test
- Target API: https://support.google.com/googleplay/android-developer/answer/11926878
- Data safety form and payment-service exemptions: https://support.google.com/googleplay/android-developer/answer/10787469
- App content/privacy/content rating: https://support.google.com/googleplay/android-developer/answer/9859455
- Closed testing: https://support.google.com/googleplay/android-developer/answer/14151465
- Developer policies: https://play.google/developer-content-policy/
- Maintained plugin: https://github.com/godot-sdk-integrations/godot-google-play-billing

No Play Console questionnaire, paid purchase, upload, or production publication was completed by development automation. Successful build checks do not imply Play approval.
