# MEMORY.md - Long-Term Memory

## CRITICAL: Telegram Plain Text Rule
- NEVER use backtick code formatting, bold, italic, or headers in Telegram replies
- Markdown-to-HTML conversion failures cause the ENTIRE message to be silently dropped with no fallback
- Plain prose only. Confirmed silent drops on 2026-02-18 from backtick usage.
- If reply doesn't show in Telegram, use the message tool to send directly as plain text

## Email + Calendar Setup (2026-02-18)
- Christian's personal calendar is in iCloud but synced into Jarvis's Google account; should appear as "christian's calendar".
- iCloud Notes are synced into Jarvis's Google account; Christian can leave notes there for Jarvis.
- Christian forwards his emails to Jarvis's Google inbox.
- Email policy: do not reply to emails proactively. Only act when Christian asks (either answer his question, or draft a reply and send it to Christian for review).

## Slack DM Preference (critical)
- Never reply in threads / "Reply to message" on Slack. Always send top-level DM messages.

## Morning briefing: news relevance (2026-02-19)
- News selection must be actionable and directly relevant to Christian's goals/profile; avoid broad/general industry items.
- Always deliver the full briefing format; if something fails, use a fallback and still send the rest.
- Include NotebookLM links in Slack (not only via email). If link generation fails, state the reason + next best link.

## Brave Search API rate limit (2026-02-20)
- Christian subscription limit: max 1 request/second. Throttle web_search usage accordingly.

## Coding workflow preference (2026-02-19)
- For coding tasks, default to spawning a sub-agent using Codex 5.3 (or the coding-agent skill) rather than coding directly in the main session.

## Action Rule (2026-02-22) - CRITICAL
- NEVER ask Christian to do something I can do myself
- If I can edit a file, run a command, or make a change → just do it
- Only ask when I genuinely lack permission or it's a destructive action requiring confirmation
- Default: act, don't ask

## NotebookLM (2026-02-18)
- NotebookLM is connected via notebooklm-mcp-cli (nlm + notebooklm-mcp) + mcporter MCP wiring.
- Auth uses browser cookies; prefer nlm login auto mode when possible, otherwise nlm login --manual with cookie header copied from NotebookLM batchexecute request headers.
- Never store cookies in memory files.
- 2026-02-19: Christian upgraded to Google Pro plan (NotebookLM/Gemini), so artifact generation quotas should be higher.

## App Dev Process Rule (2026-02-23) - CRITICAL
When Christian asks for ANY app (including "test runs", "demos", "quick prototypes"):

1. **Planning Phase MANDATORY** - Ask planning questions first, get confirmation
   - App name, description, public/private, data needs
   - Acceptance criteria defined
   - Cannot proceed until Christian confirms

2. **Coding Agent MANDATORY** - Main session NEVER writes code
   - Spawn Codex 5.3 sub-agent for implementation
   - Main session = orchestration only

3. **QC Checklist MANDATORY** - Headed browser on BOTH environments
   - Test environment first
   - Production only after test passes
   - Actually click/interact, don't just curl
   - Evidence written to disk before declaring "done"

**NO EXCEPTIONS.** "Test run" = follow process. "Demo" = follow process. "Simple" = follow process.

See: memory/2026-02-23-process-compliance.md (why I failed) + memory/2026-02-23-process-failure.md (what happened)

## App dev + hosting runbook (2026-02)
- Defaults agreed:
  - Repo-per-app
  - Naming: force lowercase (slugify)
  - Default exposure: private unless Christian explicitly says "public"
  - Deletion policy: if an app is deleted, delete repo +24h later (grace window)
- Infra checklist we considered "ready":
  - Domain + Cloudflare DNS: done
  - Cloudflare Tunnel: running as a service: done
  - Cloudflare token available (mode A): yes (never store token value in memory)
  - GitHub CLI auth with repo scopes: yes
- Intake template for new app request:
  - app name (or slugify), 1-3 bullet description, public/private, data needs
- Full runbook file: docs/app-dev-hosting-runbook.md
- Process enforcement: when Christian says "create app …" or "delete app …", Jarvis must open and follow docs/APP_WORKFLOW.md before acting.

## 2026-02-17: First Boot
- Christian set me up. Name: Jarvis. Full profile captured in USER.md.
- Key priorities: productivity optimization, AI tools for UX work, vibe coding projects, health routines, financial optimization, home automation
- Currently vibe coding (non-specific; not the LMS)
- Wants proactive assistance across all life areas
- "Figure It Out" directive: no excuses, ship results
