---
name: leeskill
description: Install, remove, list, and manage Claude Code skills from the lee-skills repository. Use when user wants to install a skill, remove a skill, browse available skills, or check installed versions.
type: global
allowed-tools: Bash, Read, Write, Edit
---

# leeskill — Skill Package Manager

Manages Claude Code skills distributed via the `lee-skills` GitHub repository. Handles installation of skill files, hooks, rules, and CLAUDE.md entries.

## Repository

```
https://github.com/lee/lee-skills
```

Local clone for offline use: `~/.claude/lee-skills/`

## Commands

### `leeskill` (no args) — List available skills

Fetches the repo README and lists all skills with one-line descriptions.

If the repo is not cloned locally, clone it first:
```bash
git clone https://github.com/lee/lee-skills.git ~/.claude/lee-skills
```

Then read the catalog:
```bash
cat ~/.claude/lee-skills/README.md
```

### `leeskill <name>` — Show skill details

Read the skill's README for features, install steps, configuration, and notes.

```bash
cat ~/.claude/lee-skills/skills/<name>/README.md
```

Also open the repo page: `https://github.com/lee/lee-skills/tree/main/skills/<name>`

### `leeskill -a <name>` — Install a skill

Install a skill with all its dependencies (hooks, rules, CLAUDE.md entries).

**What it does:**
1. Clones/updates the lee-skills repo
2. Runs `scripts/install.sh <name>` — copies skill files, shared deps, merges hooks, appends CLAUDE.md rules
3. Shows progress for each step
4. Runs a verification check if the skill has one

```bash
cd ~/.claude/lee-skills && git pull 2>/dev/null || git clone https://github.com/lee/lee-skills.git ~/.claude/lee-skills
bash ~/.claude/lee-skills/scripts/install.sh <name>
```

### `leeskill -d <name>` — Remove a skill

Removes a skill and reverts installation changes.

```bash
# 1. Read install.json to know what was installed
# 2. Remove skill files from ~/.claude/skills/<name>/
# 3. Remove command from ~/.claude/commands/
# 4. Remove hooks from ~/.claude/hooks/hooks.json (by description match)
# 5. Remove CLAUDE.md additions (reverse of append)
# 6. Report what was cleaned up
```

Implementation: read the install.json from the repo, reverse each step.

### `leeskill -l` — List installed skills

Check which lee-skills are installed locally and compare versions.

```bash
for d in ~/.claude/skills/*/; do
    name=$(basename "$d")
    if [ -f ~/.claude/lee-skills/skills/$name/install.json ]; then
        installed_version=$(python3 -c "import json; print(json.load(open('$d/SKILL.md').read().split('---')[1] if '---' in open('$d/SKILL.md').read() else '{}').get('version','?'))" 2>/dev/null)
        repo_version=$(python3 -c "import json; print(json.load(open('$HOME/.claude/lee-skills/skills/$name/install.json'))['version'])" 2>/dev/null)
        status="OK"
        [ "$installed_version" != "$repo_version" ] && status="UPDATE ($installed_version → $repo_version)"
        echo "  $name: $status"
    fi
done
```

### `leeskill -u <name>` — Update a skill

```bash
cd ~/.claude/lee-skills && git pull
leeskill -a <name>
```

### `leeskill -p <name>` — Publish/upload a skill

Upload a local skill to the lee-skills repo. **Validation runs first — blocks upload if checks fail.**

```bash
# 1. Run validation (BLOCKING — must pass)
bash ~/.claude/lee-skills/scripts/validate.sh <name>

# 2. If validation passes, commit and push
cd ~/.claude/lee-skills
git add skills/<name>/ shared/ .github/
git commit -m "feat: add <name> v<version>"
git push origin main
```

**Pre-upload checks enforced by `validate.sh`:**
- [ ] install.json exists and is valid JSON
- [ ] Required fields: name, version, files
- [ ] All files in manifest exist on disk
- [ ] SKILL.md has YAML frontmatter
- [ ] SKILL.md within PD limits (<400 lines, <20KB)
- [ ] README.md exists and is ≥10 lines
- [ ] Hook commands reference valid script paths
- [ ] install.sh syntax valid

**CI:** GitHub Actions (`.github/workflows/validate.yml`) re-runs all checks on push/PR.

## Install.json Format

Each skill directory contains `install.json` that defines the installation:

```json
{
  "name": "skill-name",
  "version": "1.0.0",
  "description": "...",
  "files": { "source": "dest-path" },
  "shared": [{ "source": "shared/...", "dest": "~/.claude/..." }],
  "hooks": { "PostToolUse": [{ "matcher": "...", "command": "...", "description": "..." }] },
  "claude_md": { "append_file": "...", "anchor_after": "...", "dedup": true }
}
```

## Repo Structure

```
lee-skills/
├── README.md              # Unified catalog
├── shared/                # Cross-skill dependencies (auto-installed)
│   ├── hooks/             # Shared hook scripts
│   └── rules/             # Shared rule files
├── skills/
│   └── <name>/
│       ├── README.md      # Detailed skill documentation
│       ├── SKILL.md       # Claude Code skill definition
│       ├── install.json   # Installation manifest
│       ├── commands/      # Slash command files
│       └── ...            # Pipeline files, assets
└── scripts/
    └── install.sh         # Automated installer
```
