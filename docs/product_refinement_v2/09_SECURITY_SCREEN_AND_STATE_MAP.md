# Security Screen & State Map — Gate G2 Proposal

> **Status:** Ready for Owner experience approval
> **Purpose:** Define the security surface inventory before implementation. Existing screens are evidence and implementation candidates; this map defines their intended product role.

## 1. Parent security surfaces

| ID | Surface | Primary job | Current evidence / relationship | Required key states |
|---|---|---|---|---|
| P-SEC-01 | Safety Hub | Understand family safety now. | New organizing surface; consumes Today, alerts, device, child, and report projections. | Loading, stable, needs-review, urgent, unknown/no connected child, error. |
| P-SEC-02 | Attention Queue | Resolve the next meaningful safety item. | Evolves alert hub/detail patterns. | Empty, grouped, urgent, acknowledged, resolved, stale/failed. |
| P-SEC-03 | Child Safety Profile | Control and understand one child in context. | Reconciles existing child profile and security shortcuts. | Child selector, no device, healthy, limited, action-required, error. |
| P-SEC-04 | Quick Action Sheet | Take a context-safe immediate action. | Reuses sheets/primary action patterns. | Available, confirmation, sending, queued, confirmed, failed/unsupported. |
| P-SEC-05 | Time & Routine Desk | Set daily time, schedules, and exceptions. | `SCR-FAT-032`, `SCR-FAT-033`, smart-modes/source evidence. | Loading, active, edited draft, conflict, pending delivery, no eligible device. |
| P-SEC-06 | Schedule Builder | Create/review a routine. | Existing schedule/mode domain evidence. | New, recurring, time-zone/travel changed, conflict, preview, saved/failed. |
| P-SEC-07 | Request Inbox | Decide fairly on child requests. | Existing time-request/request-inbox evidence. | Empty, pending, approved, declined, expired, cannot deliver. |
| P-SEC-08 | Apps Desk | Manage apps and categories. | `SCR-FAT-034`, `SCR-FAT-035` evidence. | App list unavailable, allowed, limited, blocked, approval pending, unsupported. |
| P-SEC-09 | App Review | Review a new app/request with context. | Existing approval and app-info patterns. | New request, details available/limited, decision saved, queued/confirmed, expired. |
| P-SEC-10 | Web Desk | Set web protection and exceptions. | `SCR-FAT-036`, web-filter surfaces. | Active, partial support, exception list, request, sending, blocked. |
| P-SEC-11 | Web Request Review | Resolve temporary site access. | Existing web unlock loop evidence. | Pending, URL/category known or unknown, approved with expiry, declined, expired. |
| P-SEC-12 | Immediate Action / Lock | Pause/lock safely. | `SCR-FAT-037`, instant-lock/child-lock evidence. | Confirm, sending, queued, confirmed, limited, failed, reversal pending. |
| P-SEC-13 | Location & Check-ins | Understand current location/sharing state. | `SCR-FAT-014`, map/location evidence. | Fresh, stale, paused, permission-needed, offline, unsupported. |
| P-SEC-14 | Location History | Understand movement context over time. | `SCR-FAT-015` evidence. | Empty, date range, partial/stale, retained-data limit, error. |
| P-SEC-15 | Safe Places | Manage agreed places and event preferences. | `SCR-FAT-016`, `SCR-FAT-017` evidence. | Empty, place list, create/edit, device limitation, delivery state. |
| P-SEC-16 | SOS Response | Respond to an active SOS. | `SCR-FAT-018`, emergency/alert patterns. | Incoming, acknowledged, responder en route/contacting, resolved, delivery uncertain. |
| P-SEC-17 | SOS Readiness | Set contacts and test preparedness. | `SCR-FAT-028`, emergency setup evidence. | Setup incomplete, ready, partially ready, test, unsupported/outage. |
| P-SEC-18 | Protection Health | Repair device protection health. | Device-health and tamper-alert evidence. | Healthy, action-required, repair step, pending recheck, unsupported. |
| P-SEC-19 | Integrity Event | Understand a loss-of-protection signal. | `SCR-FAT-038`, tamper alert evidence. | Event, confidence/context, repair, dismissed/feedback, resolved. |
| P-SEC-20 | Safety Activity & Reports | Understand trends and actions over time. | `SCR-FAT-069`, weekly report and alert projections. | Empty/new family, data freshness, trend, insufficient data, report error. |
| P-SEC-21 | School & Focus Routine | Coordinate digital and learning focus. | Smart mode/focus source evidence; old screen registry is evidence only. | Scheduled, active, override, unavailable/limited, linked learning routine. |
| P-SEC-22 | Safety Notification Preferences | Choose meaningful interruptions. | Notification preference/catalog evidence. | Default, customized, quiet hours, urgent exception explanation, save/failed. |
| P-SEC-23 | Safety History & Privacy | Audit significant actions and understand visibility. | Privacy/audit source evidence. | Empty, timeline, filter, export/delete request state, support path. |

## 2. Child security surfaces

| ID | Surface | Child job | Existing evidence / relationship | Required key states |
|---|---|---|---|---|
| C-SEC-01 | My Day & Routine | Know what is active today. | Child day-board and time-mirror evidence. | Normal day, routine active, time low, request pending, device limited. |
| C-SEC-02 | Time Remaining | Understand time and next availability. | Child screen-time/time-expiry evidence. | Available, warning, expired, education/focus exception, no device truth. |
| C-SEC-03 | Ask for Time / Access | Ask respectfully for more time, an app, or a site. | Time-request and web-unlock evidence. | Draft, sent, seen, approved, declined with explanation, expired. |
| C-SEC-04 | App / Web Explanation | Understand a restriction and alternatives. | App deny and web block surfaces. | Blocked, partially allowed, request available, request unavailable, essential exception. |
| C-SEC-05 | Temporary Lock | Understand a pause and retained essentials. | Child-mode lock evidence. | Active, remaining duration, reason, allowed emergency/accessibility path, restored. |
| C-SEC-06 | SOS | Ask for help and see its state. | Child SOS button/in-progress evidence. | Ready, confirmation, in progress, delivery state, resolved/cancelled by appropriate path. |
| C-SEC-07 | Protection Explanation | Understand setup/permission-related limits where age-appropriate. | Onboarding/transparency/device-health evidence. | Needs guardian help, setup complete, no action required. |

## 3. Co-guardian surfaces

Co-guardian uses the same Safety Hub, child profile, alert, request, and response surfaces with visible permission boundaries. The only additional surface is:

| ID | Surface | Job | Required states |
|---|---|---|---|
| G-SEC-01 | My Safety Access | Understand what the guardian may see, change, approve, and receive. | Full, limited, observer, action-pending-primary, invitation/recovery. |

## 4. State coverage matrix

Every parent/child security screen must evaluate these states; inapplicable states require a written reason:

| State | Meaning |
|---|---|
| Loading | Data is being prepared; skeleton/loading does not look like a healthy state. |
| Empty | No child, device, event, request, or history exists yet; explain first useful action. |
| Healthy / confirmed | The relevant state is current and confirmed. |
| Needs review | A meaningful but non-urgent action is needed. |
| Urgent | Immediate attention is needed; action is visually and semantically clear. |
| Draft / unsaved | A rule is being edited and is not active yet. |
| Sending / queued | The command is in transit or waiting; no false confirmation. |
| Limited / unsupported | The device/platform cannot deliver the complete behaviour. |
| Permission/setup needed | A repair path exists and states impact. |
| Offline / stale | The information/action is dated, unavailable, or cannot be delivered now. |
| Failed / recoverable | An operation did not complete; preserve context and offer a next action. |
| Role restricted | The person cannot perform an action; show who can and why. |

## 5. Existing-screen reconciliation rule

No existing screen is deleted or rebuilt merely because a new map exists. During G3 implementation readiness, each existing security screen is assigned one of:

- **Retain:** already serves the approved surface with only implementation hardening.
- **Refine:** preserves its role but receives approved IA, visual, or state improvements.
- **Merge:** content moves into one approved parent surface without losing a closed user journey.
- **Defer:** remains part of the registered system universe but is outside the first sequence.
- **Retire:** only after a documented replacement and explicit decision.

## 6. G2 screen acceptance

The UX lock is complete only if every Core or capability-gated Core security action has a parent entry point, child consequence/explanation where relevant, confirmed/pending/failed state, device-health/capability path, audit/notification relationship, and named implementation surface.
