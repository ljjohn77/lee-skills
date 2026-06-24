# Lee Skills — Claude Code Skill Repository

Available skills for Claude Code. Install with `leeskill -a <name>`.

## Install leeskill First

```bash
leeskill -a leeskill
```

This installs the skill manager itself — you only need to do this once.

## Available Skills

### audit-health — System Health Audit + Anti-Bloat Guards

**What it does:** Monitors Claude Code system health (skills, MCPs, rules, hooks, plugins) against a baseline. Enforces progressive disclosure for SKILL.md files. Warns on MCP bloat.

**What gets installed:**
| Component | Location |
|-----------|----------|
| `/audit-health` command | `~/.claude/commands/` |
| audit-health skill + PD scanner | `~/.claude/skills/audit-health/` |
| guard-skill-bloat hook | `~/.claude/hooks/` |
| guard-mcp-count hook | `~/.claude/hooks/` |
| Progressive Disclosure rule | `~/.claude/rules/common/` |
| Anti-Bloat rules | Appended to `~/.claude/CLAUDE.md` |

**Install:**
```bash
leeskill -a audit-health
```

---

## Manual Install (without leeskill)

If you don't have `leeskill` installed, clone the repo and run the install script:

```bash
git clone https://github.com/lee/lee-skills.git /tmp/lee-skills
cd /tmp/lee-skills
./scripts/install.sh audit-health
```
