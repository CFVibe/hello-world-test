# OpenClaw Mission Control — Install Notes (this machine)

Repo: https://github.com/abhi1693/openclaw-mission-control

## What I installed

1) Cloned the repository (no system packages installed yet)
- Installed/created directory:
  - /home/cf/.openclaw/workspace/third_party/openclaw-mission-control
- This contains:
  - compose.yml, backend/, frontend/, install.sh, docs/, etc.

2) Attempted to run the upstream installer in Docker mode (first run)
- Command attempted:
  - cd /home/cf/.openclaw/workspace/third_party/openclaw-mission-control
  - ./install.sh --mode docker --backend-port 8000 --frontend-port 3000 --public-host localhost --api-url http://localhost:8000 --token-mode generate
- Result:
  - Installer detected Ubuntu + apt.
  - Docker was missing at the time.
  - It prompted to install Docker tooling and requested sudo.
  - The run was stopped at the sudo password prompt because the agent cannot enter your sudo password.

3) Attempted to run the upstream installer again after Docker was installed
- Result:
  - Installer created / updated the repo root .env file.
  - It then tried to start Docker Compose, hit a Docker socket permission error, and retried with sudo.
  - The run was stopped again at the sudo password prompt.

Current state:
- .env exists at:
  - /home/cf/.openclaw/workspace/third_party/openclaw-mission-control/.env
- It contains a generated LOCAL_AUTH_TOKEN (treat as a password).

## Where it is installed

- Source checkout:
  - /home/cf/.openclaw/workspace/third_party/openclaw-mission-control

- No Docker containers are running yet.
- No .env was written yet (installer would create it once Docker is available).

## Final install status

Mission Control is now installed and running (Docker mode).

## What is running

Containers (Docker Compose):
- backend: http://localhost:8000/healthz
- frontend: http://localhost:3000
- db: Postgres (host port 5432)
- redis: host port 6379
- webhook-worker: background worker

You can see the running stack with:
- cd /home/cf/.openclaw/workspace/third_party/openclaw-mission-control
- docker compose -f compose.yml --env-file .env ps

## How it was installed

- Docker was installed via apt (Ubuntu 24.04):
  - docker.io
  - docker-compose-v2
- Repo checkout location:
  - /home/cf/.openclaw/workspace/third_party/openclaw-mission-control
- Installer used:
  - /home/cf/.openclaw/workspace/third_party/openclaw-mission-control/install.sh
- Installer command used (Docker mode):
  - ./install.sh --mode docker --backend-port 8000 --frontend-port 3000 --public-host localhost --api-url http://localhost:8000 --token-mode manual
  - (manual mode so we reused the existing LOCAL_AUTH_TOKEN from .env)

## Config files created/updated

- /home/cf/.openclaw/workspace/third_party/openclaw-mission-control/.env
  - Contains AUTH_MODE=local and LOCAL_AUTH_TOKEN (treat as a password).

## Stop / start

Stop:
- cd /home/cf/.openclaw/workspace/third_party/openclaw-mission-control
- docker compose -f compose.yml --env-file .env down

Start:
- cd /home/cf/.openclaw/workspace/third_party/openclaw-mission-control
- docker compose -f compose.yml --env-file .env up -d
