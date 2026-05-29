# Claude harness Architecture

## 1. Overview

`claude-code-harness` is a modular, autonomous development framework designed to maximize the capabilities of Claude Code. The core design philosophy is to support a systematic **Plan → Work → Review** development cycle using three primary extension mechanisms: **Skills**, **Rules**, and **Hooks**.

## 2. Three-Layer Architecture

This plugin adopts the following three-layer architecture to improve reusability and maintainability.

```mermaid
graph TD
    subgraph Profile Layer
        A[profiles/claude-worker.yaml]
    end
    subgraph Workflow Layer
        B[init.yaml, plan.yaml, work.yaml, review.yaml]
    end
    subgraph Skill Layer
        C[30+ SKILL.md files]
    end

    A -- references --> B;
    B -- uses --> C;
```

- **Skill Layer**: Self-contained knowledge units defined as `SKILL.md` files. They contain specific procedures and knowledge for executing particular tasks (e.g., security review, code implementation).
- **Workflow Layer**: Defined as `*.yaml` files, these orchestrate **Skills** to execute specific development phases (e.g., `/work`). They manage step ordering, conditional branching, and error handling.
- **Profile Layer**: Defines the overall behavior of the plugin. Specifies which workflows are assigned to which commands and which Skill categories are permitted.

## 3. Directory Structure

```
claude-code-harness/
├── .claude-plugin/         # Plugin metadata
│   ├── plugin.json
│   └── hooks.json
├── skills/                 # Skill definitions (SKILL.md + references/)
│   ├── impl/               # Implementation skills
│   ├── harness-review/     # Review skills
│   ├── verify/             # Verification skills
│   ├── planning/           # Planning skills
│   ├── setup/              # Setup skills
│   ├── ci/                 # CI/CD-related skills
│   └── ...                 # 30+ other skills
├── agents/                 # Sub-agent definitions (Markdown)
├── hooks/                  # Hook definitions (hooks.json)
├── scripts/                # Automation shell scripts
├── docs/                   # Documentation
└── templates/              # Various templates
```

## 4. Key Components

### 4.1. Skills

Each skill specifies a `description` (when to use it) and `allowed-tools` (permitted tools), supporting autonomous discovery by Claude and safe execution.

### 4.2. Rules

Configuration files strictly defined in `claude-code-harness.config.schema.json` enforce safety (`dry-run` mode) and path restrictions (`protected` paths).

### 4.3. Hooks

Defined in `hooks.json`, hooks automatically execute scripts at key points in the development process.
- **SessionStart**: Environment check at session start
- **PostToolUse**: Automatic testing and change tracking after file edits
- **Stop**: Summary generation at session end

### 4.4. Parallel Processing

The `/harness-review` command launches multiple `code-reviewer` sub-agents simultaneously, running security, performance, and quality reviews in parallel, dramatically reducing feedback time.
