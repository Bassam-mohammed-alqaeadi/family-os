# 12 — Critical Dependencies and Risks (Family OS)

**Date:** 2026-09-23  
**Note:** Dependencies for a *real* Family OS experience — not an implementation plan.

---

## Dependency stack (blocked capabilities)

| Real-world need | Depends on | Current | Risk if ignored |
|---|---|---|---|
| Account & family membership | Auth service + `account`/`member` APIs | H | No multi-user product |
| Child device binding | Pairing service + secure device identity | F UI | Fake “linked” families |
| Screen time enforcement | Android Usage Access / iOS Screen Time APIs + agent | H | Parents think caps work |
| Web filter | VPN/DNS/local proxy or MDM web rules | H | Filter UI is theater |
| Instant lock | Device Admin / Lock Task / managed profile | H | Lock button false confidence |
| Anti-tamper | Permission monitors + integrity signals | F simulate | No real bypass detection |
| Location / geofence | GPS SDK + background location + server | H | Empty safety promise |
| SOS | Telephony/SMS gateway + live location + push | F | Critical safety failure |
| Push alerts | FCM/APNs + NotificationDelivery mapping | H | Parents miss events |
| Chat | Realtime messaging backend | F | Family tab is demo |
| Calls | LiveKit (or equiv.) + TURN | H (CSV mentions LiveKit; dep absent) | Call screens demo |
| AI advisor/tutor | AI Gateway + Advisor/Insights/Tutor repos | F mock | Misleading intelligence |
| Durable settings | SQLite/Drift or server source of truth | H memory | Data loss; desync |
| Sync/outbox | Network queue + conflict policy (Register §G-1) | F bus | Multi-device inconsistency |
| Billing | Store IAP + entitlement service | F mock | Cannot monetize safely |
| Audit compliance | Append-only store (server) | F memory | No forensic trail |
| Co-parent permissions | Server-enforced perm_level | B local only | Mother gates bypassable by role switch |
| Quran content | Licensed source only (Rule 26) | UNKNOWN licensing wiring | Legal/religious risk |

---

## Cross-system risks

1. **Honesty debt:** CapabilityHonestyTile exists for platforms, but many other domains still look fully capable.  
2. **Test green ≠ product ready:** Large suite validates mocks.  
3. **Placeholder vs file drift:** Engineers may “finish” screens that users never reach.  
4. **Single-process multi-role:** Father/mother/child share one app process via RoleController — not representative of two phones.  
5. **Policy core sanctity:** `core/policy/` and `tokens.dart` are owner-gated — changes need discipline.  
6. **Stage 3 / harness:** LOOP_STATE notes Stage 3 blocked — product phases incomplete.

---

## Role-specific risk

| Role | Top risk |
|---|---|
| Father | Believes enforcement exists after configuring beautiful settings |
| Mother | Assumes FULL equals father power; lacks server enforcement |
| Child | Sees transparency/SOS UI that doesn’t match real collection/emergency |

---

## FACT / INFERENCE

- **FACT:** Listed native/network packages are absent from pubspec.  
- **INFERENCE:** Closing XD-001…005 is prerequisite to any “real-world complete” claim.  
- **UNKNOWN:** External systems already chosen by Bassam outside this repo.
