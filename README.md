# Lee Skills — Claude Code Skill Repository

Ready-to-install skills for Claude Code. Each skill is self-contained with its own install/uninstall scripts. No prerequisites beyond `git` and `bash`.

## Install Any Skill

```bash
git clone https://github.com/ljjohn77/lee-skills.git
cd lee-skills
bash scripts/install.sh <skill-name>
```

Uninstall: `bash scripts/uninstall.sh <skill-name>`

## Available Skills

### leeskill — Skill Package Manager

Convenience wrapper. Once installed, use `leeskill -a <name>` instead of the git+script flow.

```bash
bash scripts/install.sh leeskill
```

Then: `leeskill -a audit-health`, `leeskill -l`, etc.

[Full docs →](skills/leeskill/README.md)

### audit-health — System Health Audit + Anti-Bloat Guard

Monitors Claude Code system health. Runs 9 diagnostic checks against a post-optimization baseline. Enforces progressive disclosure for SKILL.md files with real-time guard hooks.

```bash
bash scripts/install.sh audit-health
```

Then: `/audit-health`

[Full docs →](skills/audit-health/README.md)

---

## Repo Structure

```
lee-skills/
├── README.md                    # This page
├── scripts/                     # install.sh, uninstall.sh, validate.sh
├── shared/                      # Cross-skill hooks and rules
│   ├── hooks/
│   └── rules/
└── skills/                      # All skills at the same level
    ├── leeskill/                # Package manager (optional)
    │   ├── README.md
    │   ├── SKILL.md
    │   └── install.json
    └── audit-health/            # System health audit
        ├── README.md
        ├── SKILL.md
        ├── install.json
        └── commands/
```

## For Skill Authors

1. Create `skills/<name>/` with SKILL.md, README.md, install.json
2. Run `bash scripts/validate.sh <name>` — 9 checks must pass
3. Submit a PR — CI re-runs validation automatically
