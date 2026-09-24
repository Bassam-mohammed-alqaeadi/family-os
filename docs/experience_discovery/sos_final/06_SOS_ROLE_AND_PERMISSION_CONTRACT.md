# 06 — SOS Role & Permission Contract

**Status:** FROZEN  
**SOS PRODUCT CONTRACT STATUS: FROZEN**  
**Source:** OD-01…04, RD-01…05, Q-SOS-RD-02A/02B/03A (all closed)

---

## Capability matrix (authoritative)

| Capability | Primary | Mother Full | Mother Partner | Mother Observer | Child |
|---|---|---|---|---|---|
| Trigger SOS | — | — | — | — | ✅ |
| Receive SOS (ungradeable) | ✅ | ✅ | ✅ | ✅ | — |
| View essential incident | ✅ | ✅ | ✅ | ✅ | Own |
| View full evidence timeline | ✅ | ✅ | ✅ | Essential only | Own limited |
| Contact child | ✅ | ✅ | ✅ | ✅ | Contact parent |
| Acknowledge | ✅ | ✅ | ✅ | ❌ | ❌ |
| Escalate (trusted **VERIFIED** only) | ✅ | ✅ | ✅ | ❌ | ❌ |
| Resolve | ✅ | ✅ | ✅ | ❌ | ❌ (cancel path only) |
| Cancel / false-alarm | ❌ | ❌ | ❌ | ❌ | ✅ (confirm) |
| Configure SOS settings | ✅ | ✅ | ❌ | ❌ | ❌ |
| Manage trusted contacts (max 5) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Manage escalation config | ✅ | ✅ | ❌ | ❌ | ❌ |
| Start/revoke backup verification | ✅ | ✅ | ❌ | ❌ | ❌ |
| Panic Quiet Mode configure | ✅ | ✅ | ❌ | ❌ | Effect on active UI only |
| **Break-glass invoke** | ✅ | ✅ | ❌ | ❌ | ❌ |
| Mute SOS receipt | ❌ forever | ❌ | ❌ | ❌ | ❌ |
| Gate SOS by subscription | ❌ | ❌ | ❌ | ❌ | ❌ |

**Break-glass AuthZ:** RBAC (role + MotherLevel). **Never** inferred from device ownership (Q-SOS-RD-02A).

---

## Break-glass allowlist (Q-SOS-RD-02B) — FROZEN

**ALLOWED temporarily:** lock/restricted shell bypass for SOS response; screen-time bypass for SOS response; web/app bypass for emergency communication/response; emergency communication surface; active SOS + location context; parent SOS notification handling.

**FORBIDDEN:** permanent policy/role/billing changes; disable SOS; disable audit; delete incidents/evidence; privacy/audit bypass; permanent exceptions; unlock-everything.

**Lifecycle:** START → REASON/CONTEXT → OVERRIDE_ACTIVE → EXPIRY → AUTO_REVOKE → AUDIT.

---

## Enforcement layers

1. **UI:** Hide/disable forbidden controls.  
2. **RoleGuard / RBAC:** FAT-028 edit + Break-glass = Primary/Full only.  
3. **API:** Reject forbidden transitions; reject escalate to non-VERIFIED; reject Break-glass for non-allowed roles.  
4. **Escalation engine:** Skip non-VERIFIED backups.  
5. **Break-glass:** Temporary override ticket with expiry + auto-revoke; Policy Kernel must not persist permanent policy mutation.

---

## “Essential incident information” (Observer)

Must include: child identity (repo), trigger time, lifecycle, location honesty, battery/connection summary, self delivery status, Contact child.  

Must exclude: Ack/Escalate/Resolve, Setup, Panic Quiet controls, Break-glass, verification admin.

---

## Nuclear configuration

- Contacts (add/remove/priority/verify)  
- Escalation delays/enablement  
- Panic Quiet Mode  
- Channel configuration (not mute SOS)  

Primary + Mother Full only.
