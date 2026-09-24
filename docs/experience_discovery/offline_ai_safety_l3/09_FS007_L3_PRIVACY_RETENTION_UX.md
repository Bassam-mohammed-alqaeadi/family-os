# 09 — FS-007 Privacy and Retention UX (L3)

**Authority:** AI-OD-05 · AI-OD-12 · AI-SF-27  
**Master:** [13_FS007_L3_MASTER_CONTRACT.md](13_FS007_L3_MASTER_CONTRACT.md)

---

## Parent review privacy

- Default body: metadata + **redacted preview** if available.  
- `preview_unavailable`: empty honest state — **not** full-raw fallback.  
- Full raw **not** default; no “reveal full” unless a future OD adds step-up (not in v1 freeze).

---

## Retention UX

| Event | Preview | Metadata | Audit |
|---|---|---|---|
| Ticket open | May exist | Yes | Yes |
| Resolve / FP dismiss | **Purge** | Keep | Keep |
| Tool disable | Open tickets still follow purge-on-close | Keep per history policy | Keep |

Parent-facing copy may say previews are removed when a review is closed — **without inventing day counts**.

---

## Child privacy

Child does not see parent previews, tickets, or raw/redacted evidence.

---

## Minimization

Prefer signal + redacted preview over archives. No surveillance gallery product in FS-007 v1.
