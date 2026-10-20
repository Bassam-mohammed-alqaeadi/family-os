# Contract: Server Minutes Economy (`s3_minutes_economy`)

## Scope
The Server Minutes Economy governs family minute allowances, temporary pools, app-specific wallets, free wallets, and minute rewards earned from tasks. All minute operations, balances, draws, and grants are strictly computed and ledgered on the PostgreSQL backend using an append-only ledger model, enforcing mathematical invariants against negative balances, concurrent race conditions, guardian authorization boundaries, and strict non-spendability for sacred/educational content (Quran minutes).

## Invariants
1. **Append-Only Ledger**: The minutes ledger (`family_minute_ledger`) cannot be modified or deleted at the database level; all operations (grants, draws, reversions, expirations) are strictly additive rows.
2. **Derived Runtime Truth**: Wallet balances are derived directly from ledger row aggregations; cached projections are never treated as the authoritative financial balance.
3. **No Overdrafts Under Concurrency**: When concurrent spends race for the same minute pool, transactional row-level locks guarantee that exactly one succeeds and the balance never drops below zero.
4. **Deterministic Draw Hierarchy**: Minute spends deduct strictly in the order: daily allowance first, then earliest-expiring temporary pool (FEFO), then app-specific wallet, and finally the free wallet.
5. **Guardian-Only Authority**: Only authorized guardians (`primary_guardian` or `co_guardian`) may grant or allocate minutes; children and unauthenticated callers are rejected.
6. **Co-Guardian Limit**: A co-guardian grant is constrained to an enforced ceiling (e.g., max 30 minutes per request), whereas the primary guardian has no operational limit.
7. **Sacred / Educational Isolation (S-1)**: Quran recitation and religious education surfaces can never be counted as spendable screen-time; Quran-earned minutes cannot be consumed on generic entertainment apps.
8. **Grant Idempotency**: Each external earn event or session creates exactly one ledger row; duplicate earns with the same reference are rejected.
9. **Bounded Row Mutations**: All credit, draw, and transfer rows are bounded between 1 and 1440 minutes per entry.
10. **Audited Reversals**: A reversal is recorded as a distinct row by the primary guardian only, requires an explanation of 1 to 500 characters, and cannot exceed the credit's remaining unspent balance.
11. **Client Isolation**: Client-side production code in Flutter (`lib/`) is prohibited from performing local earn/deposit calculations or using simulated wallet states.

## Owned Files
- `backend/migrations/130_family_minute_wallets.sql`
- `backend/migrations/131_family_minute_ledger.sql`
- `backend/migrations/132_tasks_minutes_reward.sql`
- `backend/src/minutes-economy.js`
- `app/lib/core/policy/wallet_ledger.dart`
- `app/lib/features/n17_child_learn/child_wallet_repository.dart`

## Enforcing Tests
- `backend/test/postgres-minutes-economy.test.js`:
  - `two concurrent spends of the same minutes: exactly one succeeds, never negative`
  - `an earn racing a spend keeps the record consistent in either order`
  - `one source produces one row: repeated earns and repeated sessions are refused`
  - `guardian ceiling: a co-guardian at 30 succeeds and at 31 is refused; expiry is recorded once`
  - `a reversal is a new row, once per credit, by the primary only, and never above the credit`
  - `the ledger refuses to be edited or deleted, in the database itself`
  - `the mutation guards: D16 suffixes start at #1, a reversal cannot exceed what the credit still holds after spending, and the table itself caps a row at 1440`
- `backend/test/minutes-economy.test.js`:
  - `daily allowance is valid only on the family day it was granted`
  - `a temporary pool disappears at its expiry by the clock alone`
  - `a draw from a temporary pool is subtracted from that pool only`
  - `app and free wallets are sums of their rows and never negative in the snapshot`
  - `a credit holds what its spends have not taken; ties draw the earlier credit first (FEFO, then FIFO)`
  - `the draw order is daily, then temporary earliest-expiry first, then the app, then free`
  - `planDraws reports a shortfall rather than overdrawing`
  - `primary has no ceiling; a co-guardian is held to the ceiling per request`
  - `a child and any unknown role may never grant minutes`
  - `an app wallet names its app; no other wallet may`
  - `a temporary wallet needs a future expiry; no other wallet may carry one`
  - `Quran and education surfaces are never countable (S-1)`
  - `guardian channels can never be earned by a child, and earn channels are a subset`
  - `the JS vocabularies match the CHECK lists in migration 130 exactly`
  - `migrations 130 to 132 are recorded in the manifest in order`
- `app/test/s3/minutes_static_guard_test.dart`:
  - `no minute write (earn / deposit) exists in lib/ outside the ledger`
  - `the local ledger is constructed only inside its own file`
  - `CHD-019 production path reads the server and is never simulated`

## Phone Evidence
none (verified in PostgreSQL integration suites and Flutter static analysis; no emulator check rows allocated yet).

## Change Rule
- All schema adjustments must be additive PostgreSQL migrations numbered > 132.
- Modifying append-only triggers, draw hierarchy rules, or the sacred isolation clause (S-1) requires explicit owner approval and an updated contract test.
