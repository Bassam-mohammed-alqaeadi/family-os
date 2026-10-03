# 11 — CHD-019 Minutes Wallet Engineering

**Screen:** SCR-CHD-019 · «محافظ تطبيقاتي» (ADR-036)  
**Disposition:** WIRING FIX → WalletLedger projection  

---

## Purpose
Show **per-app earned Minutes** + context of Daily / Grant (read-only summary), never points/XP/coins.

## Hierarchy
1. Honesty: “Earned Minutes” (not نقاط)  
2. Optional summary chips: Daily remaining · Grant remaining (link explanations)  
3. Per-app `MinutesWalletCard` rows: balance · source last credit · timestamp  
4. Empty / how to earn (channels) — suggest only, no auto credit  

## Data target
Conceptual `WalletLedger.balance` projection — **not** fixture as real.  
Fixture Stage-1 must badge **Demo**.  

## Terminology debt
Replace legacy نقاط copy when implementing; engineering forbids XP/points/coins strings.

## Roles
Child view; parent may open read-only from Economy.  

## Does not
- Spend UI that claims OS consume before API exists  
- Free wallet pool (frozen out)  
- Show SOS as requiring Minutes  
