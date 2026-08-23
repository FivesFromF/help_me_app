# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`help_me_app` is the **Flutter mobile client** of HelpMe (team FivesFromF) — an emergency-response
system. A responder identifies a person in distress by **NFC tag, QR code, or face scan**, and the
app surfaces that person's medical profile and next-of-kin. It is a **git submodule** of the
`help_me` umbrella repo (`.git` here is a gitdir pointer). Commit here first, then commit the
advanced pointer in the parent repo.

All server logic lives in `help_me_backend` — its docs vault (`help_me_backend/docs/`) is the source
of truth for API shapes; do not guess backend behaviour from this client.

## Commands

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json   # normal dev run
flutter analyze
dart format lib
flutter test                                            # no test/ dir exists yet
flutter build apk --dart-define-from-file=dart_defines.json
dart run flutter_launcher_icons                         # after changing assets/logo.png
```

Prefer the Dart/Flutter MCP tools (`analyze_files`, `dart_format`, `run_tests`, `hot_reload`,
`launch_app`) over raw shell when they are available.

## Configuration

`lib/config/env.dart` is the **single source** for backend-derived values (API endpoint, Cognito pool
/ client / hosted-UI domain). Every value is `String.fromEnvironment` with a committed default, so the
app runs without `--dart-define`; `dart_defines.json` (gitignored, copy of `dart_defines.example.json`)
overrides them at build time. `lib/amplifyconfiguration.dart` interpolates `Env.*` into the Amplify
JSON — never hardcode IDs there. Values come from `terraform output` in `help_me_backend/infra`; after
a `terraform apply` that changes IDs, edit `env.dart` only.

OAuth redirects use the custom scheme `helpme://auth-callback` / `helpme://auth-logout`, declared in
both `amplifyconfiguration.dart` and `android/app/src/main/AndroidManifest.xml` — change them together.

## Architecture

### Everything goes through `AuthService`

`lib/shared/services/auth_service.dart` (~900 lines) is the entire API layer: a class of **static
methods** over `package:http`, grouped by comment banners (profile, medical record, S3/AI jobs, NFC,
QR, identity verification, emergency report, history, complaints). There is no DI, no repository
layer, and no state-management package — pages call `AuthService.x()` directly from `initState` and
hold results in `setState`. Add new endpoints as static methods in the matching banner section.

Auth state: `getAccessToken()` asks Amplify for a fresh Cognito session and *writes through* to
`SharedPreferences`, falling back to the cached token when Amplify fails. Prefs keys are
`access_token`, `role`, and `profile` (a JSON blob holding `{role, profile, citizen}`); `signOut()`
does `prefs.clear()`.

### Backend responses are raw maps, read defensively

API results are handed around as `Map<String, dynamic>`, not typed models. `_deepCastMap` re-casts
nested `Map` values because `jsonDecode` yields `Map<dynamic, dynamic>` inside. The backend emits
**both camelCase and snake_case** for some fields, so existing code reads
`citizen['isVerified'] ?? citizen['is_verified']` — match that pattern rather than assuming one form.
The models in `lib/shared/models/` (`CitizenProfile`, `MedicalRecord`, `ContactInfo`) are used only by
some profile pages; most screens work on raw maps.

### Two image pipelines (face)

1. **Fast sync path** — `POST /api/v1/read/scan` with `method: 'FACE'` + `imageBase64`, 4 s timeout.
   Used only by `searchByFace`; any failure falls through silently.
2. **Async S3 + AI worker path** — `getUploadUrl(operation:)` → presigned PUT of raw JPEG bytes to S3
   → `pollScanJob(jobId:)` which polls `GET /api/v1/read/scan/jobs/:jobId` up to 20×1 s until the job
   is `COMPLETED` or `FAILED`. `operation` is `FACE_SCAN` (search) or `FACE_ENROLL` (registration).
   `registerFace` uses this path exclusively and refreshes the profile cache afterwards.

Outcomes are signalled by `matchStatus`: `MATCH_FOUND`, `NO_MATCH`, `ACCESS_REVOKED`.

### The three identity-scan entry points converge

- **NFC** — `identity_scan_page.dart` uses `NfcService.readCardData()` to get the hardware UID plus
  the HMAC token stored as an NDEF Text record, then `verifyIdentity(nfcId: uid, hashedCitizenId:)`.
- **QR** — `qr_scanner_page.dart` decodes a JSON payload carrying `qrId` + hash, then
  `verifyIdentity(qrId:, hashedCitizenId:)`.
- **Face** — `face_recognition_page.dart` runs a live camera stream through
  `google_mlkit_face_detection`, checks framing, and fires a background `searchByFace` roughly once a
  second while the face stays in position.

All three push **`IdentityResultPage(data: result)`**, which normalises `victim` / `citizen` /
`profile` keys and renders a candidate selector when the face search returns 1–3 similar matches.

Hash IDs are minted and verified server-side with `SYSTEM_SECRET` (backend `services/hash.service.ts`);
the app only carries them.

### Location

`LocationService.getCurrentLocation()` **never throws** — on disabled GPS or denied permission it
returns Ho Chi Minh City coordinates with `isRealGps: false` and a Vietnamese `message`.
`verifyIdentity` and `searchByFace` auto-fetch coordinates when the caller does not pass them, so
scan call sites usually omit lat/lon.

### Routing and gating

`lib/config/router.dart` is a flat `GoRouter` table with **no `redirect` guard**. Gating is imperative:

- `SplashScreenPage` is the funnel — `isLoggedIn()` → `fetchAndCacheProfile()` → `/auth/sign-up` if
  `firstDeclareProfile` is false → `/privacy?consent=true` if `consentRegulation` is false → `/home`.
- `VerificationGuardDialog.show(context)` blocks unverified accounts on home, medical record, and
  settings.

Result pages are pushed with plain `MaterialPageRoute` rather than routes, since they carry a whole
response map.

## Conventions

- **Vietnamese** for user-facing strings and most comments/doc comments. Match the language already in
  the file you are editing.
- Errors are surfaced by stripping the prefix: `e.toString().replaceAll('Exception: ', '')`.
- `AppColors` (`lib/app_colors.dart`) holds the brand palette; icons come from `phosphor_flutter`.
- Widget locations: `lib/widgets/` is legacy generic form input; `lib/shared/widgets/` is cross-page;
  a page folder's own `widgets/` is per-screen.
- **Preferred decomposition pattern** — `lib/pages/history/` is the model: the page keeps only data
  loading and wiring, while `widgets/` splits into `history_tokens.dart` (semantic colour tones and
  formatters), `history_atoms.dart`, `history_card.dart`/`history_cards.dart`, `history_sheet.dart`/
  `history_detail_sheets.dart`, `history_dialogs.dart`, `history_states.dart`. Several older screens
  are still 1000–1500-line single files (`medical_record_page.dart`, `identity_result_page.dart`,
  `home_page.dart`); when doing substantial work in one, extract toward the history layout instead of
  growing the file.
- Guard every post-`await` `setState` with `if (mounted)`.
