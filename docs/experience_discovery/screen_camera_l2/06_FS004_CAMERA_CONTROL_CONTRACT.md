# 06 — FS-004 Camera Control Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · SC-OD-02 · SC-OD-04 · SC-OD-07 · SC-SF-12  
**Non-authority:** FAT-034 mock `camera` package row as OS control  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Two planes (normative)

| Plane | System | Controls |
|---|---|---|
| **Package access** | **FS-003** | Allow/Block/Exempt for Camera **app package(s)** |
| **OS/device camera policy** | **FS-004** | Device-level camera restriction **intent** |

**Law:** Blocking a Camera package **does not equal** disabling the hardware/OS camera.  
App Control package DENY does **not** automatically mean FS-004 camera DENY.

---

## 2. Product intent

Parents may require **device-level camera restriction** for a child (baseline + override).  
Mechanism remains **T-SC-01** after verification under hybrid honesty (SC-OD-04).

---

## 3. Explicit protected / exception matrix (SC-OD-07)

| Class | Rule |
|---|---|
| **SOS** | Governed by SOS Final; FS-004 must not make emergency access unreachable; **no SOS audio** |
| **QR / enrollment camera** | Explicit Family OS exception when flow requires camera |
| **Approved Family OS camera workflows** (e.g. Studio capture by authorized parent roles) | Explicit exception / role-gated — not silent child bypass |
| **Family OS call camera** | Allowed only where the call feature **explicitly requires** it and policy exception permits |
| **Quran** | Ordinary required access path **not controlled by FS-004**; remains unaffected |
| **Required Family Chat** | Not denied by FS-004 camera policy for ordinary required use |

Exceptions are **audited policy objects**, not silent bypasses.

---

## 4. Capture prevention (screen) — related

Where platform can enforce screenshot/recording **prevention**, FS-004 may express prevention intent (SC-OD-03).  
**Forbidden:** claiming universal third-party capture blocking.  
Family OS **sensitive surface protection** is the Protect pillar (SC-OD-01) — mechanism **T-SC-02**.

---

## 5. Microphone

**OUT** (SC-OD-05). This contract does not define mic allow/block.

---

## 6. Interaction with (A) FakeCamera / real plugins

Future real camera plugins for QR/Studio must reconcile with OS restriction via **explicit exceptions** (SC-OD-07) and honesty (**T-SC-09**) — not by ignoring FS-004 policy.
