# QUESTIONS — owner decision channel

When an agent hits ambiguity: stop, append a question below, do not guess.  
Owner answers under the question with a date.

---

### Q-PREFLIGHT-001 — Flutter / Dart pin (blocks Stage 1)
**Date asked:** 2026-09-20  
**Why:** FVM + pubspec must match every agent session (handoff/10 A1).  
**Question:** Which Flutter stable channel version should we pin (e.g. 3.24.x / latest stable you want named)?  
**Answer:** use my flutter version that's existing in my pc , i don't need to struggle with other versions or graddle issues so use my ones  
**Resolved (2026-09-20):** Flutter **3.35.7** (stable) · Dart **3.9.2** · path `C:\src\flutter` · no FVM — pin documented in `app/README.md` + `app/pubspec.yaml` `environment`

### Q-PREFLIGHT-002 — Arabic font (blocks F0-A)
**Date asked:** 2026-09-20  
**Why:** handoff/06 left IBM Plex Sans Arabic vs Cairo open; tokens/gallery need a literal choice.  
**Question:** Bundle **IBM Plex Sans Arabic** or **Cairo** (both OFL)?  
**Answer:** use the existing best one  that suites this app  
**Resolved (2026-09-20):** **IBM Plex Sans Arabic** (400/700/800) — primary in `prototype/15_DESIGN_SYSTEM.md`; Cairo remains alternate only

<!-- Append new questions below this line -->
