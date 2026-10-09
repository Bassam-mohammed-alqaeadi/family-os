# Family Connection Screen & State Map — Gate G2

> **Status:** Accepted under standing Owner trust
> **Purpose:** Define the approved connection surface inventory before implementation. Existing Flutter screens are evidence/candidates, not a complete production communication system.

## 1. Parent / guardian surfaces

| ID | Surface | Primary job | Existing evidence relationship |
|---|---|---|---|
| P-CON-01 | Family Hub | Understand and coordinate family connection today. | New organizing surface over calendar, tasks, chat, circle, check-ins. |
| P-CON-02 | Connection Attention Queue | Resolve requests, task reviews, invitation/check-in and delivery issues. | Reuses alerts/request patterns. |
| P-CON-03 | Family Conversations | Open family/direct threads and understand delivery state. | `SCR-FAT-021`, `SCR-FAT-022` evidence. |
| P-CON-04 | Conversation Detail | Reply/edit/delete/report within relationship/privacy boundary. | Existing thread surfaces. |
| P-CON-05 | Call / Call History | Start/review supported family call capability. | `SCR-FAT-023`, `SCR-FAT-024` evidence. |
| P-CON-06 | Safe Circle | View/manage family/external relationships. | `SCR-FAT-070` outer circle evidence. |
| P-CON-07 | Contact Request Review | Approve/decline/request context for friend/contact. | `SCR-FAT-071` evidence. |
| P-CON-08 | Family Calendar | Coordinate today/week and context. | `SCR-FAT-052` evidence. |
| P-CON-09 | Event Editor | Create/edit/cancel a contextual family event. | `SCR-FAT-053` evidence. |
| P-CON-10 | Family Responsibilities | View/assign/support tasks fairly. | `SCR-FAT-054` evidence. |
| P-CON-11 | Task Builder / Review | Create/revise/review a task/recognition. | `SCR-FAT-055` evidence. |
| P-CON-12 | Check-ins | See/respond to arrival/location-in-communication states. | Child arrival/location evidence. |
| P-CON-13 | Connection Settings | Set contacts, schedule, notification, privacy, calendar/task preferences. | New organizing settings desk. |
| P-CON-14 | Connection Activity & Audit | Review relationship/event/task/check-in changes and recovery. | Shared activity/audit foundation. |

## 2. Child surfaces

| ID | Surface | Child job | Existing evidence relationship |
|---|---|---|---|
| C-CON-01 | My Family | See available conversations, events, tasks and check-in. | New child organizing surface. |
| C-CON-02 | My Conversations | Open allowed family/contact threads. | `SCR-CHD-007`, `SCR-CHD-008` evidence. |
| C-CON-03 | Call | Start/join a supported call and see actual state. | `SCR-CHD-009` evidence. |
| C-CON-04 | My Friends | See approved friends/request a friend. | `SCR-CHD-030` evidence. |
| C-CON-05 | Share a Moment | Share permitted media/file/voice with intended circle. | `SCR-CHD-023` evidence. |
| C-CON-06 | My Day & Events | See child-visible calendar context. | Uses calendar/task/Today foundation. |
| C-CON-07 | My Tasks | Understand, complete, ask for help, see recognition. | `SCR-CHD-022` evidence. |
| C-CON-08 | I Arrived / Check-in | Send/respond to an approved check-in/location action. | `SCR-CHD-024` evidence. |

## 3. Mandatory states

Each applicable connection surface must handle:

- Loading, first-use/empty and recovery state.
- Relationship active/pending/paused/blocked/revoked/restricted.
- Message/media/call sent, queued, delivered, read/acknowledged, failed, expired or unsupported.
- Event/task draft, assigned/invited, seen, changed, completed, reviewed, cancelled, overdue/reopened.
- Check-in/location fresh, stale, awaiting response, unavailable, permission-needed, limited/unsupported.
- Co-guardian permission restriction/conflict and author/history.
- Offline local availability versus unconfirmed remote delivery.

## 4. Reconciliation rule

Each existing connection surface will later be Retained, Refined, Merged, Deferred or Retired only with a closed journey and documented replacement. New Family Hub architecture must not remove a working child/guardian path merely for visual simplification.

## 5. G2 completion test

Every Core or capability-gated connection action has a parent/guardian entry, child consequence where relevant, relationship/permission state, delivery or lifecycle truth, shared timeline/notification/audit relationship, and recovery path.
