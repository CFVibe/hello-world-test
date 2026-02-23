# APP_WORKFLOW.md - Create/Delete app workflow (Christian ↔ Jarvis)

This is the repeatable workflow for building and hosting apps on Christian's infrastructure.

## Goals

Primary goal (non-negotiable)
- Go from Christian asking for an app → Jarvis builds + deploys + returns a working URL.
- **No interaction required from Christian during build/deploy** (no clicking, no manual copy/paste, no asking for API keys) beyond the initial app request.

Lifecycle goals
- Christian can say: "create app X that does Y" → Jarvis builds + deploys + returns a working URL.
- Christian can say: "delete app X" → Jarvis removes the service + routing, then deletes the repo after a 24h grace window.
- Default is **private** (login-gated) unless Christian explicitly says "public".

## GitHub Repository Strategy

**Primary account for Coding Agent projects:** `CFVibe` (full access - create, push, delete)
**Secondary account:** `chrfra` (limited access - read/write code only, NO delete permissions)

### Why
- Coding agent needs full repo control (create, push, delete after 24h grace period)
- CFVibe token has `repo` scope = full permissions
- chrfra token has limited permissions (contents read/write, metadata read)
- Use chrfra only when Christian explicitly says so
- All repos PRIVATE by default

### Implementation
- **Create repos under `CFVibe` by default**
- **Push all code to `CFVibe`**
- **Delete from `CFVibe` after 24h grace period**
- **Use `chrfra` only when explicitly instructed by Christian**
- **All repos PRIVATE unless Christian says "public"**

### Git Commands
```bash
# Create repo (CFVibe by default, private)
gh repo create CFVibe/<app> --private

# Push to CFVibe
git push https://github.com/CFVibe/<app>.git main

# Clone from CFVibe
git clone https://github.com/CFVibe/<app>.git

# Switch to chrfra only when Christian says so:
# gh auth switch chrfra
```

## Naming + URL conventions

- App slug: **lowercase** only. Jarvis will normalize and explicitly report: `X → x`.
- URL pattern (default):
  - `https://<app>.christianfransson.com`

(We discussed an alternative bucket pattern `https://<app>.apps.christianfransson.com` + wildcard DNS for fewer per-app DNS records. We are currently operating with the short-URL root pattern above.)

## Repo convention

- **Repo-per-app**.
- Repo name = app slug.
- Rationale: clean lifecycle mapping: `repo == service == hostname`.

## Exposure / privacy

- Default exposure: **private**.
- If Christian says "public app", Jarvis makes it publicly accessible.
- Private access model: Cloudflare Access (Google login allowlist).
  - Allowed identity: `dedooma@gmail.com` (as discussed).

## Hosting model

>>> Chosen runtime option: **Option 1 - Docker Compose per app (recommended)**

- Hosting target: **ThinkCentre/OpenClaw host** (home server).
- Edge routing: **Cloudflare Tunnel** (`cloudflared`) running as a **systemd service**.
- Each app runs locally as its own Docker Compose stack (inside its own repo folder) on a local port; cloudflared routes hostname → local service.

### Test and production environments (mandatory)

Goal
- Jarvis must be able to test apps (including creating/modifying data and uploading files) without affecting Christian's production data.

Rule
- Every app gets **two environments**:
  - **Test/Staging** (where Jarvis deploys first + runs QC)
  - **Production** (what Christian uses)

URL convention
- Production: `https://<app>.christianfransson.com`
- Test/Staging: `https://<app>-test.christianfransson.com`

Data persistence + separation (mandatory)
- The database and blob/file storage must be **separate from the web app container**.
- Deploying a new version of the app must not delete user data.
- Test and Production must have **separate**:
  - databases
  - blob/file storage

Implementation default (Docker)
- Use Docker volumes (or bind mounts under a stable host path) for:
  - database data directory
  - blob/file storage directory
- Use distinct resources per environment (e.g. different Docker volume names or different host paths).

Deploy policy
1) Default: deploy all changes to **Test** first.
2) Run QC tests against **Test** (headed browser + data manipulation as needed).
3) Only if tests pass: deploy the same version to **Production**. and run the QC tests again. if QC tests pass then proceed:
4) Notify Christian after Production deploy.

### Ops mechanics (exact conventions)

Repository-local paths
- Inside a repo, prefer relative paths.
- Don't hardcode absolute paths in code/config unless unavoidable.

Host folder layout on ThinkCentre (configurable)
- We use a single configurable base directory for deployments:
  - `APP_BASE_DIR` (default: `/srv/apps`)
- Each app repo is cloned into: `$APP_BASE_DIR/<app>`
  - Example: `$APP_BASE_DIR/notes`

Docker Compose requirements per app
- Each app repo contains a `docker-compose.yml`.
- Compose must define two app services:
  - `<app>-test` (staging)
  - `<app>-prod` (production)
- If a database is required, it must be a separate service per environment:
  - `db-test`, `db-prod` (or equivalent)
- If file/blob storage is required, it must be persisted outside the app container per environment:
  - `files-test`, `files-prod` (either bind mount dirs or volumes)
- Every long-running service in compose must include:
  - `restart: unless-stopped`

Why this matters (reboots)
- If Docker itself is enabled on boot, then after a server reboot Docker will restart and bring up any containers with `restart: unless-stopped` automatically.

Standard commands (run on ThinkCentre)
- Start/update (pull latest + rebuild + start):
  - `cd "$APP_BASE_DIR/<app>"`
  - `git pull`
  - `docker compose up -d --build`
- Stop:
  - `docker compose stop`
- Full shutdown (remove containers/network, keep volumes unless you remove them):
  - `docker compose down`
- Logs:
  - `docker compose logs -f --tail 200`

Ports
- Each environment exposes an internal container port (e.g. 3000) and binds to localhost only.
- cloudflared points:
  - production hostname → `http://localhost:<prod-port>`
  - test hostname → `http://localhost:<test-port>`

## Cloudflare automation token (security model)

- Cloudflare API token is required for end-to-end automation of DNS + Access.
- Best practice:
  - Never paste tokens into chat.
  - Store token on the ThinkCentre in a root-only env file and load it via systemd.

Required token permissions (as agreed in chat):
- Account → Cloudflare Tunnel → Edit
- Zone → Zone → Read
- Zone → DNS → Edit
- Zone → Access: Apps and Policies → Edit (optional but recommended for private-by-default)

## Create app flow (Jarvis)

When Christian says: "create app X that does Y" (plus public/private + data needs), Jarvis will:

1) Intake + normalize
- Slugify/lowercase name.
- Confirm: public/private (default private), data needs.

2) Repo + scaffolding
- Create GitHub repo `<app>`.
- Add README + basic ops instructions.

3) Build
- Implement in small increments; keep `main` deployable.

4) Deploy on ThinkCentre
- Run app as a service (default: Docker Compose).
- Configure cloudflared ingress:
  - `https://<app>-test.christianfransson.com` → test service
  - `https://<app>.christianfransson.com` → production service
- Ensure DNS exists (tunnel route typically creates the CNAME; otherwise create via API).
- Apply Access policy if private (both envs unless explicitly requested otherwise).

5) QC and promotion
- Deploy to **Test** first.
- Run all QC tests against **Test**.
- If all pass: deploy/promote the same version to **Production**.

6) Return
- Test URL + production URL
- What was tested
- How to update (deploy)
- Where logs are
- How to delete

## Delete app flow (Jarvis)

When Christian says: "delete app X", Jarvis will:

1) Normalize name to slug.
2) Stop/remove **both** environments (test + prod).
3) Remove cloudflared ingress for both hostnames:
   - `<app>-test.christianfransson.com`
   - `<app>.christianfransson.com`
4) Delete DNS records for both hostnames.
5) Confirm they're gone.
6) Data handling (explicit):
   - By default, deletion removes the app + routing but preserves volumes for 24h (same grace window).
   - After 24h (when repo is deleted), delete the associated volumes/storage too unless Christian says "keep data".
7) Schedule repo deletion **+24h** after app deletion (grace window).

## One-time infrastructure checklist (must remain true)

- Domain + Cloudflare DNS: done
- Cloudflare Tunnel: installed and running as a service: done
- Cloudflare automation token available (mode A): yes (stored on host; never in docs)
- GitHub CLI auth with repo scopes on ThinkCentre: yes

## Repo skeleton (required)

Every app repo must contain this minimum structure (add more as needed, but never less):

- `README.md`
  - what the app does
  - URLs (test + prod)
  - how to run locally
  - how to deploy (test then prod)
  - how to view logs
  - how to delete

- `context.md`
  - living context: architecture, key decisions, ports, env vars, data stores, known limitations, TODOs

- `design-system/`
  - `design-system/design-system.md` (tokens)
  - `design-system/components.md` (component catalog + usage)

- `docker-compose.yml`
  - must define test + prod services + separate DB/files per env

- `.env.example`
  - complete list of env vars needed to run locally
  - **never** include real secrets

- `.gitignore`

- `docs/` (optional but recommended)
  - `docs/adr/` for architecture decisions (if the app grows)

## QC checklist (required before every commit)

Copy/paste this list into the PR description or commit message notes and tick it mentally.

Build + run
- [ ] `git status` clean except intended changes
- [ ] App builds locally without errors
- [ ] `docker compose up -d --build` works

Context + docs
- [ ] Updated `context.md` to reflect *all* changes in this commit
- [ ] Updated `.env.example` if env vars changed
- [ ] README still accurate (run/deploy/logs)

Test/Staging
- [ ] Deployed to **test** env first
- [ ] Headed browser QC on test URL:
  - [ ] core flows work
  - [ ] error states sane
  - [ ] forms validate
  - [ ] auth/access behaves as expected (private/public)
  - [ ] file upload/download works (if relevant)

Promotion
- [ ] Only if all tests passed: deployed same version to **production**
- [ ] Production smoke test in headed browser

Code quality
- [ ] Quick self code review done (naming, dead code, error handling)

Git
- [ ] Commit message describes what changed
- [ ] Pushed to remote

## Coding execution (agent + model)

Default
- Implementation work is delegated to a spawned coding sub-agent (per our workflow preference).
- Default model: **Codex 5.3** (or the closest available Codex coding model).

Roles
- Main Jarvis (this chat):
  - intake + clarify requirements
  - enforce this runbook
  - orchestrate deploy + DNS/Access + notifications
  - review results + ensure QC evidence exists
- Coding sub-agent:
  - implement features according to the plan
  - keep `context.md` up to date
  - run QC checklist
  - prepare commits/PRs

## Vibe-coding guardrails (for the coding agent)

These rules exist to prevent context rot + spaghetti code and to let the coding agent work autonomously.

Planning (mandatory) - interactive "Codex planning mode"
- Before any coding, run an explicit planning phase.
- Flow:
  1) Jarvis (main chat) asks a fixed set of planning questions.
  2) Christian answers.
  3) Jarvis compiles the final plan (features + acceptance criteria + QC steps) and hands it to the coding sub-agent.
- The plan must include:
  - features to implement (bullets)
  - acceptance criteria per feature
  - how each feature will be QC tested (step-by-step)
  - test/prod data separation considerations (DB + files)

Context management (mandatory)
- Every repo must contain a `context.md` at repo root.
- Update `context.md` whenever behavior/architecture changes.
- **CRITICAL - Update BEFORE starting work on a task:**
  1) Document intent: "Starting: [task name], will modify: [files]"
  2) Document expected changes: "Will add: [feature], change: [behavior]"
  3) This ensures fallback models can resume if credits run out mid-work
- **Update AFTER completing work (before commit):**
  1) `git diff` / `git status` and scan all changes in the active branch.
  2) Update context.md with actual results: what changed + why.
  3) Note any new env vars, ports, routes, migrations.
  4) Record follow-up TODOs and known limitations.
- **Continuous state saving (for GSD resume):**
  - After every task completion: commit code AND update STATE.md with current position
  - Push to remote immediately
  - Never rely only on `/gsd:pause-work` (may fail if credits exhausted)
- Files are source of truth, not conversation history.
  3) Note any new env vars, ports, routes, migrations.
  4) Record follow-up TODOs and known limitations.

Code quality (mandatory)
- Refactor while you go: don't leave TODO-spaghetti.
- Prefer small modules + clear boundaries over "one big file".
- Add types (TypeScript) and consistent lint/format.

Code review (mandatory)
- Before each commit, do a quick self-review for:
  - obvious bugs
  - dead code
  - unclear naming
  - missing error handling

Testing / QC (mandatory)
- Do thorough QC before asking Christian to review.
- Test in a real browser (headed), by clicking through everything that you have added to the UI. Test every flow..
- Test the **local deployment first**; if all tests pass → then commit/push.

Git discipline
- Use GitHub email for commits if needed: `1331654+chrfra@users.noreply.github.com`.
- Commit + push after each unit of work once QC passes (keep main deployable).

Docs / library usage
- When library/API docs are needed for correct setup/config/codegen: use Context7 (MCP) by default.
  - If Context7 is not available in the current runtime, use web docs as fallback and note what was used.

Design system (per app, reusable)
- Every app repo must include:
  - `design-system/` folder containing:
    - `design-system.md` (tokens: colors, type scale, spacing, radii, shadows)
    - `components.md` (component catalog + usage guidelines: primary/secondary button, inputs, accordion, etc.)
- When Christian requests: "use design system from APPNAME1", reuse that folder as the baseline and document the inheritance in `context.md`.

## Product requirements (global)

- Apps are primarily **web browser-based**.
- Every app must be **mobile-friendly** by default (responsive layout, touch targets, usable on phone).

## Standard tech stack (default for all apps)

Goal: consistency across projects + easy maintenance + Lovable-friendly frontend.

Frontend (default)
- Vite + React + TypeScript
- Tailwind CSS
- shadcn/ui (component primitives)

Backend (default)
- Node.js + TypeScript (Fastify)
- If the app doesn't need a backend: omit it.

Rationale
- This stack is fast to scaffold, consistent across apps, and produces a repo that is straightforward to open/edit as a frontend project.

## "Edit with Lovable" process (standard)

Reality check
- Lovable can edit the frontend repo/project.
- Backend services running on the ThinkCentre won't "run inside Lovable", so for fullstack apps we treat Lovable as a **frontend editor**.

Workflow
1) Christian says: "I want to edit <app> in Lovable."
2) Jarvis creates (or reuses) a temporary Lovable-facing GitHub repo (frontend-only if needed)'https://github.com/chrfra/openclaw-lovable.git'.
3) Jarvis syncs code to that repo (preserve history where possible; otherwise mirror snapshot) and ensures it's in a Lovable-importable shape.
4) Christian edits in Lovable.
5) Christian says: "Done editing in Lovable."
6) Jarvis merges/migrates the changes back into the canonical app repo, runs QC, then redeploys.

## "New app request" template (Christian → Jarvis)

- App name (one word preferred; I will slugify)
- What it should do (1-3 bullets)
- Public or private (default private)
- Data needs: none / simple notes / file upload / other
