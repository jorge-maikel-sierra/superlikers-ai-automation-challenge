# AGENTS.md — Superlikers AI Automation Challenge

## Project

WhatsApp chatbot for contests/promotions. **Zero application code** — the entire automation lives in **n8n workflows** (exported as JSON to `n8n/workflows/`). Orchestrator runs via Docker.

## Source of truth

- `docs/state-machine.md` — conversational state machine (the core logic)
- `docs/api-contracts.md` — Superlikers API endpoints, payloads, error codes
- `docs/session-schema.md` — session persistence model
- `docker/docker-compose.yml` — n8n service definition
- `docker/.env.example` — required env vars (`SUPERLIKERS_API_KEY`, `OPENAI_API_KEY`, etc.)

## Dev workflow

SDD (Specification Driven Development). Full cycle: `sdd-{explore,propose,spec,design,tasks,apply,verify,archive}`.

## Commands

```bash
# Start n8n
docker compose -f docker/docker-compose.yml up -d

# Logs
docker compose -f docker/docker-compose.yml logs -f n8n

# Stop
docker compose -f docker/docker-compose.yml down

# Restart
docker compose -f docker/docker-compose.yml restart n8n

# Backup workflows from running n8n
docker exec superlikers-n8n n8n export:workflow --all --output=/backup/workflows
```

## Conventions

| Aspect | Rule |
|--------|------|
| Commits | Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:` |
| Branching | `feature/<name>` from `main` |
| Workflows | Export n8n workflows as `.json` to `n8n/workflows/` |
| Schemas | JSON Schema in `prompts/schemas/` |
| System prompts | in `prompts/system/` |
| Docs | in `docs/`, all in Spanish |
| Env | `docker/.env` from `docker/.env.example`, never commit |

## Misc

- No test framework exists — tests are manual via `tests/test-plan.md`
- No CI, no lint, no typecheck, no build step
- `prompts/schemas/` and `prompts/system/` are currently empty — create files there as needed
- No README.md exists
