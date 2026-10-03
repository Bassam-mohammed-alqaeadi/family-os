# 06 — FAT-037 Instant Lock Engineering

**Screen:** SCR-FAT-037  
**Disposition:** EXTEND · precedence P1  

---

## Purpose
Engage/clear instant device lock (full / internet-only / timed per prototype). Highest entertainment precedence after safety exempt.

## Roles
Primary · Mother Full: lock. Partner/Observer: read status only. Father unlock supersedes mother (ADR-035) — show supersession banner when relevant.

## Hierarchy
Lock status hero · mode choices · exempt surfaces callout (Chat / Quran / **SOS always**) · confirm  

## Primary action
Lock now / Unlock  

## Policy
Sets `instantLock` → TimeEngine deniedLock for entertainment. Does **not** disable SOS.

## Honesty
SIMULATED vs ENFORCING badge. Do not claim OS lock until proven.

## Distinct from
FAT-085 modes · FAT-038 tamper · Temporary Grant  

## A11y
Destructive confirm sheet; large targets; RTL.
