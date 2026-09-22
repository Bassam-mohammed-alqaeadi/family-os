# MCP Strategy — servers that serve THIS project's methodology
(Owner-requested, 2026-09-18. MCP = Model Context Protocol servers that extend Cursor's agent with tools. Configure in `.cursor/mcp.json`.)

## Selection principle
We pick MCP servers that serve our four pillars: (1) fidelity to the frozen prototype, (2) the seven CI checks, (3) the constitution (26 rules), (4) traceable governance. Not popularity.

## Tier 1 — install before F0 (direct daily value)
| MCP server | What it gives Cursor | Why it matters for US |
|---|---|---|
| **Dart/Flutter MCP** (official `dart_mcp_server`) | Live access to analyzer errors, running app, hot reload, pub.dev search, widget-tree inspection | Rule 18 (zero analyze warnings) enforced in-loop, not post-hoc; Cursor fixes what the analyzer actually reports instead of guessing |
| **Playwright/Browser MCP** | Opens `family_os_app.html` in a real browser, navigates screens, takes screenshots | ⭐ THE fidelity weapon: before converting screen X, Cursor screenshots the frozen prototype screen and compares its Flutter output — pixel-fidelity per rule 1. Also re-runs our human-walk acceptance scenarios |
| **GitHub MCP** | Issues/PRs/commits/history from chat | Each task card becomes an Issue; CONVERSION_LOG cross-links; owner reviews PRs per phase gate — our governance, automated |
| **Memory/Knowledge MCP** (persistent notes) | Long-term memory across sessions | Cursor sessions forget; the constitution's spirit, owner Q&A answers from QUESTIONS.md, and per-screen decisions persist |
| **Context7 MCP** (live library docs) | Up-to-date Riverpod/Drift/go_router/freezed docs | Prevents stale-API hallucinations in exactly the packages our architecture mandates |

## Tier 2 — install when the phase needs them
| MCP server | Phase | Purpose |
|---|---|---|
| **SQLite MCP** | F2+ | Inspect the local Drift DB while testing policy engine and wallets (Minutes integrity checks) |
| **Figma MCP** | only if we later redraw assets | Not needed now — our design source is the HTML prototype, not Figma |
| **Sentry MCP** | F7/beta | Crash triage from chat during Gulf beta |
| **Supabase/Firebase MCP** | backend phase | When the real API layer replaces mock/ (rule 25 seam) — server-side inspection |
| **App Store / Play Console MCP** (or fastlane scripts) | release | Store metadata, review status |
| **LiveKit docs via Context7** | F5 calls | C-5 policy: metadata-only calls |

## Governance rules for MCP usage (extends the constitution)
- M-1: MCP servers run with least privilege — GitHub MCP scoped to this repo only; no server receives secrets in prompts.
- M-2: Screenshot comparisons (Playwright) are attached to the task's CONVERSION_LOG line as evidence.
- M-3: Memory MCP stores decisions and answers — never child data, never tokens.
- M-4: Any new MCP server addition = logged owner decision (rule 21 spirit).

## Suggested `.cursor/mcp.json` skeleton
```json
{
  "mcpServers": {
    "dart": { "command": "dart", "args": ["mcp-server"] },
    "playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@latest"] },
    "github": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"], "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "<owner-scoped-token>" } },
    "memory": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-memory"] },
    "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp"] }
  }
}
```
(Exact package names/versions to be verified at install time — they evolve.)

## The workflow this unlocks (fidelity loop)
1. Task card for screen X → Cursor asks Playwright MCP to open the frozen prototype at screen X and screenshot it.
2. Cursor implements the Flutter screen (constitution rules).
3. Dart MCP runs analyzer + tests; Cursor iterates until green.
4. Cursor runs the Flutter app, screenshots the same screen, compares against step 1 — attaches both to the PR.
5. GitHub MCP opens the PR; owner gate per phase.
