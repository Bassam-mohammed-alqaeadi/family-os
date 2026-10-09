# 04 — FS-004 Policy and AuthZ Discovery

**Mode:** Record **current evidence** and **open Owner questions**. Do not freeze L2.  
**Vocabulary target (global):** Primary Parent · Co-Parent · Child — Stage-1 Father/Mother = non-authority  
**Master:** [10_FS004_DISCOVERY_CLOSURE_REPORT.md](10_FS004_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Documented policy language (not target law yet)

| Source | Claim |
|---|---|
| **P-7** Policy Register | Smart monitoring **with child knowledge**: search / image / **screenshots**; father switches + **app picker**; on detection save snapshot & report; **permanent transparency card** on child |
| Prototype Smart Watch | `screenshot` flag + `screenshotApps` picker UI |
| FAT-065 registry | Smart alerts / monitoring tools including screenshot tool |
| Domain 1 audio | Ambient recording + prevent screenshot on **evidence playback** (in-app protection intent) |
| P-4 Register | SOS location+**audio** — **conflicts** SOS Final (audio excluded) |

---

## 2. Current AuthZ evidence (Stage-1 — non-authority)

| Surface | Observed AuthZ | Classification |
|---|---|---|
| FAT-034 app block (incl. mock Camera) | Father + Mother Partner/Full mutate (Stage-1) — **rejected as FS-003 target**; FS-003 L2: Primary+Full configure | **MOCK** + **C** vs FS-003 frozen |
| FAT-065 Smart Alerts toggles | Parent UI; exact role matrix not FS-004-specific | **MOCK** |
| Studio camera (A) | Parent capture; child lean / observer blocked (l10n) | **MOCK** (A) |
| QR camera (A) | Child device permission repair | **MOCK** (A) |

**No dedicated FS-004 RoleGuard / RBAC matrix exists.**

---

## 3. Inherited global AuthZ constraints (must respect in future L2)

| Constraint | Source |
|---|---|
| RBAC only; never device-possession inference | SOS / FS-002 / FS-003 SF |
| Primary ≠ Co-Parent Full for sensitive/owner-only classes | WF-SF-06 / APP-SF-03 |
| Child transparency for monitoring (P-7 spirit) | Policy Register |
| SOS reachable; never gated by subscription | Constitution / SOS Final |
| AI suggests only | Constitution |

---

## 4. Owner questions (Q-SC-*) — OPEN · not silently closed

| ID | Question | Alternatives (examples) | Blocks L2? |
|---|---|---|---|
| **Q-SC-01** | FS-004 v1 scope: **prevent** capture, **monitor** capture (P-7), **protect Family OS surfaces**, or combination? | A prevent · B monitor · C protect · D combo | **Yes** |
| **Q-SC-02** | Camera control granularity? | Device-wide OS off · per-app (FS-003) · per-Mode · category | **Yes** |
| **Q-SC-03** | “Screen control” = block child screenshots/recordings, parent receive screenshots, or both? | Block · Monitor · Both | **Yes** |
| **Q-SC-04** | Is blocking the Camera **package** (FS-003) sufficient, or is **hardware/OS camera disable** required? | Package only · OS disable · Hybrid honesty | **Yes** |
| **Q-SC-05** | Include Domain 1 ambient/surround **microphone** recording in FS-004? | In · Out · Separate system | **Yes** |
| **Q-SC-06** | iOS honesty promise when Android-class controls unavailable? | Unsupported honesty · Different feature set | **Yes** |
| **Q-SC-07** | Safety exceptions when camera blocked: SOS, parent video call, Quran recitation, Studio? | Explicit matrix | **Yes** |
| **Q-SC-08** | Reconcile P-4 “SOS audio” vs SOS-final “no audio” for any mic work? | Follow SOS-final · Reopen SOS · N/A if mic out | **Yes** if mic in |
| **Q-SC-09** | Does P-7 screenshot monitoring live under **FS-004** or remain **Smart Alerts (FAT-065)**? | FS-004 · FAT-065 · Split | **Yes** |
| **Q-SC-10** | Must child transparency card list screenshot/image/search tools (P-7)? | Mandatory · Optional · Later | **Partial** |
| **Q-SC-11** | Who configures / who decides exceptions (align FS-002/003 patterns)? | Primary+Full configure · Partner tickets · etc. | **Yes** |
| **Q-SC-12** | Policy scope: family baseline + child override (like WF/AC)? | Family · Per-child · Baseline+override | **Yes** |

**Silent closures:** **NONE**.

---

## 5. AuthZ reality today

| Reality |
|---|
| No FS-004 policy objects |
| No Primary/Co-Parent matrix for camera/screenshot control |
| Stage-1 Partner may appear on adjacent screens — **must not** become FS-004 law without Q-SC-11 |

---

## 6. Child authority today

| (A) QR/Studio | Child may need camera permission for QR; Studio is parent-lean |
| (B) Parental control | Child has **no** FS-004 admin; transparency for screenshot tools **not implemented** in MonitoringFeature set |
