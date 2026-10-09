# 06 — FS-007 Child Transparency (L3)

**Authority:** AI-OD-06 = B+B1 · AI-OD-04 · P-7 · FS-004 SC-OD-09  
**Master:** [13_FS007_L3_MASTER_CONTRACT.md](13_FS007_L3_MASTER_CONTRACT.md)

---

## W-C01 Permanent transparency card

**Required when** any of Search / Image / Screenshot monitoring-or-classify is configured on.

| Row | Shows |
|---|---|
| Search analysis | off / active / degraded / unsupported / stale |
| Image classification | same |
| Screenshot monitoring | same (policy owned by FS-004; FS-007 reflects effective state) |

**Copy requirements:**

- Name **on-device / offline classification** when local plane applies.  
- Never claim “always watching everything.”  
- Never claim active classify when model missing/integrity failed.  
- No toggles, no ticket list, no parent previews, no raw content.

## W-C02 Entry points

- Privacy / “What is collected” / monitoring honesty hub may host the card.  
- Must remain reachable without parent PIN theater that hides the card while tools are on.

## Degraded example (normative intent)

> Image classification: on, but model update needed — not classifying until update applies.
