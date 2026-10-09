# 02 — FS-006 L3 Role Matrix

**Authority:** SOS Final OD-01…04 · L2 role contract  
**Master:** [13_FS006_L3_MASTER_CONTRACT.md](13_FS006_L3_MASTER_CONTRACT.md)

**Observer discrepancy:** Stage-1 may allow Observer ack — **implementation debt**. Target UX = frozen matrix below (Observer **no** ack).

---

## 1. Action × role

| Action | Primary | Full | Partner | Observer | Child |
|---|---|---|---|---|---|
| Open SOS entry / fire | — | — | — | — | ✓ |
| View active incident | ✓ | ✓ | ✓ | ✓ essential | Own |
| Acknowledge | ✓ | ✓ | ✓ | **✗** | ✗ |
| Escalate trusted | ✓ | ✓ | ✓ | **✗** | ✗ |
| Resolve | ✓ | ✓ | ✓ | **✗** | ✗ |
| False-alarm cancel | — | — | — | — | ✓ (own + confirm) |
| Configure ladder/contacts/Panic Quiet | ✓ | ✓ | ✗ | ✗ | ✗ |
| Break-glass | ✓ | ✓ | ✗ | ✗ | ✗ |
| View delivery honesty | ✓ | ✓ | ✓ | ✓ | Simplified |
| View evidence pack | ✓ | ✓ | ✓ limited | limited | Status only |
| Browse audit | ✓ | ✓ | limited | limited | ✗ |
| Contact child | ✓ | ✓ | ✓ | ✓ | Contact parents |
| Approve AI SOS suggestion | ✓ | ✓ | ✗ | ✗ | ✗ |
| Reach Chat / Quran | always | always | always | always | always |

---

## 2. Surface visibility

| Surface | Primary | Full | Partner | Observer | Child |
|---|---|---|---|---|---|
| Trigger / HOLDING | — | — | — | — | R/W |
| Active critical | R | R | R | R | R/W cancel |
| Incident console | R/W | R/W | R/W (−config/−BG) | R (−ack/−esc/−res) | — |
| Setup | R/W | R/W | — | — | — |
| Break-glass sheet | R/W | R/W | — | — | — |
| Audit | R | R | R− | R− | — |
