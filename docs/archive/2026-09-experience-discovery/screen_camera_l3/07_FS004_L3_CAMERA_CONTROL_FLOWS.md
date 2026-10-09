# 07 — FS-004 L3 Camera Control Flows

**Authority:** SC-OD-03 · SC-OD-07 · SC-OD-08 · Camera Control Contract L2  
**Separates:** OS/device camera (FS-004) ≠ Camera **package** (FS-003)  
**Master:** [12_FS004_L3_MASTER_CONTRACT.md](12_FS004_L3_MASTER_CONTRACT.md)

---

## C1 — Enable OS camera restriction

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Entry | SC-P-CAMERA |
| Preconditions | Child context; role configure |
| Policy | `cam_restrict` intent → on |
| UI | Intent toggle; honesty; package-vs-OS education; protected-use list |
| Enabled | Save (configure roles) |
| Forbidden | Partner save; claim package block; claim mic; fake enforced before ack+plane |
| Success | Version bump; `pending_policy` until ack; plane may still be unsupported |
| Pending | Parent: pending_delivery; Child: last-acked until ack |
| Offline | offline_queued |
| Degraded | Intent on + residual risk copy |
| Unsupported | Intent may persist; **no** “camera off” success; remediation honesty |
| Failure | Rollback UI / retry outbox |
| Audit | `sc_policy.saved` (camera restrict) |
| Notify | Optional parent ack of save; child transparency if monitoring also on — camera restrict alone does not require surveillance notice |
| Child | Sees status Restricted after ack when plane can enforce; else honesty-aware messaging |
| Nav | Stay / back to child effective |

---

## C2 — Disable OS camera restriction

| Field | Spec |
|---|---|
| Transition | cam_restrict off |
| Modes | If Mode had tightened, Mode may still show tighten — Modes owns schedule; FS-004 may show Mode chip |
| Forbidden | Modes silently permanently clearing without parent FS-004 save |
| Audit | policy saved |

---

## C3 — Child hits restricted camera (OS)

| Field | Spec |
|---|---|
| Entry | Attempt camera use outside protected exception |
| UI | SC-C-DENY with source **FS-004 OS camera** |
| Distinct from | FS-003 package deny (different copy + CTA to App Control) |
| Allowed | Exception request if eligible; SOS/Chat/Quran |
| Forbidden | Implying mic muted; implying all apps blocked |

---

## C4 — Protected QR / enrollment

| Field | Spec |
|---|---|
| Preconditions | Explicit exception **or** frozen protected-matrix allows enrollment camera |
| UI | Enrollment camera works; parent may see “protected path / exception active” |
| Policy | Underlying `cam_restrict` **unchanged** |
| After | Exception expires → restrict resumes without re-save |
| Audit | `sc_exception.*` / protected-path event |
| Forbidden | Silent permanent weaken of FS-004 |

---

## C5 — Studio / required call camera

| Field | Spec |
|---|---|
| Preconditions | Approved Studio capture / required Family OS call camera per product matrix |
| UI | Explicit exception/protected chrome — not silent bypass |
| Scope | Only Family OS workflow — not third-party camera free-for-all |
| End | Return to restricted state |
| SOS | Reachability preserved; **no** SOS audio in FS-004 |

---

## C6 — Concurrent FS-003 Camera package deny

| Field | Spec |
|---|---|
| UI | Both reasons may appear: “App blocked” + “Device camera restricted” |
| CTAs | App Control **and** Screen & Camera separately |
| Forbidden | Merging into one generic “camera blocked” |

---

## C7 — Capability honesty for camera plane

| Plane | Parent claim allowed |
|---|---|
| enforced | “Restricted on this device” after ack |
| degraded | “Limited restriction” |
| pending_policy | “Waiting for device” |
| unavailable / disabled_by_permission | Remediation CTA |
| unsupported | “Not available on this platform” — **no Android-parity claim on iOS** |
| unknown | “Checking…” — no protected claim |

---

## State transitions (camera intent)

```
cam_off ──save──► cam_on + pending_policy
cam_on ──ack+enforced──► parent may claim enforced
cam_on ──ack+unsupported──► honesty unsupported (intent may remain)
exception_pending ──approve──► exception_active (policy intent unchanged)
exception_active ──expire/revoke──► restrict effective again
```

**T-SC** platform API selection deferred — UX only consumes honesty states.
