# audit-health — System Health Audit + Anti-Bloat Guard

Monitors Claude Code system health. Compares against 2026-06-24 post-optimization baseline. Enforces progressive disclosure for SKILL.md files.

## Quick Start

```bash
# Install (one command)
leeskill -a audit-health

# Verify
/audit-health

# Uninstall
leeskill -d audit-health
```

## What It Does

| Feature | How |
|---------|-----|
| **Health audit** | `/audit-health` runs 9 diagnostic checks with 🟢🟡🔴 report |
| **Progressive disclosure scan** | Detects SKILL.md >15KB/300 lines; flags multi-mode without pipeline files |
| **Real-time guard** | Hooks fire on every SKILL.md write: warns >15KB/300 lines, errors >20KB/400 lines |
| **MCP guard** | Warns when MCP server count exceeds 8 (baseline: 5) |
| **Baseline comparison** | All metrics compared against 2026-06-24 optimized baseline |

## Install

### Via leeskill (recommended)

```bash
leeskill -a audit-health
```

Progress output:
```
[1/6] Installing skill files...        ✓
[2/6] Installing shared hooks...       ✓
[3/6] Installing shared rules...       ✓
[4/6] Merging hooks into hooks.json... ✓ (2 hooks added)
[5/6] Appending rules to CLAUDE.md...  ✓
[6/6] Verifying installation...        ✓
Done. Run /audit-health to check system health.
```

### Manual install

```bash
git clone https://github.com/lee/lee-skills.git /tmp/lee-skills
bash /tmp/lee-skills/scripts/install.sh audit-health
```

## What Gets Installed

```
~/.claude/
├── skills/audit-health/SKILL.md
├── commands/audit-health.md
├── hooks/
│   ├── guard-skill-bloat.js       # Register in hooks.json: PostToolUse → Write
│   └── guard-mcp-count.js         # Register in hooks.json: PostToolUse → Write
├── rules/common/
│   └── progressive-disclosure.md  # Skill design mandatory rule
└── CLAUDE.md                      # § System Health + § Skill Design appended
```

## Usage

```bash
# Full system diagnostic
/audit-health

# What to expect
## System Health Report
Status: 🟢 HEALTHY

Skills: 78 (safe: <100)     🟢
MCPs:   5  (safe: <8)       🟢
Rules:  112KB (safe: <120K)  🟢
Hooks:  10 (safe: <12)       🟢
...
```

Hooks run automatically — no manual action needed after install.

## Uninstall

```bash
# Via leeskill (recommended)
leeskill -d audit-health

# Manual
bash /tmp/lee-skills/scripts/uninstall.sh audit-health
```

Removes all files, reverts hooks.json, reverts CLAUDE.md additions.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/install.sh <name>` | Install a skill: copy files, merge hooks, append CLAUDE.md, verify |
| `scripts/uninstall.sh <name>` | Remove a skill: delete files, revert hooks, revert CLAUDE.md |
| `scripts/validate.sh <name>` | Pre-upload CI check: JSON schema, file existence, size limits, PD compliance |

## Dependencies

Auto-installed from `shared/`:

| Component | Destination |
|-----------|-------------|
| `shared/hooks/guard-skill-bloat.js` | `~/.claude/hooks/` |
| `shared/hooks/guard-mcp-count.js` | `~/.claude/hooks/` |
| `shared/rules/progressive-disclosure.md` | `~/.claude/rules/common/` |

## Configuration

After install, thresholds are in `~/.claude/CLAUDE.md`:
- `## System Health — Anti-Bloat Rules` — hard limits for skills/MCPs/rules/hooks
- `## Skill Design — Progressive Disclosure` — mandatory SKILL.md design rules

## Notes

- Guard hooks are **pass-through**: warn via stderr, never block tool execution. Files write successfully even when BLOCKED is triggered.
- Scans both global (`~/.claude/skills/`) and project (`.claude/skills/`) directories.
- Recognizes any extra `.md` files as pipeline files — not just `pipeline-*.md`.
- Baseline from three-phase optimization: ~160K→~30K system prompt tokens, eliminated 40s startup delay.
