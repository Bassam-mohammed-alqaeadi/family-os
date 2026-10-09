# 02 — FS-007 Role Matrix (L3)

**Authority:** AI-OD-04 · AI-OD-05 · AI-OD-06 · AI-OD-11  
**Master:** [13_FS007_L3_MASTER_CONTRACT.md](13_FS007_L3_MASTER_CONTRACT.md)

| Capability | Primary | Full | Partner | Observer | Child |
|---|---|---|---|---|---|
| Configure Search/Image classify tools | ✅ | ✅ | ❌ | ❌ | ❌ |
| Link/view FS-004 screenshot policy | ✅ | ✅ | view | view | ❌ |
| Apply / rollback signed models | ✅ | ✅ | ❌ | ❌ | ❌ |
| Receive safety notifications | ✅ | ✅ | ✅ | ❌ | ❌ |
| Open review tickets | ✅ | ✅ | ✅ | ❌ | ❌ |
| See metadata + redacted preview | ✅ | ✅ | ✅ | ❌ | ❌ |
| See full raw by default | ❌ | ❌ | ❌ | ❌ | ❌ |
| Mark FP / resolve ticket | ✅ | ✅ | ✅ | ❌ | ❌ |
| Emit human-approve suggest → WF/AC/Mode | ✅ | ✅ | ✅ | ❌ | ❌ |
| View transparency card | — | — | — | — | ✅ |
| Configure / review admin | ❌ | ❌ | ❌ | ❌ | ❌ |
| Device-possession AuthZ | ❌ forever | ❌ | ❌ | ❌ | ❌ |

Observer may see non-push **status summary** on a shared parent dashboard if product chrome exposes read-only honesty — **no** ticket actions, **no** FS-007 push (AI-OD-04).
