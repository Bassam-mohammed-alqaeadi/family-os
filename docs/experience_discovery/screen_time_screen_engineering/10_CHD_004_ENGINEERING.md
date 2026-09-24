# 10 — CHD-004 Day Board Engineering

**Screen:** SCR-CHD-004  
**Disposition:** EXTEND remaining + warning entry  

---

## Purpose
Child home for “my day” including **entertainment remaining** without parent diagnostics.

## Before expiry (AVAILABLE)
Show:
- Remaining Minutes (progress) — may show grant chip separately if grant>0  
- When time ends (clock / “about X min”)  
- What counts vs protected (Chat · Quran · SOS)  
- CTAs: Request More · Wallet · (optional) Focus  

## WARNING (≤5 min)
`TimeWarningBanner` calm:
- Request More · Quran · Chat · **SOS**  

## EXPIRED
Navigate/present CHD-021 (or embed calm surface).  

## Roles
Child only for mutation; parents may preview.  

## Data
PolicySyncBus mirror · grant remaining · **no** Policy Health dump  

## Honesty
If used is mock, child copy stays generic (“time left”) without “measured on device” claims.  

## SOS
Always reachable from board / shell FAB — never hidden by mode/expiry.
