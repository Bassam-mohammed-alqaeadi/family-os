# 04 — FS-004 L3 Flow Catalog

**Authority:** SC-OD-* · L2 contracts  
**Master:** [12_FS004_L3_MASTER_CONTRACT.md](12_FS004_L3_MASTER_CONTRACT.md)

Each flow: actor · entry · preconditions · state · UI · allowed/forbidden · success · pending · offline · degraded · unsupported · failure · audit · notify · child transparency · nav.

---

## F01 — Open hub

| Field | Spec |
|---|---|
| Actor | Any parent |
| Entry | Shell → Screen & Camera |
| UI | Honesty strip; pillar chips; pending tickets; child list |
| Forbidden | “Fully protected” if not enforced+acked; mic section |
| Offline | Last-known honesty + queued badge |
| Audit | none |
| Nav | → FAMILY / CHILD / EXCEPT / OBS / AUDIT / DEVICE |

---

## F02 — Edit family baseline

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Entry | SC-P-FAMILY |
| State | Baseline document |
| Allowed | Toggle prevent/monitor/protect defaults |
| Forbidden | Partner; mic; claim universal capture block |
| Success | policyVersion++; pending_delivery |
| Offline | offline_queued |
| Audit | `sc_policy.saved` |
| Child transparency | Updates only after ack if monitoring default on for children with override off |

---

## F03 — Edit child override

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Entry | SC-P-CHILD |
| State | Override wins |
| Allowed | Per-child pillar config |
| Success | Versioned override; devices pending |
| Audit | `sc_policy.saved` (override) |

---

## F04 — Configure OS camera restriction

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Entry | SC-P-CAMERA |
| UI | Clear copy: **not** the same as blocking Camera app (link FS-003) |
| Transition | cam_intent on/off |
| Success | Saved; honesty pending until ack+plane |
| Unsupported | Show unsupported — no success claim |
| Audit | camera restrict change |
| Detail | [07](07_FS004_L3_CAMERA_CONTROL_FLOWS.md) |

---

## F05 — Configure capture prevention

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Entry | SC-P-PREVENT |
| UI | “Where platform can prevent”; residual risk if degraded |
| Forbidden | “Blocks all third-party screenshots everywhere” |
| Unsupported | Honesty; toggle may save intent but claim disabled |
| Audit | prevention change |

---

## F06 — Configure monitoring + scope

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Entry | SC-P-MONITOR |
| UI | On/off; scope/app selection (**T-SC-05** storage); preview child transparency |
| Forbidden | Silent on; second store in Smart Alerts; full open-app feed default |
| Success | mon_on + scope; child transparency required after ack |
| Audit | `sc_monitor.*` |
| Notify | monitoring activated/deactivated |
| Detail | [08](08_FS004_L3_CAPTURE_MONITORING_FLOWS.md) |

---

## F07 — Deactivate monitoring

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Transition | mon_on → mon_off |
| Child | Transparency removed/updated after ack |
| Audit | `sc_monitor.deactivated` |

---

## F08 — Configure surface protection

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Entry | SC-P-PROTECT |
| UI | Protect Family OS sensitive surfaces; mechanism TBD honesty |
| Forbidden | Mic; universal third-party claim |

---

## F09 — Explicit exception request (child)

| Field | Spec |
|---|---|
| Actor | Child |
| Entry | SC-C-STATUS / DENY → SC-C-REQ |
| Preconditions | Eligible workflow; not mic/SOS audio |
| Transition | exception_pending |
| Audit | `sc_exception.requested` |
| Notify | Primary+Partner+Full |
| Forbidden | Silent erase of camera restrict policy |

---

## F10 — Decide exception

| Field | Spec |
|---|---|
| Actor | Primary, Partner, Full |
| Entry | SC-P-EXCEPT-D |
| Approve | exception_active timed/scoped — **underlying policy unchanged** |
| Deny | ticket denied |
| Duration | Placeholder **T-SC-11** — no invented number |
| Audit | approve/deny/revoke |
| Child | Status update; transparency unchanged unless monitoring flag changes |

---

## F11 — QR / enrollment protected path

| Field | Spec |
|---|---|
| Actor | Child / parent per enrollment |
| Preconditions | Explicit exception or protected matrix allows Family OS QR camera |
| UI | Enrollment continues; parent sees exception/protected indicator if restrict on |
| Forbidden | Presenting as “camera unrestricted for all apps” |
| Audit | exception use / protected path event |

---

## F12 — Studio / call camera exception

| Field | Spec |
|---|---|
| Actor | Authorized roles for Studio; call participants when feature requires |
| UI | Explicit “Family OS camera exception” affordance — not silent |
| Forbidden | Child using Studio to bypass OS restrict without policy |
| Nav | Returns to restrict after flow ends |

---

## F13 — View observations

| Field | Spec |
|---|---|
| Actor | Parents (Partner/Observer view) |
| Entry | SC-P-OBS |
| UI | Only real `sc_capture.observed`; empty if unsupported/off |
| Forbidden | Fake/demo planted observations as live; full surveillance timeline default |
| Degraded | Banner: observation limited |

---

## F14 — Source-of-restriction

| Field | Spec |
|---|---|
| Entry | SC-P-SOD / SC-C-DENY |
| UI | Distinct codes for FS-004 camera / prevention / FS-003 package / Mode / ST / WF |
| CTAs | Only owning system |

---

## F15 — Device honesty review

| Field | Spec |
|---|---|
| Entry | SC-P-DEVICE |
| UI | Per-device plane per pillar where independent; ack versions; remediation |
| Forbidden | Protected claim on unsupported/unknown/unavailable |
| Audit | `sc_plane.state_changed` |
| Detail | [09](09_FS004_L3_ENFORCEMENT_HONESTY_UX.md) |

---

## F16 — Offline parent configure

| Field | Spec |
|---|---|
| UI | offline_queued |
| Forbidden | “Saved to child / enforcing now” |
| On reconnect | Replay outbox |

---

## F17 — Offline child

| Field | Spec |
|---|---|
| Enforce | Last-acked intents |
| Transparency | Last-acked monitoring flag |
| SOS/Chat/Quran | Reachable |

---

## F18 — Modes interaction

| Field | Spec |
|---|---|
| UI | Mode tighten chip |
| Nav | → FS-005 |
| Forbidden | FS-004 schedule editor; Mode control that permanently clears FS-004 |

---

## F19 — Deep link FS-003 Camera package

| Field | Spec |
|---|---|
| From | SC-P-CAMERA educational link |
| Copy | “Block Camera app ≠ turn off device camera” |
| Nav | App Control detail for package |

---

## F20 — Smart Alerts entry (non-policy)

| Field | Spec |
|---|---|
| Entry | Optional FAT-065 shell |
| Behavior | Opens FS-004 monitoring config (single source) |
| Forbidden | Local toggle that writes a second policy |

---

## F21 — Audit browse

| Field | Spec |
|---|---|
| Entry | SC-P-AUDIT |
| Visible | Policy, monitor lifecycle, exceptions, plane, real observations |
| Forbidden | Full open-app stream as default |

---

## F22 — Observer path

| Field | Spec |
|---|---|
| Allowed | Hub/summary/honesty/obs/audit view |
| Forbidden | All configure/decide |

---

## F23 — iOS / unsupported path

| Field | Spec |
|---|---|
| UI | Per-pillar `unsupported` honesty |
| Forbidden | Fake Android parity claims |

---

## F24 — SOS / protected reachability

| Field | Spec |
|---|---|
| Always | SOS chrome reachable |
| Forbidden | FS-004 mic/audio; denying Required Chat/Quran ordinary paths |
