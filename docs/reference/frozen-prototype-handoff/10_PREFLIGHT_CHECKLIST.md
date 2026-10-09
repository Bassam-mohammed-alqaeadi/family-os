# Pre-Flight Checklist — before the first line of Flutter code
(Owner-requested partner review, 2026-09-18. Items verified as MISSING from our docs, not generic advice.)

## A · Technical ground (decide once, suffer never)
| # | Item | Decision needed | Why now |
|---|---|---|---|
| A1 | **Pin Flutter/Dart versions** (e.g., latest stable + Dart 3.9+ for MCP) via FVM, committed `.fvmrc` + `environment:` in pubspec | Owner approves the pinned version | Cursor sessions on different days must not build with different SDKs — "works yesterday, breaks today" is the #1 agent-workflow killer |
| A2 | **Arabic font decision**: IBM Plex Sans Arabic vs Cairo (both OFL-licensed, free) — bundle in assets, never fetch at runtime | Owner picks after seeing both on a screen | Doc 06 left it open; F0-A needs it literally |
| A3 | **Branch protection on `main`**: require PR, no force-push, CI green to merge | 5 minutes in GitHub settings | Right now Cursor pushes straight to main — one bad push can bury the frozen truth. Do this BEFORE F0 |
| A4 | **CI pipeline file** (GitHub Actions): analyze + format-check + tests + our 9 custom checks on every PR | Cursor writes it as task F0-0 | The constitution is enforced by hooks locally — CI is the second lock nobody bypasses |
| A5 | **Emulator/device matrix**: one Android emulator (API 34) + one low-end real device for F7 perf; iOS later per G1 | Note which physical devices you own | S4 child scenarios need real long-press/notification behavior eventually |

## B · Repo & workflow hygiene
| # | Item | Why |
|---|---|---|
| B1 | **Separate app repo or monorepo?** RECOMMENDATION: keep ONE repo (this one) with `app/` folder for Flutter — the constitution, prototype, and code live together; hooks and rules apply automatically | Simplicity + single source of truth; split later only if CI times hurt |
| B2 | **`.gitignore` for Flutter** before first `flutter create` (build/, .dart_tool/, *.g.dart policy: COMMIT generated files? RECOMMENDATION: commit codegen output — agent workflows break on "run build_runner first" surprises) | Prevents 10k-file accidental commits |
| B3 | **QUESTIONS.md protocol**: owner checks it at session start; answers are appended UNDER the question with date — it is the async decision channel | Rule 2 only works if someone actually answers |
| B4 | **Session rhythm**: recommend max 1 phase-card per Cursor session; end每 session with `git status` clean + CONVERSION_LOG updated | Agent context degrades in long sessions; clean cuts = clean audits |

## C · Product & legal (cheap now, expensive later)
| # | Item | Why now |
|---|---|---|
| C1 | **App identity pack**: final app display name (عائلتي?), bundle IDs (com.???.familyos — needs YOUR domain/org decision), app icon source | Bundle ID is near-impossible to change after store submission; icon needed by F0 |
| C2 | **Google Play developer account** ($25 one-time) + later Apple ($99/yr) — Play account age/verification takes days-weeks; family-safety apps face EXTRA review (Data Safety form, prominent disclosure for location/monitoring) | Start the account NOW so verification runs in parallel with F0–F3 |
| C3 | **Privacy policy URL** (required by Play for family/monitoring apps even in beta) — we have the substance in Register §Privacy; needs a public page | Beta blockers are always paperwork, never code |
| C4 | **Quran licensed source** (Register A-4): identify the actual licensed Madinah Mushaf text/audio provider and its license terms BEFORE F5 builds Quran screens | The most sensitive content in the product; no placeholder Quran text allowed |
| C5 | **Trademark sanity**: quick search that "عائلتي / Family OS" isn't taken in target stores | Renaming after launch = brand suicide |

## D · Money & time honesty (partner talk)
| # | Item | Reality |
|---|---|---|
| D1 | **Cursor/model budget**: F0→F7 is hundreds of agent tasks; expect real API/subscription costs monthly | Decide monthly ceiling; agent time is cheap vs developer time but not free |
| D2 | **Timeline realism**: F0–F2 (foundation+policy) are slow and boring but MUST be perfect; screens (F3–F6) then go fast because 129 screens reuse 10 components | Don't judge velocity by week 1 |
| D3 | **Backend budget looms at the end**: rule 25 keeps UI safe, but real backend (auth, sync, E2EE chat, LiveKit, AI gateway) is a second project of similar size | Plan it as "Project 2" — do NOT let it creep into the UI phases |
| D4 | **One decision-maker rhythm**: you are the gate for 8 phases; block 30–60 min per gate walk | Gates queued = project stalled |

## E · Risk register (top 5, with mitigations already in place)
| Risk | Mitigation |
|---|---|
| Agent drift from prototype | Playwright fidelity loop (doc 08) + constitution rule 1 |
| Silent constitution violations | Hooks tripwires (doc 09) + CI (A4) + PR gates (A3) |
| Session amnesia | Memory MCP + sessionStart hook + handoff docs |
| Scope creep into backend | Rule 25 seam + D3 discipline |
| Store rejection (family-safety category) | C2/C3 started early + iOS honesty (rule G1/ios_reality) |

## Suggested order of execution (this week)
1. A3 branch protection (5 min, owner) → 2. C2 Play account application (owner) → 3. A1+A2 decisions (owner picks, 10 min) → 4. Cursor task F0-0: `.gitignore` + FVM pin + CI skeleton + fonts bundled → 5. THEN F0-A tokens. 
