# PHASE 1.75 — DOM-IDENTITY PREFLIGHT

**Date:** 2026-09-25  
**Task:** DOM-IDENTITY — Family Context + Roster  
**Broad codegen:** NOT ARMED  

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-IDENTITY PREFLIGHT
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: YES (split A then B)
```

## Verdict

### `READY_WITH_EXPLICIT_HONESTY_GUARD`

**Split:** YES  

| Slice | Scope |
|-------|--------|
| **DOM-IDENTITY-A** | `FamilyContextStore` → Local KV (`id_family_ctx`) |
| **DOM-IDENTITY-B** | Children display roster → Local KV (`id_roster`) — later |
| Defer | Full IdentityRuntime graph, cloud auth, FAT-027 members, schema v11 |

## Current path (A)

```text
IdentityRuntime.switchActiveFamily / session restore
  → FamilyContextStore.saveActiveFamily / loadActiveFamily
  → MemoryFamilyContextStore (process RAM)
```

## Target (A)

```text
LocalFamilyContextStore → kv_store ns=id_family_ctx
  via FsSessionKernel + refuse sqliteFallbackToMemory
```

IdentityRuntime remains sole identity-graph authority. Cloud auth stays MOCK-REMOTE.

## Honesty

Refuse Memory fallback for production bind. Demo fixture graph remains RAM (not claimed as cloud identity).
