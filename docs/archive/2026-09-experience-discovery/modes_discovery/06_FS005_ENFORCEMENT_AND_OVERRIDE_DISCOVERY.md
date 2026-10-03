# 06 — FS-005 Enforcement and Override Discovery

**Mode:** How Modes affect enforcement and overrides today — honesty first.  
**Master:** [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Enforcement plane today

| Layer | Behavior | Honesty |
|---|---|---|
| In-app TimeEngine | If `modeActive` and not (`appAllowedInMode` \|\| `hasModeException`) → `deniedMode` | Algebra **IMPLEMENTED** |
| Callers supplying flags | ScheduleWindowQuery; tests; not full feature wiring of allow-lists from Modes | **PARTIAL** |
| Child OS app launch block | None from Modes | **MISSING** |
| OS Focus / Screen Time API | Documented as unsupported until proven | **MISSING** |
| FAT-085 UI | Toggle = prefs + bus; honesty banner | **MOCK/SIMULATION** of device-wide mode |

Engineering note (`09_FAT_085_ENGINEERING.md`): in-app activation = **SIMULATED overlay** unless ENFORCING; OS Focus = H.

---

## 2. Override ladder (Register §2 / TimeEngine)

Order already coded:

1. Instant lock  
2. Permanent block  
3. Active mode (+ exceptions)  
4. Daily limit  
5. Earned balance  

Modes **cannot** outrank instant lock or permanent block in current algebra — aligns with Register “lock above modes” and FS-003 “cannot reopen Permanent Block” spirit.

---

## 3. Overrides intersecting Modes

| Override | Stage-1 | Mode interaction |
|---|---|---|
| ModeException | Flag only | Should pierce mode deny |
| Temporary Grant | ST | Ruling C: `GrantOnModeStart` complete \| freeze — UI **MISSING** |
| App Access Exception (FS-003) | L2 law elsewhere | Must stay distinct from ModeException |
| Web temporary allow | FS-002 | Modes must not rewrite allowList |
| Wallet / Unlimited | ST | After mode allow, still apply |

---

## 4. What Modes must not do (sibling L2 evidence — not FS-005 freeze)

| Forbidden pattern | Source |
|---|---|
| Duplicate package policy store | FS-003 |
| Second AC/WF/SC scheduler | FS-002/003/004 |
| Silently rewrite URL lists | FS-002 |
| Permanently remove camera/screenshot policy | FS-004 |
| Own minutes / grants / wallets | Screen Time Final |
| Own geofence definitions | FS-001 |
| Gate SOS | SOS Final / Rules 9 & 11 |

---

## 5. Emergency behavior

| Rule | Evidence |
|---|---|
| SOS under all conditions | Register P-4; ST final correction; child screens keep SOS |
| Chat / Quran untouchable at time expiry | Register C-1 / Rule 11 — still apply under mode allow path |

---

## 6. Platform dependencies (discovered, not chosen)

| Platform | Candidate mechanisms (evidence/docs only) | Selected? |
|---|---|---|
| Android | Digital Wellbeing / Focus, DPM, UsageStats, Accessibility | **No** |
| iOS | Screen Time / FamilyControls / Focus filters | **No** |

**T-MODE-02** remains open.

---

## 7. Child-device handling

| Concern | Evidence |
|---|---|
| Acknowledgement of mode policy | **MISSING** |
| Offline last-known activation | Bus retains; prefs memory — **PARTIAL** |
| Multi-device same child | **MISSING** |
| Enforcement honesty badge pattern | Exists elsewhere; FAT-085 has host banner, not capability matrix |
