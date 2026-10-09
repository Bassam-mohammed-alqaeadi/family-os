# 09 — End-to-End User Journeys (Family OS)

**Date:** 2026-09-23  
**Format:** START → INTENT → SCREEN(S) → ACTION → SYSTEM LOGIC → DATA → BACKEND/SYNC → CHILD DEVICE EFFECT → NOTIFICATION → RESULT → FAILURE/RECOVERY  

Status on each journey: A–H for **real-world completeness**; in-app notes called out.

---

## J1 — Father creates family (onboarding)

| Step | Current behavior |
|---|---|
| START | App launch → `/scr-shr-001` |
| INTENT | Become family owner |
| SCREENS | SHR-001 → SHR-002/003 → SHR-007 → FAT-001 → FAT-002… |
| ACTION | Enter family name; continue wizard |
| SYSTEM LOGIC | Validation; mock create injectable (UI-001) |
| DATA | Memory / navigation state |
| BACKEND/SYNC | **None** |
| CHILD EFFECT | None |
| NOTIFICATION | None |
| RESULT | Navigate to day board / next wizard step |
| FAILURE | AppErrorState retry paths on create family |
| **Status** | **F** (UI journey) |

---

## J2 — Pair child device (QR)

| Step | Current behavior |
|---|---|
| START | FAT-003 add child → FAT-004 QR |
| INTENT | Link child phone |
| SCREENS | FAT-004/005/006; CHD-001/002/003 |
| ACTION | Show mock QR; child “scan” |
| SYSTEM LOGIC | TTL timer renew; FakeCameraPermissionSeam |
| DATA | Mock token UI only |
| BACKEND/SYNC | pairing_token table **unused** |
| CHILD EFFECT | Navigation success UI — **no MDM enrollment** |
| NOTIFICATION | None real |
| RESULT | Link success celebration |
| FAILURE | Camera deny → repair CTA (UI-003) |
| **Status** | **F** |

---

## J3 — Father sets screen time; child mirror

| Step | Current behavior |
|---|---|
| START | FAT-032 |
| INTENT | Cap / schedules / wallets |
| ACTION | Toggle windows; save policy |
| SYSTEM LOGIC | Prefs* memory repos; TimeEngine; PolicySyncBus |
| DATA | Memory JSON maps |
| BACKEND/SYNC | In-process bus statuses |
| CHILD EFFECT | ChildScreenTimeMirror / CHD-004 updates **same session** |
| NOTIFICATION | N/A |
| RESULT | Remaining time UI updates |
| FAILURE | OfflineQueued status simulation |
| **Status** | **A in-app / H device** |

---

## J4 — Child requests time; parent decides

| Step | Current behavior |
|---|---|
| START | Child request UI / FAT-033 inbox |
| INTENT | Extra minutes |
| SYSTEM LOGIC | TimeRequestService; mother ceiling; PolicyEngine deposit path on approve |
| DATA | Memory requests |
| CHILD EFFECT | Decision seam |
| NOTIFICATION | Simulated |
| **Status** | **A in-app / H device**; route wiring for CHD-020 may be **G** |

---

## J5 — Web block + unlock

| Step | Current behavior |
|---|---|
| START | FAT-036 categories; child WebBlockPage |
| INTENT | Filter / temporary unlock |
| SYSTEM LOGIC | WebFilterEvaluator; WebUnlockService; mother observer denied |
| DATA | Policy + allow-list memory |
| CHILD EFFECT | Same verdict preview parity (UI-009) |
| **Status** | **A in-app / H network filter** |

---

## J6 — SOS

| Step | Current behavior |
|---|---|
| START | CHD-005 or FAT-018 |
| INTENT | Emergency |
| SYSTEM LOGIC | MockSosFire; SosLadder parents fixed; NotificationDelivery critical always |
| DATA | InMemory sos repos |
| BACKEND | sos_alert table unused |
| CHILD/PARENT EFFECT | UI progression only |
| **Status** | **B/F** — safety **never entitlement-gated** (tested) but **not real emergency telecom** |

---

## J7 — Mother invite + permission

| Step | Current behavior |
|---|---|
| START | FAT-008 → FAT-009 → FAT-031 (father) |
| INTENT | Delegate co-parent |
| SYSTEM LOGIC | MotherLevel gates; RoleGuard |
| DATA | Memory level repo |
| **Status** | **B/F** |

---

## J8 — Instant lock

| Step | Current behavior |
|---|---|
| START | FAT-037 |
| INTENT | Lock child now |
| SYSTEM LOGIC | DeviceLockService; mother FULL; father unlock supersedes; chat/quran/sos exempt |
| CHILD EFFECT | In-app lock UI / bus |
| **Status** | **A in-app / H OS** |

---

## J9 — Education assign → child submit → parent results

| Step | Current behavior |
|---|---|
| START | Studio FAT-040…049; child learn |
| INTENT | Assign + review |
| SYSTEM LOGIC | InMemory education repos; attribution reward uses Minutes/PolicyEngine in tests |
| GAP | **P15-EDU-006/007 OPEN** — submit≠FAT-050 feed; materials toast-only |
| ROUTES | Many child learn routes still Placeholder |
| **Status** | **G/B** |

---

## J10 — Chat / call

| Step | Current behavior |
|---|---|
| START | FAT-021/022/023; CHD-007… |
| INTENT | Family communication |
| SYSTEM LOGIC | InMemory conversation/call repos; ChatAvailability entitlement-free |
| BACKEND | LiveKit mentioned in CSV notes — **SDK NOT in pubspec** |
| **Status** | **C/F** |

---

## J11 — Location / geofence

| Step | Current behavior |
|---|---|
| START | FAT-014…017; CHD-024 arrival |
| INTENT | Know where child is |
| SYSTEM LOGIC | InMemory location/safe zone |
| GPS SDK | **H NOT FOUND** |
| **Status** | **C/F** |

---

## J12 — Billing vs safety

| Step | Current behavior |
|---|---|
| START | FAT-056/057 |
| INTENT | Subscribe |
| SYSTEM LOGIC | MockEntitlement; RoleGuard father-only |
| SAFETY | SOS.fire + chat usable when plan expired (arch tests) |
| **Status** | **F** billing / **A** ungated safety rule |

---

## Cross-journey truth

For every journey above, **BACKEND/SYNC** is either **none** or **in-process mock**.  
**CHILD DEVICE EFFECT** never means Android/iOS system restriction in the current repository.
