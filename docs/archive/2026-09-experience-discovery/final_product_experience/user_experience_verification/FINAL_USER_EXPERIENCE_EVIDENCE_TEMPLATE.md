# FINAL USER EXPERIENCE EVIDENCE TEMPLATE

**Program:** Final User Experience Verification  
**Companions:** Plan · Matrix · Checklist · Expected Results · Coverage Report  
**Tester:** Bassam (Owner)  
**Rule:** One result code per case. Attach evidence. Do not mark PASS without the listed evidence type.

---

## A. Session header (fill once per day / device pair)

| Field | Value |
|---|---|
| Session date | |
| Build / commit / how installed | |
| Device A model · Android · approx width dp | |
| Device B model · Android · approx width dp | |
| Start language | AR / EN |
| Start role | Father / Mother / Child |
| Family present? | empty / created / switched |
| Children present? | none / one / many |
| Tester initials | |

**Result codes:** `P` PASS · `F` FAIL · `BN` BLOCKED-NATIVE · `BR` BLOCKED-REMOTE · `OD` OWNER-DECISION · `NA` NOT-APPLICABLE

---

## B. Per-case evidence row (copy for each case)

| Field | Entry |
|---|---|
| **Case ID** | `UXV-…` |
| **Screen ID** | `SCR-…` or sys3 / shell |
| **Journey ID** (if any) | `JRN-…` |
| **Role** | Father / Mother / Child / Any |
| **Locale / direction** | AR-RTL / EN-LTR |
| **Device** | A / B / both |
| **Font scale** | 1.0 / 1.3 |
| **Precondition** | |
| **Exact action** | |
| **Observed UI response** | |
| **Observed data/state** | |
| **Observed navigation** | |
| **Observed feedback** | (toast/banner text verbatim) |
| **Must-NOT check** | OK / VIOLATION: … |
| **Persistence** | N/A / verified after kill-relaunch / FAILED |
| **Result** | P / F / BN / BR / OD / NA |
| **Evidence types used** | ☐ screenshot ☐ text ☐ nav ☐ data ☐ restart ☐ device info |
| **Screenshot / note ref** | |
| **Related finding** | new / `UXV-FD-…` / none |
| **Notes** | |

---

## C. SIP control log (per screen)

Screen: `SCR-__________` · Case: `UXV-SCR-__________-SIP` · Date: __________

| CTL# | Type | Label (verbatim) | Action | Result | Evidence ref |
|---|---|---|---|---|---|
| 01 | | | | | |
| 02 | | | | | |
| 03 | | | | | |
| 04 | | | | | |
| 05 | | | | | |
| 06 | | | | | |
| 07 | | | | | |
| 08 | | | | | |
| 09 | | | | | |
| 10 | | | | | |

*(Add rows as needed. Do not invent controls that were not on screen.)*

---

## D. Nine-field deep record (for FAIL or critical mutate)

Use for every **FAIL**, every **Local mutate**, and every **father↔child loop** step.

1. **Precondition:**  
2. **Exact user action:**  
3. **Expected UI (from Expected Results):**  
4. **Observed UI:**  
5. **Expected data/state:**  
6. **Observed data/state:**  
7. **Expected navigation:**  
8. **Observed navigation:**  
9. **Expected feedback:**  
10. **Observed feedback:**  
11. **Must NOT happen — violated?** Y/N — detail:  
12. **Persistence expectation / observed:**  
13. **Evidence attached:**  
14. **Result:**  

---

## E. Persistence checkpoint block

| Checkpoint ID | Before value | Action | After (same session) | After kill→relaunch | Related screens checked | Result |
|---|---|---|---|---|---|---|
| e.g. child name | | Add child | | | Kids / Today / Profile | |
| e.g. chat msg | | Send | | | FAT-022 / CHD-008 | |
| e.g. language | AR | Switch EN | | | Hub labels | |
| e.g. safe zone | | Save | | | FAT-016 | |
| e.g. notif toggle | | Flip | | | FAT-058 | |

---

## F. Cross-screen consistency log (`UXV-X-*`)

| Case ID | Surfaces compared | Same person? | Same child? | Same family? | Same status/setting? | Result | Evidence |
|---|---|---|---|---|---|---|---|
| UXV-X-01 | | | | | | | |
| UXV-X-02 | | | | | | | |
| UXV-X-03 | | | | | | | |
| UXV-X-04 | | | | | | | |
| UXV-X-05 | | | | | | | |
| UXV-X-06 | | | | | | | |
| UXV-X-07 | | | | | | | |
| UXV-X-08 | | | | | | | |
| UXV-X-09 | | | | | | | |
| UXV-X-10 | | | | | | | |

---

## G. Honesty log (`UXV-HON-*`)

| Case ID | Claim on screen (verbatim) | Reality class (Local / LOCAL_DEMO / NC / RC) | Fake success? | Jargon? | Result |
|---|---|---|---|---|---|
| UXV-HON-01 | | | | | |
| UXV-HON-02 | | | | | |
| UXV-HON-03 | | | | | |
| UXV-HON-04 | | | | | |
| UXV-HON-05 | | | | | |
| UXV-HON-06 | | | | | |
| UXV-HON-07 | | | | | |
| UXV-HON-08 | | | | | |
| UXV-HON-09 | | | | | |
| UXV-HON-10 | | | | | |

---

## H. Fail log (append-only)

| # | Case ID | Screen | Severity (block / residual) | Observation | Screenshot | Suggested smallest fix (optional) | Owner disposition |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |
| 2 | | | | | | | |

**Rule:** One F does not stop the whole program unless the app crashes repeatedly. Finish the checklist; send this Fail log to Cursor after the session.

---

## I. Device §13 summary (from D-FINAL nest)

| Check | Device A | Device B | Notes |
|---|---|---|---|
| Cold start | | | |
| Tabs + Back | | | |
| Keyboard | | | |
| Touch targets | | | |
| Kill relaunch | | | |
| Role switch | | | |
| SOS actor | | | |
| Contrast | | | |
| Small/normal layout | | | |

---

## J. Session closeout

| Question | Answer |
|---|---|
| All Phase 1 lifecycle cases recorded? | Y / N |
| All 73 journeys have a result? | Y / N |
| All 145 surfaces SIP marked? | Y / N |
| Cross-screen + honesty done? | Y / N |
| Fail log attached? | Y / N |
| Ready for Cursor remediations? | Y / N |
| Ready to argue D-FINAL PASSED? | Y / N / needs fixes |

**Signature:** _________________ **Date:** _________________
