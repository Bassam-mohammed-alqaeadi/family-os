# Gap-Hunter Batch 2 Verdict — CHILD-APP (Session Pass 6)

**Date**: 2026-09-21 · **Judge**: Internal auditor (لا حكم بلا تحقيق) · **Source**: External hunter, fresh clone of public repo (confirmed — zero stale-copy evidence this batch)
**Prototype under audit**: `family-os/family_os_app.html` (frozen v1.0, 5,032 lines) · **Verification**: 2 grep/python passes, every claimed line re-checked in our file.

## Scoreboard

| Verdict | Count |
|---|---|
| ✅ MERGE as-is | 18 |
| 🔄 REVISE → MERGE | 2 (GAP-A-CHILD-012 minor count fix · GAP-D-CHILD-005 reframed) |
| ❌ REJECT | 0 |

Hunter quality note: dramatic improvement over Batch 1 — fresh clone, honest self-deduplication (dropped X-12, L-06/X-13, L-19), and 19/20 evidence lines matched our file exactly. The only UNVERIFIED item the hunter flagged himself (yardstick counts 46 UC / 60 child ops / 115 father ops) is confirmed correct on our side: 46 UCs (و7-5 grand matrix) is canonical.

## Per-finding verdict table

| ID | Sev | Verdict | Evidence in OUR file | Class |
|---|---|---|---|---|
| GAP-A-CHILD-003 | P1 | ✅ MERGE | `bare:true` on CHD-001/002/003/005/006/011 — outside stateGuard, no offline/empty/error states | ANALYSIS-GAP |
| GAP-A-CHILD-004 | P0 | ✅ MERGE | L1067 `depositWallet(req.appId\|\|'youtube',…)` — no wallet-routing contract; silent fallback misroutes minutes | ANALYSIS-GAP |
| GAP-A-CHILD-005 | P0 | ✅ MERGE | L3658 lesson mints +١٠ د, L4405 review mints +١٠ د — outside the 5 sacred channels (ع-٣) | ANALYSIS-GAP |
| GAP-A-CHILD-006 | P0 | ✅ MERGE | Contradictory quran prices: L3640 +٣٥ · L3170 +٥٠ · L3735 +٢٠ · L3739 «كسبت +٧٠» · L4352 hardcoded +٣٠ vs `q.rewardMins` | ANALYSIS-GAP |
| GAP-A-CHILD-007 | P0 | ✅ MERGE | L3729 `const q=qList[0]` (single question); `correct:0` ×6 vs other index ×1 → first-option-wins; attempt never consumed → infinite farm | ANALYSIS-GAP |
| GAP-A-CHILD-008 | P0 | ✅ MERGE | L2747 one-click 🦁 reveal, no 10s hold; banners L2406/L2751 promise «٣ محاولات → قفل ٢٤ ساعة» with zero counter/lockout logic | ANALYSIS-GAP |
| GAP-A-CHILD-009 | P1 | ✅ MERGE | L2478 reply map hardcodes «أبوك» for approved/tasked/rejected; «وافقت أمك» ×0 — contradicts ADR-039 mother grants; also L3859 «أبوك يقول» | ANALYSIS-GAP |
| GAP-A-CHILD-010 | P0 | ✅ MERGE | L2467 «فهمت وأوافق ✓» → `setRole('child')` only; `consent` ×0 in entire file — no consent record, version, timestamp | ANALYSIS-GAP |
| GAP-A-CHILD-011 | P1 | ✅ MERGE | CHD-010 segment contains none of: احتفاظ/تصدير/إفصاح/حذف بيانات — no retention/export/disclosure spec | ANALYSIS-GAP |
| GAP-A-CHILD-012 | P1 | 🔄 REVISE→MERGE | Confirmed, count corrected: «خالد» ×**244** (hunter ~229); L3921 `t.kid==='خالد'`; L977 `KIDS[0]` — no ChildId parameterization anywhere | ANALYSIS-GAP |
| GAP-A-CHILD-013 | P1 | ✅ MERGE | L3813 focus start = toast only; `S.focus` only carries `praiseSent` (L1422-3); CHD-018 static ٢٥:٠٠; CHD-035 decorative `swt` spans — no session record, S-5 auto-reward absent | ANALYSIS-GAP |
| GAP-A-CHILD-014 | P1 | ✅ MERGE | `tradeOffer` written L393 (seed) + L3884 (child send), never read by decideTimeRequest (L1065-1077, verified GH-1) — child's bargain silently dropped | ANALYSIS-GAP |
| GAP-A-CHILD-015 | P0 | ✅ MERGE | L2485 **child-side** button `onclick="S.familyModes.graceLeft=null"` — child terminates grace unilaterally; L1063 setFamilyMode boolean toggle, no actor identity → parent-conflict collapse (ADR-035 breach path) | ANALYSIS-GAP |
| GAP-D-CHILD-002 | P2 | ✅ MERGE | Pronoun bug confirmed **inside CHD-022 template**: «المكافأة: +${t.extraMins} دقيقة لمحفظته» (child screen, 3rd-person); dual field `t.extraMins\|\|t.points` L2654 (CHD-004) | ANALYSIS-GAP |
| GAP-D-CHILD-003 | P1 | ✅ MERGE | CHD-019 `filter(a=>a.status!=='blocked')` — blocked app vanishes **with its balance**; child loses sight of owned minutes (note: same filter at L2912 FAT instant-lock is legitimate) | ANALYSIS-GAP |
| GAP-D-CHILD-004 | P2 | ✅ MERGE | L3698 «أحتاج مراجعة» flips card + toast «سنكررها لك قريبًا» — no queue, no index move, promise never kept | ANALYSIS-GAP |
| GAP-D-CHILD-005 | P1 | 🔄 REVISE→MERGE | Hunter's claim «battery/sentLove never rendered» is **half wrong**: father widget renders both («بطاريته: ٨٤٪», button state «تم الإرسال ❤️», L1817-1916). REAL gap (kept, reframed): toast promises dua appears «لخالد **على شاشته**» — **no child screen renders received love**; one-way promise. Battery also lacks any data contract (static ٨٤٪ everywhere incl. L3977) | ANALYSIS-GAP |
| GAP-OPP-CHILD-001 | OPP | ✅ MERGE | Fairness receipt on refusal (لماذا · من · ماذا بعد) — pairs perfectly with A-009/A-014 fixes | V1.1-SUPREMACY |
| GAP-OPP-CHILD-002 | OPP | ✅ MERGE | Weekly child trust digest | V1.1-SUPREMACY |
| GAP-OPP-CHILD-003 | OPP | ✅ MERGE | Offline promise card (what still works offline) — aligns with OFFLINE-FIRST mandate | V1.1-SUPREMACY |

## P0 roll-up after GH-2 (cumulative)

| # | Gap | Theme |
|---|---|---|
| 1 | GH-1 SEC-002 | No minute ledger (single economic source of truth) |
| 2 | GH-1 ADM-001 | Restore/downgrade surfaceless (S-ADM-024/S-ADM-013 registered, no UI) |
| 3 | GH-1 CHILD-001 | SOS cancel unauthenticated (L2695) |
| 4 | GH-2 A-004 | No wallet-routing contract (youtube fallback) |
| 5 | GH-2 A-005 | Off-channel minute minting (lesson/review +١٠) |
| 6 | GH-2 A-006 | Contradictory reward pricing (5 conflicting figures) |
| 7 | GH-2 A-007 | Farmable quiz (first-option-wins, attempts never consumed) |
| 8 | GH-2 A-008 | Child lock theater (promised 3-strike lockout absent) |
| 9 | GH-2 A-010 | Consent without record |
| 10 | GH-2 A-015 | Child-writable family-mode grace + actorless mode toggle |

**Economic-integrity cluster (SEC-002 + A-004/005/006/007) = one architectural answer: the Minute Ledger.** All five close together in the conversion spec: every minute movement = ledger entry {source_channel, actor, amount, wallet_id, timestamp}; channels whitelist = ع-٣ five only; prices read from one rewards table; quiz attempts consumed server-side.

## ID-numbering decision (runbook clause)

Hunter's runbook says merged IDs drop the domain prefix → continuous GAP-A0xx/GAP-D0xx. **Decision: keep domain-suffixed IDs in GAP_LOG (consistent with Batch GH-1); continuous normalization happens once, at transplant into `docs/project-plan/08-gap-closure-specs.md` §GH during conversion planning.** Rationale: two live numbering schemes in the same log invite collision errors; one normalization pass at spec-transplant time is auditable.

## Rejected-findings archive

`docs/gap-review/rejected.md` created per runbook. GH-2 contributes zero rejections; GH-1's AIC-002 (countdown snapshot misread) migrated there for the permanent record.

## Owner Gate

| Batch | Findings | Merge | Revise→Merge | Reject | Pushed |
|---|---|---|---|---|---|
| GH-2 (CHILD-APP) | 20 | 18 | 2 | 0 | pending commit |

Next recommended hunter session: **FATHER-APP pass** (115 father ops surface > child surface; expect wallet-admin and mode-conflict findings that pair with A-015), then MOTHER/SHARED pass.
