# PHASE 1.75 — DOM-IDENTITY-B SEED CONTRACT

**Date:** 2026-09-25  
**Owner decision:** **B** — deterministic local demo seed (supersedes empty roster)  
**Provenance label:** `LOCAL_DEMO_SEEDED`

## Purpose

Populate durable Children display roster so FAT-012 (and coherent FAT-013 fallback) shows a complete local UI during Real Local Runtime validation.

## Not claimed

Seeded `locationLabel` / `lastSeenLabel` / `batteryLabel` / `timeLeftLabel` are **presentation demo strings**.  
They are **not** GPS, OS battery APIs, or live device telemetry.

## Authority

| Concern | Owner |
|---------|--------|
| Child membership IDs | `IdentityRuntime` (unchanged) |
| Display roster DTO | `ChildrenListRepository` Local KV |
| Location / battery facts | Other domains / native later — **not** this seed |

## Storage

| Item | Value |
|------|--------|
| Namespace | `id_roster` |
| Children key | `children:{familyId}` |
| Policies key | `shared_policies` |
| Envelope | `{ "provenance": "LOCAL_DEMO_SEEDED", "children": [ ... ] }` |

## Deterministic seed (aligned with Stage-1 IdentityRuntime)

| Family | Child IDs |
|--------|-----------|
| `fam_stage1` | `demo-child`, `child_b` |
| `fam_stage2` | `child_c` |

Seed runs **once** when a family key is missing/empty after Local open. Restart reloads persisted rows (stable).

## Merge with FAT-012

Managed IdentityRuntime children order wins; matching display IDs use seeded DTO fields; unmanaged lean placeholders only when no display row.
