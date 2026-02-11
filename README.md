# Specular — Spec-Driven Development for Claude Code

**Specular** is an AI-native development framework that turns natural language requirements into tested, working code through a structured specification pipeline.

It uses **Spec Kit** — a set of `/speckit.*` slash commands inside [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — to guide AI through: Spec → Clarify → Plan → Tasks → Implement → Review.

```
You describe WHAT → Specular (Spec Kit + Claude Code) builds HOW
```

---

## How It Works

```text
/speckit.specify  →  Gherkin .feature file (functional spec)
/speckit.clarify  →  AI QA: detect ambiguities, record answers
/speckit.plan     →  Technical blueprint (API, models, architecture)
/speckit.tasks    →  Phased task list (TDD: RED → GREEN)
/speckit.implement → Execute tasks, run tests in Docker
/speckit.review   →  Review report (tests, coverage, checklist)
```

Each step produces a **traceable artifact**. Nothing is invented out of thin air — every line of code traces back to a Gherkin scenario.

---

## Quick Start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- Docker & Docker Compose
- Git

### New Project Setup

```bash
mkdir my-project && cd my-project
git init

# Copy the Specular framework files from an existing Specular repo
# (see "What to Copy" below)

# Customize for your project
# 1. Edit CLAUDE.md — update Section 2 (Tech Stack) and Section 3 (Structure)
# 2. Edit .specify/memory/constitution.md — adjust principles if needed
# 3. Add your DBML schema to specs/db_schema/
# 4. Verify Docker works
docker compose run --rm test
```

### Add to Existing Repo (Safe Merge)

If you already have a project and want to add Spec Kit without overwriting anything:

```bash
# Copy from a Specular source repo (will NOT overwrite existing files)
SPECULAR_SRC=/path/to/specular-source

# -- Core config --
cp -rn $SPECULAR_SRC/.specify/ .specify/
cp -rn $SPECULAR_SRC/.claude/ .claude/

# -- Docker & test infra (skip if you already have these) --
cp -n $SPECULAR_SRC/Dockerfile ./Dockerfile
cp -n $SPECULAR_SRC/docker-compose.yml ./docker-compose.yml
cp -n $SPECULAR_SRC/pytest.ini ./pytest.ini
cp -n $SPECULAR_SRC/requirements.txt ./requirements.txt

# -- Test scaffolding --
mkdir -p tests/unit tests/integration
cp -n $SPECULAR_SRC/tests/__init__.py tests/
cp -n $SPECULAR_SRC/tests/unit/__init__.py tests/unit/
cp -n $SPECULAR_SRC/tests/integration/__init__.py tests/integration/
cp -n $SPECULAR_SRC/tests/integration/conftest.py tests/integration/

# -- Ignore files (append, don't overwrite) --
cat $SPECULAR_SRC/.gitignore >> .gitignore && sort -u -o .gitignore .gitignore
cat $SPECULAR_SRC/.dockerignore >> .dockerignore && sort -u -o .dockerignore .dockerignore

# -- Spec directories --
mkdir -p specs/db_schema specs/features

# Verify
docker compose run --rm test
```

> **`cp -n`** = no-clobber. Existing files are never overwritten.
> **`.specify/`** and **`.claude/commands/`** are the only directories Spec Kit owns. Your `app/`, `src/`, `tests/unit/`, etc. are untouched.

---

## Your First Feature

Once Specular is installed, open Claude Code in your project:

```bash
claude
```

### Step 1: Write the spec

```
/speckit.specify
Type: COMMAND
Feature: user/CreateUser
Domain: user

Requirement: Users can register with email and password
Context: @specs/db_schema/user.dbml
```

Output: `specs/features/user/CreateUser.feature`

### Step 2: Clarify ambiguities

```
/speckit.clarify @specs/features/user/CreateUser.feature
```

AI asks up to 5 targeted questions. Answers are recorded in the `.feature` file.

### Step 3: Generate technical blueprint

```
/speckit.plan @specs/features/user/CreateUser.feature
```

Output: `specs/features/user/CreateUser.plan.md` — API contracts, Pydantic models, service architecture, ISA mapping.

### Step 4: Break down into tasks

```
/speckit.tasks @specs/features/user/CreateUser.plan.md
```

Output: `specs/features/user/CreateUser.tasks.md`

| Phase | Goal |
|-------|------|
| Phase 1 | Skeletons (schemas, services, routers) |
| Phase 2 | Unit Tests (RED state) |
| Phase 3 | BDD Integration Tests |
| Phase 3.5 | **Verify RED** — all tests must FAIL |
| Phase 4 | Logic Implementation (GREEN state) |
| Phase 5 | Refactor & Cleanup |

### Step 5: Implement

```
/speckit.implement @specs/features/user/CreateUser.tasks.md
```

AI executes tasks phase by phase, running tests in Docker until all green.

### Step 6: Generate review report

```
/speckit.review
```

Output: `specs/features/user/review.md` + `reports/test-report.html`

---

## Project Structure

```text
Project Root
├── .claude/commands/        # Specular slash commands (tracked in git)
├── .specify/                # Specular configuration
│   ├── config/isa.yml       # ISA: Gherkin → Test mapping rules
│   ├── memory/              # Project constitution & principles
│   ├── templates/           # Code generation templates
│   └── scripts/             # Automation scripts
│
├── specs/                   # YOUR specifications
│   ├── db_schema/           # DBML database definitions (source of truth)
│   └── features/            # Gherkin specs organized by domain
│       └── <domain>/
│           ├── <Feature>.feature    # Functional spec
│           ├── <Feature>.plan.md    # Technical blueprint
│           ├── <Feature>.tasks.md   # Implementation tasks
│           └── review.md            # Review report
│
├── app/                     # YOUR implementation code
├── tests/
│   ├── conftest.py          # Your mock fixtures
│   ├── unit/                # Unit tests
│   └── integration/         # BDD integration tests (pytest-bdd)
│       └── conftest.py      # Shared BDD infrastructure
│
├── CLAUDE.md                # Claude Code project instructions
├── Dockerfile               # Test environment
├── docker-compose.yml       # test / lint / report services
└── pytest.ini               # pytest + bdd_features_base_dir
```

**Specular owns**: `.specify/`, `.claude/commands/`, templates, scripts
**You own**: `specs/`, `app/`, `tests/`, `CLAUDE.md`

---

## Customization

### CLAUDE.md

This is your project's instruction file for Claude Code. Update these sections:

| Section | What to change |
|---------|---------------|
| Section 2: Tech Stack | Your framework, DB, libraries |
| Section 3: Structure Map | Your actual directory layout |
| Section 5: Decisions | Your architectural decisions |

### Constitution (`.specify/memory/constitution.md`)

The 8 principles that govern all generated code. Modify to match your team's standards (e.g., change Python → TypeScript, FastAPI → Express).

### ISA Config (`.specify/config/isa.yml`)

Maps Gherkin step types to test code patterns. Extend when adding new step types.

### Docker Services

| Service | Command | Purpose |
|---------|---------|---------|
| `test` | `docker compose run --rm test` | Run all tests |
| `lint` | `docker compose run --rm lint` | Type checking (mypy) |
| `report` | `docker compose run --rm report` | HTML + JUnit XML reports |

---

## What is What

| Term | What it is |
|------|------------|
| **Specular** | The overall framework (this repo's structure, conventions, and principles) |
| **Spec Kit** | The `/speckit.*` slash commands that drive the workflow inside Claude Code |
| **ISA** | Instruction Set Architecture — maps Gherkin steps to test code patterns |
| **CLAUDE.md** | Project-level instructions that Claude Code reads on every session |
| **Constitution** | The 8 non-negotiable coding principles (`.specify/memory/constitution.md`) |

### What to Copy (Framework) vs What's Yours (Project)

| Copy to new projects | Don't copy (project-specific) |
|---|---|
| `.claude/commands/` | `specs/features/*/` |
| `.specify/` (config, templates, scripts, memory) | `specs/db_schema/*` |
| `CLAUDE.md` (then customize Sections 2-3) | `app/*` |
| `Dockerfile`, `docker-compose.yml` | `tests/conftest.py` |
| `pytest.ini`, `requirements.txt` | `tests/unit/test_*` |
| `.gitignore`, `.dockerignore` | `tests/integration/test_*` |
| `tests/integration/conftest.py` (shared BDD infra) | `reports/` |
