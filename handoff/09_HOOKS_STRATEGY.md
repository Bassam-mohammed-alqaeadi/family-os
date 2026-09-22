# Cursor Hooks Strategy — turning the constitution into ENFORCED law
(Owner-requested, 2026-09-18. Hooks = scripts in the agent's loop, configured in `.cursor/hooks.json`. Verified against official Cursor docs.)

## The design-deciding fact
Only TWO hooks can actually BLOCK the agent (return `permission: deny`): **`beforeShellExecution`** and **`beforeMCPExecution`**. All others (`afterFileEdit`, `beforeReadFile`, `beforeSubmitPrompt`, `stop`…) are observe-only: they log, alert, format — but cannot veto. So we design: **hard gates on shell/MCP, tripwires + auto-fixes everywhere else.**

## Our hooks, mapped to constitution rules

### 1) `beforeShellExecution` — the HARD GATE (can deny)
| Guard | Blocks | Enforces |
|---|---|---|
| Protected-path guard | any shell command writing to `core/policy/`, `lib/core/design/tokens.dart`, `.cursor/rules/`, `handoff/` (sed/mv/rm/echo>>…) | Rule 21 |
| Danger guard | `rm -rf` outside build dirs, `curl\|sh`, force-push to main | repo safety |
| Git discipline | `git push` → `ask` (owner sees it); `git commit` touching >1 feature dir → `deny` | Rule 22 |

### 2) `beforeMCPExecution` — the MCP GATE (can deny)
| Guard | Blocks | Enforces |
|---|---|---|
| GitHub MCP scope | any GitHub MCP call to a repo ≠ `family-os` | M-1 (least privilege) |
| Secret hygiene | MCP payloads containing `github_pat_`, `Bearer `, API keys | M-3 |

### 3) `afterFileEdit` — TRIPWIRES + AUTO-FIX (observe, react)
| Watcher | On edit of `lib/**` | Serves |
|---|---|---|
| Auto-format | run `dart format` on the edited file | Rule 18 (half of it, free) |
| Currency tripwire | grep edit for `points\|coins\|xp\|نقطة\|نقاط` in reward context → append violation to `HOOK_ALERTS.md` | Rule 4 |
| Hardcoded-string tripwire | new `Text('…arabic…')` literal outside i18n/ → alert | Rule 12 |
| Child-name tripwire | `Khaled\|Noura\|Saad\|خالد\|نورة\|سعد` outside `mock/` and ARB files → alert | Rules 13, 23 |
| Raw-color tripwire | `Color(0x` inside `features/` → alert | Rule 14 |
| Protected-file alarm | edit landed in protected paths (agent used Write tool, not shell — observe-only here!) → LOUD alert line + `git diff` saved | Rule 21 backstop |

### 4) `beforeSubmitPrompt` — audit trail (observe)
Log every prompt (timestamp + first 200 chars) to `.cursor/audit/prompts.log` — our governance habit: everything recorded.

### 5) `stop` — the closer (observe)
When the agent finishes a turn: if `HOOK_ALERTS.md` gained new lines during the turn → print them as the final word so neither owner nor agent can miss violations; remind about pending `CONVERSION_LOG.md` line if lib/ changed but the log didn't.

### 6) `sessionStart` — context injection
Inject one line: "Constitution v26 in force. Check QUESTIONS.md for owner answers. GAP_LOG.md has N open gaps." — fights session amnesia (pairs with Memory MCP).

## Honest limits (so we don't oversell)
- `afterFileEdit` cannot revert an edit — it flags it. The BLOCK for protected files only works when the agent goes through shell; direct Write-tool edits are caught by the tripwire + `stop` summary, and rule 21 remains a constitutional (review-time) law. Defense in depth: hook alarm → CONVERSION_LOG review → PR gate.
- Hooks run on OUR machine — keep scripts fast (timeouts) and dependency-free (bash + grep).

## Files this adds to the Flutter repo
```
.cursor/
├─ hooks.json
└─ hooks/
   ├─ guard-shell.sh        # gate 1
   ├─ guard-mcp.sh          # gate 2
   ├─ post-edit.sh          # tripwires + dart format
   ├─ log-prompt.sh         # audit trail
   ├─ on-stop.sh            # closer
   └─ session-start.sh      # context injection
HOOK_ALERTS.md               # violations land here (append-only)
```

## hooks.json (reference implementation)
```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [{ "command": ".cursor/hooks/session-start.sh" }],
    "beforeShellExecution": [{ "command": ".cursor/hooks/guard-shell.sh", "failClosed": true, "timeout": 10 }],
    "beforeMCPExecution": [{ "command": ".cursor/hooks/guard-mcp.sh", "failClosed": true, "timeout": 10 }],
    "afterFileEdit": [{ "command": ".cursor/hooks/post-edit.sh", "timeout": 20 }],
    "beforeSubmitPrompt": [{ "command": ".cursor/hooks/log-prompt.sh", "timeout": 5 }],
    "stop": [{ "command": ".cursor/hooks/on-stop.sh", "timeout": 10 }]
  }
}
```

## Governance
- Hook scripts live in the repo → versioned, reviewable, and protected by their own guard (editing `.cursor/` via shell = deny).
- Adding/changing hooks = logged owner decision (rule 21 family).
- `HOOK_ALERTS.md` is append-only evidence — reviewed at every phase gate alongside CONVERSION_LOG.
