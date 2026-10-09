# 20 — Screen Time Wireflow

**Docs only — target flows**

---

## W1 Parent configure

```
Child Profile → FAT-032 Overview
  → edit Cap/Schedule/Overflow (Primary|Full)
  → save → Sync PENDING→SYNCED|QUEUED
  → child CHD-004 mirror updates
```

## W2 Child request → grant

```
CHD-004 / CHD-021 → CHD-020 draft → createRequest
  → REQUEST_PENDING (only one)
  → FAT-033 Partner+|Primary
  → [Ruling C if needed]
  → Temporary Grant OR DENIED(+reason)
  → child feedback → remaining chips update
```

## W3 Warning → expiry

```
AVAILABLE → (≤5m) WARNING banner (Request/Quran/Chat/SOS)
  → EXPIRED → CHD-021 calm
  → Request | Quran | Chat | SOS
```

## W4 Instant lock

```
FAT-032 Lock → FAT-037 → DEVICE_LOCKED
  → entertainment denied; SOS/Chat/Quran remain
  → Father unlock supersedes mother
```

## W5 App rules

```
FAT-032 Apps → FAT-034 axes → (future) TimeEngine
  → WhyUnavailableSheet for parent debug
```

## W6 Smart mode

```
FAT-032 Schedule → FAT-085 activate
  → P3 overlay; grant does not pierce
  → ModeException from Exceptions section
```

## W7 Stale fail-closed

```
POLICY_STALE → grace banner → fail closed entertainment
  → CHD-021 path; SOS still open
```

## W8 New app

```
Install signal → FAT-035 → axes → FAT-034
```
