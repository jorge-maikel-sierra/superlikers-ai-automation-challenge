# Skill Registry — superlikers-ai-automation-challenge

Generated: 2026-06-24

## Project Context
- **Project**: superlikers-ai-automation-challenge
- **Stack**: n8n workflows (JSON), Docker, no runtime code
- **Language**: JavaScript (n8n Code Nodes), YAML (Docker Compose)
- **SDD**: Active — all phases enabled

---

## User-Level Skills

### branch-pr
- **Trigger**: Creating, opening, or preparing PRs for review
- **Path**: `~/.config/opencode/skills/branch-pr/SKILL.md`
- **Compact Rules**:
  - Every PR MUST link an approved issue (`status:approved` label)
  - Every PR MUST have exactly one `type:*` label
  - Automated checks must pass before merge
  - Branch naming: `^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`
  - PR body must include: linked issue, PR type, summary, changes table, test plan, contributor checklist
  - Conventional commits required: `type(scope): description`
  - No `Co-Authored-By` trailers
  - Run `shellcheck` on modified scripts before push

### chained-pr
- **Trigger**: PRs over 400 lines, stacked PRs, review slices
- **Path**: `~/.config/opencode/skills/chained-pr/SKILL.md`
- **Compact Rules**:
  - Split PRs over 400 changed lines unless `size:exception` approved
  - Keep each PR reviewable in ≤60 minutes
  - One deliverable work unit per PR; keep tests/docs together
  - Every child PR includes dependency diagram marking current with `📍`
  - Stacked-to-main: each PR merges to main independently
  - Feature Branch Chain: tracker PR (draft), children target parent branch
  - Polluted diffs = base bugs: retarget or rebase
  - Do not mix chain strategies after user choice

### cognitive-doc-design
- **Trigger**: Writing guides, READMEs, RFCs, onboarding, architecture, review-facing docs
- **Path**: `~/.config/opencode/skills/cognitive-doc-design/SKILL.md`
- **Compact Rules**:
  - Lead with the answer: decision/action/outcome first
  - Progressive disclosure: happy path → details → edge cases → references
  - Chunking: group related info into small sections, keep flat lists short
  - Signposting: headings, labels, callouts, summaries
  - Recognition over recall: tables, checklists, examples, templates
  - Review empathy: docs designed so reviewers verify without reconstructing the story
  - Default structure: outcome title → quick path → details table → checklist → next step

### comment-writer
- **Trigger**: PR feedback, issue replies, reviews, Slack messages, GitHub comments
- **Path**: `~/.config/opencode/skills/comment-writer/SKILL.md`
- **Compact Rules**:
  - Be useful fast: start with actionable point, do not recap the whole PR
  - Be warm and direct: sound like a thoughtful teammate
  - Keep it short: 1-3 paragraphs or tight bullet list
  - Explain why: give technical reason when asking for change
  - Avoid pile-ons: comment on highest-value issue
  - Match thread language: Rioplatense voseo in Spanish (`podés`, `tenés`, `fijate`, `dale`)
  - No em dashes: use commas, periods, or parentheses
  - Formula: direct observation → why it matters (if needed) → concrete next action

### issue-creation
- **Trigger**: Creating GitHub issues, bug reports, feature requests
- **Path**: `~/.claude/skills/issue-creation/SKILL.md`
- **Compact Rules**:
  - Blank issues disabled — MUST use template (bug report or feature request)
  - Every issue gets `status:needs-review` automatically
  - Maintainer MUST add `status:approved` before any PR
  - Questions go to Discussions, not issues
  - Body template: summary, expected/actual behavior, reproduction steps, environment, additional context

### judgment-day
- **Trigger**: Judgment day, dual review, adversarial review, juzgar
- **Path**: `~/.claude/skills/judgment-day/SKILL.md`
- **Compact Rules**:
  - Launch two blind judges in parallel with identical target/criteria
  - Wait for both judges before synthesis
  - Classify warnings as `WARNING (real)` only if normal intended use can trigger; otherwise `INFO`
  - Ask before fixing Round 1 confirmed issues
  - Re-judge in parallel after fixes before commit/push/done
  - Terminal states: `JUDGMENT: APPROVED` or `JUDGMENT: ESCALATED`
  - After 2 fix iterations with remaining issues, ask user whether to continue
  - Resolve project skills before launching agents

### work-unit-commits
- **Trigger**: Implementation, commit splitting, chained PRs, keeping tests/docs with code
- **Path**: `~/.config/opencode/skills/work-unit-commits/SKILL.md`
- **Compact Rules**:
  - Commit by work unit: a commit is a deliverable behavior, fix, migration, or docs unit
  - Do not commit by file type (avoid separate model/service/test commits)
  - Keep tests with the code they verify
  - Keep docs with the user-visible change they explain
  - Tell a story: reviewer should understand why each commit exists from diff + message
  - Each commit should be a candidate chained PR slice
  - Checklist before committing: one clear purpose, repo makes sense, tests/docs included, reasonable rollback, outcome-oriented message
  - SDD workload guard: if >400-line forecast, group into chained PRs before implementation

### skill-creator
- **Trigger**: New skills, agent instructions, documenting AI usage patterns
- **Path**: `~/.config/opencode/skills/skill-creator/SKILL.md`
- **Compact Rules**:
  - Skill is a runtime instruction contract for LLM, not human documentation
  - `description` MUST be one physical line, quoted, YAML-safe, trigger words first, ≤250 chars
  - Frontmatter: name, description, license, metadata.author, metadata.version
  - No `Keywords` section
  - References must point to local files
  - Target 180–450 body tokens, recommended max 700, hard max 1000
  - Sections in order: Activation Contract, Hard Rules, Decision Gates, Execution Steps, Output Contract, References
  - Supporting material goes in `assets/` or `references/`

### go-testing
- **Trigger**: Go tests, go test coverage, Bubbletea teatest, golden files
- **Path**: `~/.claude/skills/go-testing/SKILL.md`
- **Compact Rules**:
  - Prefer table-driven tests with `t.Run(tt.name, ...)`
  - Test behavior and state transitions, not implementation trivia
  - Use `t.TempDir()` for filesystem tests
  - Keep integration tests skippable with `testing.Short()`
  - Bubbletea: test `Model.Update()` directly; use `teatest` only for interactive flows
  - Golden files must be deterministic; update only through repo's `-update` path
  - Use small mocks/interfaces around system/command boundaries

### deploy-model (Microsoft)
- **Trigger**: Deploy model, deploy gpt, create deployment, model deployment
- **Path**: `~/.agents/skills/microsoft-foundry/models/deploy-model/SKILL.md`
- **Compact Rules**:
  - Routes to sub-skills: preset (quick deploy), customize (full control), capacity (find availability)
  - Simple deployment → preset; needs version/SKU/capacity control → customize; needs quota check → capacity
  - Requires Azure CLI authenticated (`az login`)
  - Do NOT use for listing existing deployments (use `foundry_models_deployments_list` MCP tool)

### preset (Microsoft)
- **Trigger**: Quick deployment, optimal region, best region, automatic region selection
- **Path**: `~/.agents/skills/microsoft-foundry/models/deploy-model/preset/SKILL.md`
- **Compact Rules**:
  - Automatically checks capacity in current region first
  - If no capacity, analyzes all regions and shows alternatives
  - Deploys with GlobalStandard SKU by default
  - Requires `PROJECT_RESOURCE_ID` env var or interactive input
  - Not for custom SKU, version, capacity config (use customize)

### customize (Microsoft)
- **Trigger**: Custom deployment, version/SKU/capacity, RAI policy, content filter
- **Path**: `~/.agents/skills/microsoft-foundry/models/deploy-model/customize/SKILL.md`
- **Compact Rules**:
  - Interactive step-by-step guided deployment
  - Supports: GlobalStandard, Standard, ProvisionedManaged, DataZoneStandard SKUs
  - Full control: version, capacity, RAI content filter, dynamic quota, priority processing, spillover
  - Requires Azure CLI authenticated
  - Not for quick/automatic deployment (use preset)

### capacity (Microsoft)
- **Trigger**: Find capacity, check quota, where can I deploy, capacity discovery
- **Path**: `~/.agents/skills/microsoft-foundry/models/deploy-model/capacity/SKILL.md`
- **Compact Rules**:
  - Read-only analysis — does NOT deploy
  - Discovers capacity across all accessible regions and projects
  - Returns ranked table of regions/projects with available capacity
  - Hands off to preset or customize for actual deployment
  - Not for quota increase requests (direct user to Azure Portal)

### microsoft-foundry (main)
- **Trigger**: Deploy/evaluate/manage Foundry agents, batch eval, prompt optimization, RBAC, quota
- **Path**: `~/.agents/skills/microsoft-foundry/SKILL.md`
- **Compact Rules**:
  - MUST read corresponding sub-skill before executing any workflow
  - Sub-skills: deploy, invoke, observe, trace, troubleshoot, create, eval-datasets, project/create, resource/create, models/deploy-model, quota, rbac
  - Each sub-skill has its own pre-checks and validation logic
  - Do not call MCP tools for a workflow without reading its skill document

### find-skills
- **Trigger**: How do I do X, find a skill for X, is there a skill that can...
- **Path**: `~/.agents/skills/find-skills/SKILL.md`
- **Compact Rules**:
  - Check skills.sh leaderboard first for popular/battle-tested skills
  - Use `npx skills find [query]` to search
  - Verify quality before recommending: install count (1K+ preferred), source reputation, GitHub stars
  - Present: skill name, description, install count, install command, link to learn more
  - Offer to install with `npx skills add <owner/repo@skill> -g -y`
  - Suggest `npx skills init` if no existing skill found

---

## Project Convention Files

### AGENTS.md
- **Path**: `AGENTS.md`
- WhatsApp chatbot for contests/promotions. Zero application code — all automation in n8n workflows (JSON)
- SDD workflow active
- Conventional commits, `feature/<name>` branching
- Workflows exported as `.json` to `n8n/workflows/`
- JSON Schema in `prompts/schemas/`, system prompts in `prompts/system/`
- Docs in Spanish in `docs/`
- No test framework — manual tests via `tests/test-plan.md`
- No CI, lint, typecheck, build step
