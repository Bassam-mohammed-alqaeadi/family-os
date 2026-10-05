# Auto UX Polish — Family Entry (no-mock guard)

Scope: CreateFamily (SCR-FAT-001) + AddChild (SCR-FAT-003) only.
Rule: same screens, same brand, real states only. No fake success.

Planned micro-improvements:
1. CreateFamily: live character counter (x/120), inline over-limit hint,
   disable submit when empty/over-limit/submitting, keep SHR-005 error
   mapping untouched.
2. AddChild: keep server error mapping, add inline name counter and keep
   emoji/theme as local display-only until backend contract admits them.
3. Both: 48dp targets, semantics labels, RTL-safe counters, no raw errors.
