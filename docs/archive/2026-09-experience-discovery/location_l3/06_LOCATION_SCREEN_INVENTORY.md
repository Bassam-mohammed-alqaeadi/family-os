# 06 — Location Screen Inventory (L3.5)

**Authority:** Flows F01–F13 · IA · Role matrix  
**Rule:** Inventory derived from L3 design — legacy SCR-* are **mapping evidence only**, not completeness.

Logical IDs use `LOC-*`. Implementation may later bind to registry SCR IDs.

---

## Parent screens / states

### LOC-P-LIVE — Live Location Map

| Field | Content |
|---|---|
| **Purpose** | See children now with honesty; watch modes; soft integrity; actions |
| **Role** | Primary + all Mother levels + Guardian (view) |
| **Entry** | Kids hub · profile · SOS handoff · notifications · zone events |
| **Required info** | Child context · freshness state · watch mode · online/sync · optional confidence_low · pins/zones (Domain) · battery honesty if available |
| **Actions** | Elevated/Standard · Silent locate · History · Zones · SOS · child switch |
| **States** | See State Matrix §1–4, §9 |
| **Exit** | History · Zones · SOS · back hub |
| **Policy ref** | L-S1 · Q-LOC-03=B · Q-LOC-07=C · LOC-OD-17 |

*Legacy map hint: SCR-FAT-014*

---

### LOC-P-HIST — Location History

| Field | Content |
|---|---|
| **Purpose** | 90d operational trail; Primary export/archive |
| **Role** | View: Primary + Mothers + Guardian; Export/Archive: Primary only |
| **Entry** | Live · profile · event |
| **Required info** | Day threads · stops · retention honesty · offline partial chip |
| **Actions** | Browse · Export · Archive (Primary) · open Live |
| **States** | history_* · export_* |
| **Exit** | Live · back |
| **Policy ref** | L-S2 · Q-LOC-01 · LOC-OD-05/06 |

*Legacy hint: SCR-FAT-015*

---

### LOC-P-ZONE-LIB — Geofence Library

| Field | Content |
|---|---|
| **Purpose** | List family zones; open edit; create CTA |
| **Role** | View all guardians; Create/Edit Primary + Mother Full |
| **Entry** | Live CTA · Kids hub |
| **Required info** | Zone name · assignment summary · alert enablement summary · empty/error |
| **Actions** | Create · open zone · (Full/Primary) toggle alerts if inline |
| **States** | empty · loading · ready · read-only banner for Observer/Partner |
| **Exit** | Author · Live |
| **Policy ref** | L-S3 · Role matrix |

*Legacy hint: SCR-FAT-016*

---

### LOC-P-ZONE-EDIT — Create / Edit Zone

| Field | Content |
|---|---|
| **Purpose** | Geometry (circle/polygon) · rules · **mandatory child multi-select** · save |
| **Role** | Primary + Mother Full |
| **Entry** | Library create/edit |
| **Required info** | Geometry editor · name · ENTER/EXIT/NO_SHOW toggles · child multi-select · validation |
| **Actions** | Draw · assign · save · cancel |
| **States** | zone_draft (invalid if 0 children) · saving · saved · offline queued |
| **Exit** | Library |
| **Policy ref** | L-S3/L-S4 · Q-LOC-12=B · Q-LOC-11 · Q-LOC-06=A |

*Legacy hint: SCR-FAT-017 (must add multi-select + polygon)*

---

### LOC-P-SLR — Silent Location Request (sheet or card)

| Field | Content |
|---|---|
| **Purpose** | Authorize silent locate; show honest result |
| **Role** | Initiate: Primary/Partner/Full; View result: all guardians |
| **Entry** | Live / profile action |
| **Required info** | Child · pending/result state · freshness if any · offline honesty |
| **Actions** | Confirm request · dismiss |
| **States** | slr_* |
| **Exit** | Live |
| **Policy ref** | L-S6 · LOC-OD-08 |

*No legacy child respond UI*

---

### LOC-P-EVENT — Zone Event Detail

| Field | Content |
|---|---|
| **Purpose** | Present ENTER/EXIT/NO_SHOW event |
| **Role** | All guardians (view) |
| **Entry** | Notification / inbox |
| **Required info** | Kind · child · zone name · time · sync honesty |
| **Actions** | Open Live · History · dismiss |
| **States** | unread/opened · offline delayed |
| **Exit** | Live / back |
| **Policy ref** | L-S7 · Q-LOC-18=A |

---

### LOC-P-CI-CARD — Check-In received (parent card)

| Field | Content |
|---|---|
| **Purpose** | Reassurance that child acknowledged a named place |
| **Role** | All guardians |
| **Entry** | Day board / notification |
| **Required info** | Child · place name · time · evidence availability honesty (no child coords UI) |
| **Actions** | Open Live/History · send care reply (if Comms — out of Location core) |
| **States** | received/opened |
| **Policy ref** | L-S5 · LOC-OD-13 |

---

## Child screens / states

### LOC-C-CHECKIN — Child Safety Check-In

| Field | Content |
|---|---|
| **Purpose** | Acknowledge arrival at **named** Safety place |
| **Role** | Child |
| **Entry** | Child Safety nav |
| **Required info** | Named places only (no geometry/map) |
| **Actions** | Tap place · confirm |
| **States** | ci_* |
| **Exit** | Back to day/safety hub |
| **Policy ref** | Q-LOC-16 · Child Silent |

*Legacy SCR-CHD-024 — reshape; remove live location card*

---

### LOC-C-DISCLOSURE — Non-interactive safety disclosure

| Field | Content |
|---|---|
| **Purpose** | Compliance/transparency categories — no location data exposure |
| **Role** | Child |
| **Entry** | Onboarding / transparency flows (may be shared privacy screens) |
| **Required info** | Static category text |
| **Actions** | Acknowledge read (non-control) |
| **Forbidden** | Disable/weaken · map · coords |
| **Policy ref** | Q-LOC-14 |

---

### LOC-C-SOS-STATUS — (owned by SOS L3; Location constraint)

| Field | Content |
|---|---|
| **Purpose** | Status words only during ACTIVE SOS |
| **Role** | Child |
| **Entry** | SOS in-progress board |
| **Required info** | acquiring / located / stale·last-known / unavailable |
| **Forbidden** | map · coords · history · geofence · diagnostics |
| **Policy ref** | Q-LOC-09 · SOS Handoff |

---

## Supporting / non-Location-owned

| Surface | Relation |
|---|---|
| SOS Incident parent board | Handoff CTA → LOC-P-LIVE |
| Device Health | Posture / permission inputs for bands |
| Audit log | Export/archive/zone edits visibility |
| FAT-077 Road Safety | **Excluded** from this inventory |

---

## Empty / loading / error (Rule 23)

Every parent LOC-* screen must design: **empty · loading · one · many · error** (+ offline variant where relevant).
