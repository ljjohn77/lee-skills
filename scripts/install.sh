#!/usr/bin/env bash
set -e

SKILL_NAME="${1:?Usage: install.sh <skill-name>}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO_DIR/skills/$SKILL_NAME"
SHARED_DIR="$REPO_DIR/shared"

if [ ! -f "$SKILL_DIR/install.json" ]; then
    echo "Error: skill '$SKILL_NAME' not found in $SKILL_DIR"
    exit 1
fi

expand_path() { echo "${1/#~/$HOME}"; }

# ── Parse manifest ──
MANIFEST=$(python3 -c "
import json, os, sys
with open('$SKILL_DIR/install.json') as f:
    m = json.load(f)
print(f'NAME={m[\"name\"]}')
print(f'VERSION={m[\"version\"]}')
print(f'FILE_COUNT={len(m.get(\"files\",{}))}')
print(f'SHARED_COUNT={len(m.get(\"shared\",[]))}')
HOOK_COUNT = sum(len(v) for v in m.get('hooks', {}).values())
print(f'HOOK_COUNT={HOOK_COUNT}')
print(f'HAS_CLAUDE_MD={\"true\" if m.get(\"claude_md\") else \"false\"}')
")
eval "$MANIFEST"

TOTAL=$((FILE_COUNT + SHARED_COUNT + 1))
STEP=0

progress() { STEP=$((STEP + 1)); echo "[$STEP/$TOTAL] $1..."; }

echo ""
echo "Installing $NAME v$VERSION"
echo "=========================="

# ── 1. Copy skill files ──
progress "Installing skill files"
python3 -c "
import json, os, shutil
with open('$SKILL_DIR/install.json') as f:
    m = json.load(f)
for src, dest in m.get('files', {}).items():
    d = os.path.expanduser(dest.replace('~', os.path.expanduser('~')))
    os.makedirs(os.path.dirname(d), exist_ok=True)
    shutil.copy2(os.path.join('$SKILL_DIR', src), d)
    print(f'  {src} → {d}')
"
echo "  Done"

# ── 2. Install shared dependencies ──
if [ "$SHARED_COUNT" -gt 0 ]; then
    progress "Installing shared dependencies"
    python3 -c "
import json, os, shutil
with open('$SKILL_DIR/install.json') as f:
    m = json.load(f)
for dep in m.get('shared', []):
    src = os.path.join('$REPO_DIR', dep['source'])
    dest = os.path.expanduser(dep['dest'].replace('~', os.path.expanduser('~')))
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy2(src, dest)
    print(f'  {dep[\"source\"]} → {dest}')
"
    echo "  Done"
fi

# ── 3. Merge hooks ──
HOOKS_JSON="$HOME/.claude/hooks/hooks.json"
if [ "$HOOK_COUNT" -gt 0 ]; then
    progress "Merging hooks into hooks.json"
    python3 -c "
import json, os

hooks_file = os.path.expanduser('$HOOKS_JSON')
with open('$SKILL_DIR/install.json') as f:
    manifest = json.load(f)

# Load existing hooks
if os.path.exists(hooks_file):
    with open(hooks_file) as f:
        existing = json.load(f)
else:
    existing = {'hooks': {}}

# Merge new hooks
new_hooks = manifest.get('hooks', {})
added = 0
for event, entries in new_hooks.items():
    if event not in existing.setdefault('hooks', {}):
        existing['hooks'][event] = []
    for entry in entries:
        # Skip if already present (dedup by description)
        existing_descs = [e.get('description', '') for e in existing['hooks'][event]]
        if entry.get('description', '') not in existing_descs:
            existing['hooks'][event].append(entry)
            added += 1

# Backup original
backup = hooks_file + '.backup.' + str(int(__import__('time').time()))
if os.path.exists(hooks_file):
    os.rename(hooks_file, backup)
    print(f'  Backed up to {os.path.basename(backup)}')

with open(hooks_file, 'w') as f:
    json.dump(existing, f, indent=2)
print(f'  {added} hooks added')
"
    echo "  Done"
fi

# ── 4. Append CLAUDE.md rules ──
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
if [ "$HAS_CLAUDE_MD" = "true" ]; then
    progress "Appending rules to CLAUDE.md"
    python3 -c "
import json, os

with open('$SKILL_DIR/install.json') as f:
    m = json.load(f)
md_config = m.get('claude_md', {})
append_file = os.path.join('$SKILL_DIR', md_config['append_file'])
anchor = md_config.get('anchor_after', '')
dedup = md_config.get('dedup', True)
claude_md = os.path.expanduser('$CLAUDE_MD')

with open(append_file) as f:
    new_content = f.read()

if os.path.exists(claude_md):
    with open(claude_md) as f:
        existing = f.read()

    if dedup and anchor and anchor in existing:
        print(f'  Anchor \"{anchor}\" already present — skipping (dedup)')
    elif dedup and new_content.strip() in existing:
        print(f'  Content already present — skipping (dedup)')
    else:
        backup = claude_md + '.backup.' + str(int(__import__('time').time()))
        os.rename(claude_md, backup)
        print(f'  Backed up to {os.path.basename(backup)}')
        with open(claude_md, 'w') as f:
            f.write(existing.rstrip() + '\n\n' + new_content)
        print(f'  Rules appended')
else:
    with open(claude_md, 'w') as f:
        f.write(new_content)
    print(f'  CLAUDE.md created with rules')
"
    echo "  Done"
fi

# ── 5. Verify ──
progress "Verifying installation"
echo "  audit-health/$NAME installed at ~/.claude/skills/$SKILL_NAME/"
echo ""
echo "Done. Run /audit-health to verify system health."
