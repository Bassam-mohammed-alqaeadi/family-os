# 13 — Open Questions and Unknown Facts (Family OS)

**Date:** 2026-09-23  
**Rule:** Only items that could **not** be verified from this repository. Do not treat as owner QUESTIONS.md blockers unless escalated.

---

## Unknowns

| ID | Unknown | Why it matters | Suggested verification |
|---|---|---|---|
| U-001 | Does a Family OS backend repo exist outside this tree? | Backend status H might be “elsewhere” | Ask owner / search org remotes |
| U-002 | Exact count of screen files fully wired vs orphaned | Scope of XD-006 | Script: map every SCR-* builder type |
| U-003 | iOS project depth (permissions, Screen Time entitlement) | Child iOS path | Inspect `app/ios/` Info.plist & entitlements |
| U-004 | Whether SharedPreferences adapter is implemented anywhere outside app/lib | Persistence claims | Broader repo search already negative in app — confirm packages |
| U-005 | LiveKit / map provider decisions | Comms/location build | Product ADR search in handoff |
| U-006 | Quran licensed corpus integration status | Rule 26 | Search assets + EDU services |
| U-007 | Mother soft permissions on each FAT screen beyond RoleGuard sets | Co-parent baseline completeness | Per-screen CurrentRole branches audit |
| U-008 | Wave-3 screen route generator lag vs harness cards | Why placeholders remain | Compare BACKLOG done cards vs router builders |
| U-009 | Whether Drift schema drafts exist beyond comments | Data roadmap | Search docs/project-plan |
| U-010 | Production package id / store listing name vs `family_os` | Branding | AndroidManifest / pubspec only seen |
| U-011 | Relationship of product name “Guardian Eye Pro” (if any) to this codebase | Avoid naming confusion | Owner confirmation — **this discovery uses Family OS only** |
| U-012 | Full service registry (S-ADM-*, S-SEC-*) implementation map | Screen→service completeness | `family-os/_REGISTRY` services files |
| U-013 | Real notification copy / event pipeline beyond mocks | Event honesty Rule 23 | EventBus search beyond policy buses |
| U-014 | Offline conflict rules beyond Register text | Sync design | handoff Register §G-1 vs code |

---

## Verified non-unknowns (do not re-ask)

- Firebase is not in this app.  
- MainActivity has no Device Owner logic.  
- PolicyEngine minutes rules exist as pure Dart.  
- 43 PlaceholderScreen route builders exist.  
- P15-EDU-006/007 marked OPEN in GAP_LOG.

---

## FACT vs process

These unknowns are **discovery residuals**, not automatic `QUESTIONS.md` halts unless the next phase requires a decision.
