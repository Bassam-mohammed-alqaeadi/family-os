# Global-Readiness Gaps & Structural Closures
English digest of `family-os/42_GLOBAL_READINESS_STRATEGY.md`. Diagnosed by probing the frozen prototype code on 2026-09-18. **These are scope boundaries of v1.0, not defects** — they close during the Flutter build, never by reopening the frozen design.

## The 8 gaps (evidence-based)
| # | Gap | Evidence from code probe | Severity for global market | Closure |
|:-:|---|---|:-:|---|
| G1 | **iOS reality not designed as an experience** | One iOS mention total; Apple doesn't grant third parties most time-control APIs | 🔴 fatal (store removal risk if overpromised) | `core/platform/ios_reality.dart` capability table; every tool screen renders an honesty badge (full on Android / reports-only on iOS). Marketing = "the only product honest about iPhone". Phase F4. |
| G2 | **Single language/direction** | `lang="ar" dir="rtl"` only; zero i18n infrastructure | 🔴 fatal for global (not for launch region) | ARB files from day one (rule 12); English skeleton; cost now ≈ 0. Phase F0. |
| G3 | **Separated/two-household families** | Zero mentions of custody/separation | 🟠 high | Reserved empty `guardianship` table in schema; screens only after an owner decision session (legal/educational minefield — owner's call). |
| G4 | **Account recovery / lost device** | One mention only | 🟠 high (father's device = family sovereignty) | `SovereigntyRepository` contract defined now; screens after owner session. |
| G5 | **Regional legal compliance (COPPA/GDPR-K)** | No age/consent flow by region | 🔴 legally fatal in US/EU | Consent/age/region columns in Drift schema from the FIRST table; activation later, structure now. Phase F2 schema. |
| G6 | **Accessibility** | Zero aria/semantics | 🟠 rising (EAA etc.) | Mandatory `Semantics` (rule 16) + F7 screen-reader pass. |
| G7 | **Single-currency pricing** | "SAR" only in plans | 🟡 medium | Store-driven pricing abstraction; plan screen reads currency from config. |
| G8 | **Design centered on Khaled** | Khaled 244 mentions vs Saad 34; no `activeKid` param | 🟡 (intentional as narrative) but MUST become a contract | **Parametric contract**: every child screen = `f(ChildId)`; CI bans child names outside `mock/`; acceptance S3 runs ×3 children. Phase F1+. |

## Standing strengths to preserve (don't regress)
OEM battery-kill handling (10 mentions), offline-first as constitution, forever-free safety tier, append-only audit log, this very policy register.

## Expansion strategy (owner-approved direction)
Gulf launch with v1.0 scope → Muslim-diaspora markets (UK/US/CA — first live test of G2+G5 with a sympathetic audience) → full global. Each ring funds and de-risks the next.
