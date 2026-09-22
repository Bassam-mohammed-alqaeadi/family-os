# Family OS Flutter app (`app/`)

**Pinned SDK (owner PC — do not hop versions):**
- Flutter **3.35.7** stable (`C:\src\flutter`)
- Dart **3.9.2**
- No FVM on this machine; agents must use this SDK only

**Font:** IBM Plex Sans Arabic (OFL) — see `assets/fonts/` + `IBM_Plex_OFL.txt`

**Structure:** feature-first per `../handoff/02_ARCHITECTURE.md`  
**i18n:** Arabic-first ARB in `lib/core/i18n/` (`app_ar.arb` template)

## Commands

```bash
cd app
flutter pub get
flutter gen-l10n
dart run tool/gen_routes.dart   # regenerate lib/app/router.dart from screens.csv
dart format .
flutter analyze
flutter test
flutter run
```

### Routes (F1-A)

- Source of truth: `../prototype/_REGISTRY/screens.csv`
- Generator: `dart run tool/gen_routes.dart` → writes `lib/app/router.dart` (**do not edit by hand**)
- Paths: `/scr-fat-010` style (`screen_id` lowercased, `_` → `-`)
- Initial location: `/gallery`
- RoleGuard: child blocked from privacy / audit; father-only for subscription / billing / brain (UI-007 / SET-015); SOS never paywalled (P-4)

## Harness

Cards **F0-0…F2-POLICY** + **SCR-SHR-001…003/007** + **SCR-FAT-001…002** shipped. Current Stage 1 card: **SCR-FAT-003** (add child).

