# leeskill — Skill Package Manager

Manages Claude Code skills from the lee-skills repository. Install, remove, list, and update skills with automatic hook registration, rule deployment, and CLAUDE.md integration.

## Quick Start

```bash
git clone https://github.com/ljjohn77/lee-skills.git
cd lee-skills
bash scripts/install.sh leeskill
```

## Usage

| Command | What it does |
|---------|-------------|
| `leeskill` | List all available skills in the repo |
| `leeskill <name>` | Show skill details and open its repo page |
| `leeskill -a <name>` | Install a skill with all dependencies |
| `leeskill -d <name>` | Uninstall a skill and revert changes |
| `leeskill -l` | List locally installed skills with version comparison |
| `leeskill -u <name>` | Update a skill to the latest version |
| `leeskill -p <name>` | Publish a skill (validation runs first) |

## What Gets Installed

```
~/.claude/skills/leeskill/SKILL.md
```

This skill is self-contained — it needs no hooks or rules of its own. It manages other skills.

## Uninstall

```bash
bash scripts/uninstall.sh leeskill
```
