# 03 — FAT-033 Request Inbox Engineering

**Screen:** SCR-FAT-033  
**Widget:** `RequestInboxScreen`  
**Disposition:** EXTEND to match frozen request loop  

---

## Purpose
Parent/Mother decide child extra-time requests → Temporary Grant (G-A) or denial with child-visible reason.

## Roles
| Role | Access |
|---|---|
| Primary | Full decide any amount |
| Mother Partner / Full | Decide; grant ≤ ceiling (ADR-039) |
| Observer | Read-only list + “cannot decide” |
| Child | No |

## Entry / exit
Entry: FAT-032 Requests · notification (future) · shell.  
Exit: back · deep-link child Overview.

## Hierarchy
1. Pending queue (max conceptual one per child highlighted)  
2. Selected request detail: child context · requested Minutes · reason · timeout countdown  
3. Ceiling meter (mothers)  
4. Decision actions  

## Primary / secondary
**Primary:** Approve (amount stepper) · Reject  
**Secondary:** Adjust grant minutes · view history · open child Screen Time  

## Permission
`RoleActionGuard` + ceiling indicator before confirm. Over-ceiling → block with “Primary only”.

## Policy I/O
In: `TimeRequest` · ceiling · child remaining (3-part) · offline flag  
Out: approve → Temporary Grant; reject → reason; queue if offline  

## Events
`time_request.approved` · `time_request.rejected` · `temporary_grant.activated` · `decision.queued_offline`

## Data
`TimeRequestService` (target) · decision bus · audit  

## States
empty · loading · pending · deciding · success · error · QUEUED_OFFLINE · list with EXPIRED requests (read)

## Errors
Not allowed · reason required · ceiling exceeded · already decided · request expired  

## Offline / sync / honesty
Queue decisions; show queued chip; no push-delivery claim.  

## Audit
Actor label + amount/reason always recorded in History / audit surface.

## A11y / RTL
Decision sheet focus trap; reject reason field labeled; RTL.

## Ruling C
If approve intersects upcoming hard mode → mandatory sheet: **Complete grant to end** | **Freeze when mode starts** before commit.
