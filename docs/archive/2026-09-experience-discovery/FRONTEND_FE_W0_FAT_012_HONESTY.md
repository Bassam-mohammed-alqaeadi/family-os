# FE-W0-FAT-012-HONESTY — LOCAL_DEMO provenance BannerNote

**Date:** 2026-09-25  
**Gate:** Frontend Completion  
**Screen:** `SCR-FAT-012`  
**Status:** **COMPLETE**

## Change

When roster envelope provenance is `LOCAL_DEMO_SEEDED`, Kids list shows a `BannerNote` stating location / last-seen / battery / time-left are **local demo presentation** — not live GPS or OS battery.

## Verification

```text
flutter test test/features/n02_day/children_list_screen_test.dart \
  test/core/identity/dom_identity_b_roster_seed_test.dart
→ All tests passed · EXIT=0
```

Evidence: `.verify/FE-W0-FAT-012-HONESTY.json`
