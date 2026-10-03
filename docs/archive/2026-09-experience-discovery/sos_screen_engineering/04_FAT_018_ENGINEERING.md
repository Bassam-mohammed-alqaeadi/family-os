# 04 — SCR-FAT-018 Engineering (Parent SOS Incident Center)

**Screen:** SCR-FAT-018 · بلاغ استغاثة  
**Decision:** EXTEND → Emergency Incident Center  
**Widget:** `SosAlertScreen` · Route: `/scr-fat-018?alertId&childId`  
**Authority:** OD-01…05, OD-09/16/20, Q-SOS-RD-02A/02B Break-glass

---

## 1. Purpose

Give eligible guardians a single incident console to understand SOS state, act within role, escalate to **verified** trusted contacts, acknowledge, resolve, and (Primary/Full) invoke Break-glass—without conflating delivery with lifecycle.

## 2. Audience

| Role | Capabilities on this screen |
|---|---|
| Primary | Full: view, contact, ack, escalate, resolve, Break-glass, setup link |
| Mother Full | Same as Primary for response + Break-glass; setup link |
| Mother Partner | View, contact, ack, respond, escalate — **no** Break-glass, **no** setup edit |
| Mother Observer | View essential + contact child only |
| Child | Child lean |

## 3. Entry points

- Push / in-app critical notification deep link  
- Shell settings shortcut → FAT-018  
- Alerts hub (if wired)  
- After sync when ACTIVE incident exists  

## 4. Exit / navigation

| Action | Destination |
|---|---|
| Live map | FAT-014 `?childId=` |
| Setup | FAT-028 (Primary/Full only; others hidden/disabled) |
| Resolve success | Pop or day board FAT-010 |
| Break-glass | Sheet on-screen (no new route) |
| Contact child | Dialer / VoIP / chat — honest channel class |
| Empty setup CTA | FAT-028 if allowed |

## 5. Information hierarchy

1. **Primary:** Child identity (from repo) + lifecycle chip (ACTIVE / ACKNOWLEDGED / ESCALATING / RESOLVED)  
2. **Secondary:** Incident time; location card with freshness class  
3. **Critical status:** Delivery status (per guardian/channel) **separate** from lifecycle  
4. **Contextual:** Device state, battery, connectivity, escalation status, timeline  
5. **Actions:** Role-filtered `SosActionBar`  

### Required sections

- Child identity  
- Incident time  
- Current incident state  
- Location state/freshness  
- Device state · Battery · Connectivity  
- Delivery status  
- Acknowledgement status  
- Escalation status  
- Available contacts/actions  
- Break-glass (Primary/Full when needed)  
- Resolve (not Observer)

## 6. Controls

| Control | Roles | Condition | Enabled | Confirm | Event | Result |
|---|---|---|---|---|---|---|
| Acknowledge | Primary, Full, Partner | ACTIVE | Yes | No | `SosAcknowledged` | ACKNOWLEDGED (still open) |
| Contact child | All guardians | Open incident | Channel class dependent | No | `SosCallAttempted` / chat | External or in-app |
| Live map | All guardians | Location not pure UNAVAILABLE without last-known | Yes if STALE/READY/ACQUIRING | No | — | FAT-014 |
| Escalate | Primary, Full, Partner | Open; ≥1 VERIFIED backup or manual trusted path | Disabled if NOT_CONFIGURED | Sheet confirm | `SosEscalated` | ESCALATING |
| Resolve | Primary, Full, Partner | Open | Yes | Optional confirm | `SosResolved` | RESOLVED retained |
| Break-glass | Primary, Full only | ACTIVE+ and allowlisted need | RBAC | Sheet full flow | `SosBreakGlassInvoked` | OVERRIDE_ACTIVE |
| Setup | Primary, Full | Empty or config | Yes | No | — | FAT-028 |
| Observer actions | — | — | Escalate/Resolve/Setup/Break-glass **absent** | — | — | — |

**Never** show Delivered unless channel confirms.

## 7. State inventory

| State | UI |
|---|---|
| loading | Spinner |
| empty | No active incident + setup CTA if allowed |
| active | Coral incident center |
| acknowledged | Lifecycle chip ACK; actions remain |
| escalating | EscalationStatus + delivery rows |
| resolved | Leave / empty |
| location_* | SosLocationStatus |
| delivery_* | SosDeliveryStatus |
| child_offline / parent_offline / network_degraded | Chips |
| low_battery | Chip |
| permission_missing | Soft on map |
| retrying | On failed actions |
| break_glass_active | Banner + expiry countdown |
| error | AppErrorState + retry |
| child_lean | Lean |

## 8. Role-specific UI

See [06_ROLE_VARIANTS.md](06_ROLE_VARIANTS.md). Observer: essential info + Contact only.

## 9. Empty / error / recovery

- Empty: calm + optional FAT-028.  
- Partial delivery: PARTIAL class, list failed channels.  
- Recovery: retry sync; reconnect fetch open incidents.

## 10. IA placement

- Full-screen coral when active  
- Hero = headline + lifecycle  
- Cards = location/device/delivery  
- Timeline = compact event list  
- Actions = sticky/action bar  
- Break-glass / escalate confirm = sheets  
- Toasts = snackbars  

## 11. Design system

- Coral board; existing tokens; Semantics on all CTAs ≥48dp; P-4 never-gated banner retained.
