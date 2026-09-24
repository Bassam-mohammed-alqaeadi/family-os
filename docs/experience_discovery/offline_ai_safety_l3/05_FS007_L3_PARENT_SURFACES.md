# 05 — FS-007 Parent Surfaces (L3)

**Master:** [13_FS007_L3_MASTER_CONTRACT.md](13_FS007_L3_MASTER_CONTRACT.md)  
**Note:** Textual wireframe contracts — not Flutter implementation.

---

## W-P01 Overview

- Honesty strip: capability state · model version · last synced  
- Counts: open tickets · notifies today  
- CTA: Tools · Tickets · Model  
- **Forbidden:** green “AI protected all children” without active plane

## W-P02 Tools

- Toggles: Search analysis · Image classification  
- Screenshot: **status + deep link to FS-004** (not a second policy editor)  
- Each row shows state chip from state matrix  
- Configure = Primary/Full only

## W-P03 Model / assets

- Current version · signature OK/fail · release notes summary  
- Apply / Rollback (Primary/Full)  
- Stale / missing / integrity_failed honesty  
- No vendor brand required in v1 UX

## W-P04 Notification

- Title: safety category + severity label  
- Sub: certainty · child alias · tool  
- Open → ticket if exists, else metadata-only detail  
- Not critical-alert SOS channel

## W-P05 Ticket list / detail

- List: open tickets gated by B1  
- Detail: **category · certainty · severity · provenance · model/policy versions · timestamp · tool**  
- **Redacted preview** region: content | `preview_unavailable` honest empty  
- Actions: Resolve · Dismiss FP · Suggest WF/AC/Mode (opens owning system approve UX)  
- **No** full raw default; **no** “block now” that mutates FS-002/003 silently

## W-P06 Devices ack

- Per enrolled child device: model version ack · tool states · last classify time  
- Multi-device skew honesty
