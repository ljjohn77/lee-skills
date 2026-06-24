#!/usr/bin/env bash
set -e

SKILL_NAME="${1:?Usage: uninstall.sh <skill-name>}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO_DIR/skills/$SKILL_NAME"

if [ ! -f "$SKILL_DIR/install.json" ]; then
    echo "Error: skill '$SKILL_NAME' not found"
    exit 1
fi

expand_path() { echo "${1/#~/$HOME}"; }

echo ""
echo "Uninstalling $SKILL_NAME..."
echo "==========================="

# ── 1. Remove skill files ──
echo "[1/5] Removing skill files..."
python3 -c "
import json, os, shutil
with open('$SKILL_DIR/install.json') as f:
    m = json.load(f)
for src, dest in m.get('files', {}).items():
    d = os.path.expanduser(dest.replace('~', os.path.expanduser('~')))
    if os.path.exists(d):
        if os.path.isdir(d):
            shutil.rmtree(d)
        else:
            os.remove(d)
        print(f'  Removed: {d}')
"
echo "  Done"

# ── 2. Remove command files ──
echo "[2/5] Removing command files..."
if [ -d "$SKILL_DIR/commands" ]; then
    for cmd in "$SKILL_DIR/commands/"*.md; do
        [ -f "$cmd" ] || continue
        cmdname=$(basename "$cmd")
        target="$HOME/.claude/commands/$cmdname"
        if [ -f "$target" ]; then
            rm "$target"
            echo "  Removed: $target"
        fi
    done
fi
echo "  Done"

# ── 3. Remove hooks ──
echo "[3/5] Removing hooks from hooks.json..."
python3 -c "
import json, os
hooks_file = os.path.expanduser('$HOME/.claude/hooks/hooks.json')
with open('$SKILL_DIR/install.json') as f:
    manifest = json.load(f)

if os.path.exists(hooks_file):
    with open(hooks_file) as f:
        h = json.load(f)
    # Get descriptions of hooks registered by this skill
    skill_descs = set()
    for event, entries in manifest.get('hooks', {}).items():
        for entry in entries:
            skill_descs.add(entry.get('description', ''))
    # Remove matching entries
    removed = 0
    for event in list(h.get('hooks', {}).keys()):
        new_entries = []
        for entry in h['hooks'].get(event, []):
            if entry.get('description', '') in skill_descs:
                removed += 1
            else:
                new_entries.append(entry)
        h['hooks'][event] = new_entries
        if not h['hooks'][event]:
            del h['hooks'][event]
    # Backup and write
    backup = hooks_file + '.backup.' + str(int(__import__('time').time()))
    os.rename(hooks_file, backup)
    with open(hooks_file, 'w') as f:
        json.dump(h, f, indent=2)
    print(f'  {removed} hooks removed (backup: {os.path.basename(backup)})')
else:
    print('  No hooks.json found — nothing to remove')
"
echo "  Done"

# ── 4. Revert CLAUDE.md additions ──
echo "[4/5] Reverting CLAUDE.md..."
python3 -c "
import json, os, time
with open('$SKILL_DIR/install.json') as f:
    m = json.load(f)
md_config = m.get('claude_md', {})
if not md_config:
    print('  No CLAUDE.md changes to revert')
    exit()

append_file = os.path.join('$SKILL_DIR', md_config['append_file'])
anchor = md_config.get('anchor_after', '')
claude_md = os.path.expanduser('$HOME/.claude/CLAUDE.md')

if not os.path.exists(claude_md) or not os.path.exists(append_file):
    print('  Nothing to revert')
    exit()

with open(append_file) as f:
    added = f.read().strip()

with open(claude_md) as f:
    content = f.read()

if added in content:
    backup = claude_md + '.backup.' + str(int(time.time()))
    os.rename(claude_md, backup)
    new_content = content.replace(added, '').rstrip()
    # Clean up double newlines
    while '\n\n\n' in new_content:
        new_content = new_content.replace('\n\n\n', '\n\n')
    with open(claude_md, 'w') as f:
        f.write(new_content + '\n')
    print(f'  CLAUDE.md reverted (backup: {os.path.basename(backup)})')
else:
    print(f'  Anchor \"{anchor}\" content not found — may have been manually modified. Skipping.')
"
echo "  Done"

# ── 5. Verify ──
echo "[5/5] Verifying..."
if [ -d "$HOME/.claude/skills/$SKILL_NAME" ]; then
    echo "  ⚠️  Skill directory still exists (may contain user-modified files)"
else
    echo "  ✅ Skill directory removed"
fi
echo ""
echo "Done. $SKILL_NAME uninstalled."
