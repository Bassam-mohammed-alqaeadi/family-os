# Acceptance Scenarios — the 5 walkthroughs (71 checks)
English port of `family-os/41_FINAL_WALKTHROUGH.md`. These passed 71/71 against the frozen prototype on 2026-09-18 and become **device acceptance tests** for phases F3–F6.

## Binding execution rules
1. **Walk like a human, not a programmer**: navigation to a screen is valid only if its button actually exists in the current screen's rendered view (screen + hub grid + tab bar + floating buttons). Direct jumps = step failure.
2. Every step is a triple: action → expected (from blueprint/contracts) → measured from the running app.
3. Interactions are real: where the scenario requires a tap (choosing a duration, completing a thikr, rotating a question), the actual handler runs and its effect on state and UI is asserted.
4. A single ❌ fails the scenario; fix before declaring results.

## S1 · A new father starts from zero (phase F3)
FAT-001 create family → FAT-002 wizard → FAT-003 add Khaled → FAT-004 QR link → FAT-005 permissions explained → FAT-006 link success 🎉
Expected: every step's button visible in its predecessor; FAT-005 explains the WHY of each permission; FAT-006 celebrates.

## S2 · Father's morning — reassurance at a glance (F3)
Open FAT-010 → read today cards → Khaled completing his athkar triggers the "blessing" card (real interaction: sayThikr to 10/10) → pending time request → FAT-033 → back → ✨ Family Advisor FAT-074 (floating button).
Expected: requests are minutes-only with father decision; advisor suggests, never decides.

## S3 · Father manages Khaled (F4)
FAT-012 → FAT-013 child profile → his tools from INSIDE the profile: screen time / apps / filtering / instant lock / Quran → FAT-064 growth map (interaction: rotate the dinner question) → back to profile.
Expected: every tool opens from its card inside the profile (per-child law G-5) and speaks about Khaled specifically. **In Flutter: must equally pass for Noura(11) and Saad(8) — parametric contract.**

## S4 · Khaled lives his full day (F5)
CHD-004 my day → tasks CHD-022 → learning CHD-012 → quiz CHD-015 → Quran portion CHD-025 → "me" CHD-010 → wallet CHD-019 (expected: self-competition card + badge cabinet + per-app wallets) → focus CHD-018 → its sounds CHD-035 (expected: return-to-session button — closed loop) → time request CHD-020 (interaction: choose 15 then 60 — highlight follows exclusively) → time expiry CHD-021 (expected: family chat & Quran never lock) → SOS CHD-005 via floating button (expected: long-press live) → family CHD-007 → call fun CHD-036.

## S5 · Edges & sovereignty (F6)
FAT-025 settings → router FAT-078 (interaction: setup guide opens with its steps) → subscription FAT-057 (expected: 3-day reminder pledge + cancel flow confirms forever-free safety) → privacy FAT-059 (interaction: double-confirm wipe, step 1 → step 2 with 7-day window) → audit log FAT-060 (append-only + actor identity) → trial mode FAT-007 (from FAT-004).
**+ Sovereignty check**: with child role, the four sensitive screens (FAT-056/057/059/060) must block.

## Results template (fill per phase)
| Scenario | Steps walked | Real interactions asserted | Result |
|---|:-:|---|:-:|
| S1 | | | |
| S2 | | | |
| S3 (× 3 children) | | | |
| S4 | | | |
| S5 | | | |
