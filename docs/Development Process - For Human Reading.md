# HYBRID WORKFLOW: GSD + Christian's Deployment Process

**FOR HUMAN READING ONLY** — This document explains the merged workflow for Christian's understanding. The AI coding agent reads its own SOUL.md, not this file.

This document merges GSD's spec-driven development with Christian's deployment/hosting requirements.

## Overview

**GSD handles:** Planning, research, task breakdown, code execution
**Our process handles:** Deployment, hosting, Cloudflare tunnel, Access policies, lifecycle

## When Christian Says "Create App"

### Phase 1: GSD Project Init
Run `/gsd:new-project` to create:
- PROJECT.md (goals, constraints)
- REQUIREMENTS.md (v1, v2, out-of-scope)
- ROADMAP.md (phases)

**Why:** This establishes the foundation. Without clear PROJECT.md (vision), REQUIREMENTS.md (scope), and ROADMAP.md (phases), we'd build without direction. It's one-time per project—sets up everything that follows.

**Inject deployment requirements into PROJECT.md:**
```
Deployment Requirements (Non-negotiable):
- Hosting: ThinkCentre via Docker Compose
- URL pattern: https://<app>.christianfransson.com (prod), https://<app>-test.christianfransson.com (test)
- Default exposure: PRIVATE (Cloudflare Access, allowlist: dedooma@gmail.com)
- Data persistence: Separate DB + file storage per environment
- Graceful deletion: Repo deleted +24h after app deletion
```

### Phase 2: GSD Discuss Phase
Run `/gsd:discuss-phase 1`

**What it does:** Locks in your preferences for Phase 1—visual layout, tech choices, error handling, interactions.

**Why:** Prevents "reasonable defaults" that aren't what you wanted. Captures your vision BEFORE planning starts. Output: `1-CONTEXT.md` which feeds directly into planning.

**Add deployment context:**
- "Each phase must include test + prod deployment tasks"
- "Docker Compose setup must be part of Phase 1"

### Phase 3: GSD Plan Phase  
Run `/gsd:plan-phase 1`

**What it does:** Researches how to implement Phase 1, then creates 2-3 atomic task plans (PLAN.md files). Verifies plans against requirements.

**Why:** Breaks work into chunks that fit in 200K context windows. No "I'll be more concise now" degradation. Each plan is executable by a fresh agent with full context. Output: `1-RESEARCH.md`, `1-1-PLAN.md`, `1-2-PLAN.md`, etc.

**Planner must include these deployment tasks in every plan:**
1. Create GitHub repo (lowercase slug)
2. Scaffold: README.md, context.md, docker-compose.yml, .env.example
3. Implement app code
4. Docker Compose config (test + prod services, separate DB volumes)
5. Deploy to test environment (ThinkCentre)
6. QC test in browser
7. Deploy to prod environment
8. Cloudflare Access policy (if private)
9. Return URLs + ops docs

### Phase 4: GSD Execute Phase
Run `/gsd:execute-phase 1`

**What it does:** Runs the plans in parallel "waves" (independent plans together, dependent plans sequentially). Each plan gets a fresh 200K context window. Commits per task.

**Why:** Actually builds the code. Fresh context per plan = no accumulated garbage from previous work. Parallel execution where possible = faster completion. Output: `1-1-SUMMARY.md`, `1-VERIFICATION.md`.

**Executor agents must:**
- Update context.md before each commit
- Run QC checklist
- Test locally before pushing
- Follow APP_WORKFLOW.md deployment steps

### Phase 5: GSD Verify + Our QC
Run `/gsd:verify-work`

**What it does:** Walks through manual UAT (User Acceptance Testing)—"Can you log in? Does the button work?" Auto-diagnoses failures and creates fix plans.

**Why:** Automated tests verify code exists; this verifies it *works* the way you expected. Catches "it compiled but it's wrong." If issues found, re-run `/gsd:execute-phase` with the fix plans.

**Additional QC (from APP_WORKFLOW.md):**
- [ ] Test URL works with test DB
- [ ] Prod URL works with prod DB
- [ ] Deploying new version doesn't wipe data
- [ ] Cloudflare Access working (private apps)
- [ ] Logs accessible via `docker compose logs`

## Required Repo Structure (Every App)

```
<app>/
├── README.md              # What, URLs, how to run/deploy/logs/delete
├── context.md             # Living architecture doc
├── docker-compose.yml     # test + prod services, DBs, volumes
├── .env.example           # No secrets
├── .gitignore
├── design-system/         # If UI-heavy
│   ├── design-system.md
│   └── components.md
├── src/                   # App code
└── docs/                  # ADRs if needed
```

## GitHub Repository Strategy

**Primary account for Coding Agent projects:** `CFVibe` (full access)
**Secondary account:** `chrfra` (limited access - read/write code only)

### Why This Strategy
- Coding agent needs full repo control (create, push, delete after 24h grace)
- CFVibe token has `repo` scope = full permissions
- chrfra token has limited permissions (cannot delete repos)
- Use chrfra only when you explicitly tell the agent to
- All repos PRIVATE by default

### Repo Creation
- **Agent creates repos under `CFVibe` by default**
- **Repos are PRIVATE unless you explicitly say "public"**
- Agent can delete from `CFVibe` after 24h grace period

### When to Use chrfra
- Only when you explicitly instruct the agent
- Agent will switch accounts via `gh auth switch chrfra`
- Cannot delete repos on chrfra (permission limitation)

### Git Commands
```bash
# Clone from CFVibe (default)
git clone https://github.com/CFVibe/<app>.git

# Push to CFVibe
git push origin main

# Switch to chrfra only when you say so:
# gh auth switch chrfra
```

```yaml
# Example structure
services:
  app-test:
    build: .
    ports:
      - "3001:3000"  # test port
    environment:
      - NODE_ENV=test
      - DB_PATH=/data/test.db
    volumes:
      - test-data:/data
    restart: unless-stopped

  app-prod:
    build: .
    ports:
      - "3000:3000"  # prod port
    environment:
      - NODE_ENV=production
      - DB_PATH=/data/prod.db
    volumes:
      - prod-data:/data
    restart: unless-stopped

volumes:
  test-data:
  prod-data:
```

## Deployment Commands (ThinkCentre)

```bash
# Deploy/test cycle
cd /srv/apps/<app>
git pull
docker compose up -d --build

# Logs
docker compose logs -f --tail 200

# Stop
docker compose stop

# Full removal
docker compose down
```

## Cloudflare Tunnel Ingress

Add to cloudflared config (automatic via API):
```yaml
ingress:
  - hostname: <app>.christianfransson.com
    service: http://localhost:3000
  - hostname: <app>-test.christianfransson.com
    service: http://localhost:3001
```

## Cloudflare Access (Private Apps)

Policy: Allow `dedooma@gmail.com` only.
Applied to both test and prod hostnames by default.

## Delete App Flow

1. Stop services: `docker compose down`
2. Remove cloudflared ingress
3. Delete DNS records
4. Confirm gone
5. Schedule repo deletion +24h
6. After 24h: delete volumes (unless "keep data" requested)

## Model Configuration

**Coding Agent:**
- Primary: anthropic/claude-opus-4-6
- Fallback: kimi-coding/k2p5 (credit exhaustion scenario)

**Main Jarvis (me):**
- Primary: kimi-coding/k2p5 (current)
- Can spawn coding agents with opus-4-6 on demand

## Key Differences from Pure GSD

| GSD Default | Our Hybrid |
|-------------|------------|
| Cloud deployment | Self-hosted (ThinkCentre) |
| Simple env vars | Docker Compose + volumes |
| Public by default | Private by default (Access) |
| No test/prod split | Mandatory test + prod |
| No persistence guarantee | Data survives redeploys |
| Delete = immediate | Delete = +24h grace |

## When to Use What

**Use GSD phases when:**
- Starting a new app (planning + research needed)
- Complex feature requiring research
- Multiple parallel workstreams

**Skip GSD, use direct when:**
- Bug fixes (use `/gsd:quick` or direct coding agent)
- Simple config changes
- Updates to existing apps

## Remember

Christian's defaults always apply unless explicitly overridden:
- Private apps (not public)
- Repo-per-app
- Lowercase slugs
- Test + prod environments
- dedooma@gmail.com allowlist
- +24h deletion grace

---

## GSD REGULAR TASKS (Do These Frequently)

These tasks keep GSD working correctly and ensure context survives between sessions and model switches.

### On Every Git Commit

**Before committing:**
1. **Update `context.md`** - Add any architecture changes, new env vars, ports, TODOs
2. **Stage changes:** `git add .`
3. **Commit with descriptive message:** `git commit -m "feat: add user authentication flow"`
4. **Push:** `git push`

**Why:** Git history + context.md = complete state that any model can resume from.

### On Every Session Start (New Chat)

**Always do first:**
```bash
/gsd:resume-work
```

**What it does:** Restores full context from STATE.md, reads PROJECT.md, ROADMAP.md, git history, and current PLAN files. Reconstructs exactly where we left off.

**Why:** New session starts with zero context. This loads everything—decisions, blockers, current task, next steps. Prevents "what were we building again?"

**Then:**
1. Read `context.md` - Understand current architecture
2. Check `git log --oneline -10` - See recent work
3. Run `git status` - See uncommitted changes
4. Read current `ROADMAP.md` or `PLAN.md` - Know what's next
5. Report: "Resuming [task]. Last commit: [message]. Next: [action]"

### On Every Session End (Stopping Work)

**Always do before stopping:**
```bash
/gsd:pause-work
```

**What it does:** Saves full context to STATE.md including current position, blockers, decisions made, and next steps. Also triggers commit of any pending changes.

**Why:** Creates a handoff file for the next session. Without this, next session starts blind. With this, next session (or fallback model) resumes seamlessly from exact stopping point.

**Then:**
1. Update `context.md` with current status
2. Commit any pending changes: `git commit -am "wip: [what you were doing]"`
3. Push: `git push`

**Why:** Files + git = source of truth. Any model can resume by reading them.

### During Active Development (Every 30-60 min)

**Run periodically:**
```bash
/gsd:progress
```

**What it does:** Shows current status: what phase you're on, what's completed, what's in progress, what's next, any blockers, and estimated completion.

**Why:** Quick "where am I?" check during long work sessions. Prevents drift. Keeps focus on the roadmap. Helps catch when we've gone off-track.

**Or manually check:**
- `git status` - What's modified?
- Read `STATE.md` - What did GSD track?
- Read current `PLAN.md` - What task am I on?

### After Model Switch (Credit Exhaustion, etc.)

**Jarvis (main agent) will:**
1. Detect the failure
2. Spawn fallback model with explicit handoff:
   - Repo path
   - Last commit hash/message
   - What was being worked on

**Fallback model must:**
1. cd to repo, checkout correct branch
2. Read `context.md` completely
3. Check `git status` and `git log`
4. Read relevant `PLAN.md` file
5. Report: "Resuming [task] after model switch. Context: [summary]. Next: [action]"

**Key principle:** Never say "I don't know what happened." Always read the files.

### Phase Completion Checklist

**After `/gsd:execute-phase N`:**
```bash
/gsd:verify-work N
```

**What it does:** Manual UAT (User Acceptance Testing). Walks through testable deliverables one by one. "Can you log in? Does the button work?" Auto-diagnoses failures.

**Why:** Automated verification checks code exists; this verifies it *works*. Catches "it compiled but it's wrong." If issues found, re-run `/gsd:execute-phase` with fix plans.

**Then verify our requirements:**
- [ ] Test URL works with test DB
- [ ] Prod URL works with prod DB
- [ ] Data persists across redeploys
- [ ] Cloudflare Access working (if private)

**Then:**
```bash
/gsd:discuss-phase N+1     # Start next phase
```

### Milestone Completion

**When all phases done:**
```bash
/gsd:audit-milestone
```

**What it does:** Verifies milestone met its definition of done. Checks all phases completed, all REQUIREMENTS.md items met, nothing missing.

**Why:** Formal checkpoint before shipping. Prevents "we're done... wait, we forgot auth." Catches gaps before they become problems.

```bash
/gsd:complete-milestone
```

**What it does:** Archives the milestone, tags the release in git (`git tag v1.0`), updates STATE.md to mark complete.

**Why:** Clean separation between versions. Tagged releases = easy rollback. Clean state for next milestone.

**Then either:**
```bash
/gsd:new-milestone         # Start next version
# OR stop if project complete
```

**What it does:** Starts next version cycle. Same as `new-project` but for existing codebase—researches what to add next, creates new ROADMAP.md.

**Why:** V2 work, new features, next iteration. Maintains continuity with previous work while treating it as a fresh planning cycle.

### Quick Tasks (Bug Fixes, Small Features)

**Skip full GSD phase workflow:**
```bash
/gsd:quick
```

**What it does:** Ad-hoc task mode. Skips research and detailed planning, but still uses atomic commits and state tracking. Creates a minimal PLAN.md, executes it, commits.

**Why:** Faster path for simple work. Don't need full `new-project` → `discuss-phase` → `plan-phase` → `execute-phase` workflow for a one-line bug fix. Still gets GSD's commit discipline.

**Still must:**
- Update `context.md` if architecture changes
- Commit with descriptive message
- Test locally before pushing
- Follow deployment steps

### Capturing Ideas (TODOs)

**When you think of something mid-work:**
```bash
/gsd:add-todo "Add password reset flow"
```

**What it does:** Captures the idea to `.planning/todos/` with timestamp. Doesn't interrupt current flow.

**Why:** Prevents context-switching. You're in the middle of Phase 2, think of something for Phase 4—capture it, stay focused on Phase 2, review todos later when planning Phase 4.

**Review later:**
```bash
/gsd:check-todos
```

**What it does:** Lists all captured todos from `add-todo` with timestamps and status.

**Why:** Review ideas you've captured. Turn them into phases, quick tasks, or discard. Prevents good ideas from being lost.

### Brownfield Projects (Existing Codebase)

**Before adding to existing code:**
```bash
/gsd:map-codebase          # Analyze existing stack/architecture
/gsd:new-project           # Then plan what you're ADDING
```

---

## GSD Key Files Reference

**Updated Frequently (by you):**
- `context.md` - Living architecture (MOST IMPORTANT)
- Git commits - History of changes

**Updated by GSD Commands:**
- `PROJECT.md` - Project vision (created by `new-project`)
- `REQUIREMENTS.md` - Scoped v1/v2 (created by `new-project`)
- `ROADMAP.md` - Phases (created by `new-project`)
- `STATE.md` - Decisions, blockers, position (updated by `pause-work`/`resume-work`)
- `{phase}-CONTEXT.md` - Phase preferences (created by `discuss-phase`)
- `{phase}-RESEARCH.md` - Ecosystem research (created by `plan-phase`)
- `{phase}-{N}-PLAN.md` - Atomic task plans (created by `plan-phase`)
- `{phase}-{N}-SUMMARY.md` - Execution results (created by `execute-phase`)

**All stored in:** `.planning/` directory (commit these to git)

---

## Context Handoff Summary

**Golden rule:** Files are the source of truth, not conversation history.

**When switching models:**
1. Old model (if possible): Update context.md, commit
2. Jarvis detects failure, spawns new model with handoff info
3. New model: Reads context.md, git log, PLAN files
4. New model: Reports current state, continues work

**When stopping/starting sessions:**
1. Use `/gsd:pause-work` and `/gsd:resume-work`
2. Or manually: Update context.md, commit, push
3. Next session: Read context.md, git log, continue

**Always:** Commit frequently. Update context.md constantly. Push to remote.
