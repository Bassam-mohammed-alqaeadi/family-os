# 11 — FS-007 Cross-System UX Contracts (L3)

**Master:** [13_FS007_L3_MASTER_CONTRACT.md](13_FS007_L3_MASTER_CONTRACT.md)

| System | FS-007 may | FS-007 must not | UX contract |
|---|---|---|---|
| **Policy Kernel** | Emit typed SafetySignal; Kernel drives notify/ticket/suggest only | Become hidden policy engine | No “Kernel blocked app because AI said so” without human/contracted plane |
| **Identity / RBAC** | Honor AI-OD-04 | Device-possession AuthZ | RoleGuard on configure/model apply |
| **FS-001 Location** | — | Own geofences; location risk as FS-007 category v1 | No location AI product in FS-007 v1 |
| **FS-002 Web Filter** | Create **suggestion** to add keyword/URL for human approve | Silent list rewrite | Suggest CTA opens FS-002 approve UX |
| **FS-003 App Control** | Suggest app classification for human approve | Silent Allow/Block/Permanent Block | Same pattern |
| **FS-004 Screen & Camera** | Classify **approved** capture inputs; reflect screenshot tool state on child card | Second screenshot policy store; silent surveillance | Deep link to FS-004 for policy |
| **FS-005 Modes** | Suggest Mode config | Silent activate/deactivate/rewrite | Suggest → Modes human path |
| **FS-006 SOS** | — | Trigger/escalate/triage SOS | No SOS UI from FS-007 hits; self_harm_signal = notify/ticket only |
| **Screen Time** | — | Minutes/wallet mutation | — |
| **Advisor/Tutor/Insights** | Adjacent sovereignty patterns | Absorb LLM chat into FS-007; unlock on-device brain | Separate IA |
| **Offline / Sync** | Outbox signals/tickets | Fake sync success | G-1 honesty |
| **Audit / Notifications** | Append events; parent safety notifies | SOS critical channel misuse | — |

---

## Suggest hand-off pattern (normative)

Ticket action “Suggest block site / restrict app / tighten Mode” creates a **pending human approval** artifact in the **owning** system. Until approved, **no** enforcement change. Aligns AI-OD-02/09 and RULE 26 sovereignty.
