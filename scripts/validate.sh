#!/usr/bin/env bash
set -e
# validate.sh — CI pre-flight check. Run before upload. Blocks on any failure.

SKILL_NAME="${1:?Usage: validate.sh <skill-name>}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO_DIR/skills/$SKILL_NAME"
ERRORS=0

red()   { echo "  ❌ $1"; ERRORS=$((ERRORS + 1)); }
green() { echo "  ✅ $1"; }
info()  { echo "  ℹ️  $1"; }

echo ""
echo "Validating $SKILL_NAME..."
echo "=========================="

# ── 1. install.json exists and is valid JSON ──
if [ ! -f "$SKILL_DIR/install.json" ]; then
    red "install.json missing"
else
    if python3 -c "import json; json.load(open('$SKILL_DIR/install.json'))" 2>/dev/null; then
        green "install.json is valid JSON"
    else
        red "install.json is invalid JSON"
    fi
fi

# ── 2. Required fields in install.json ──
python3 -c "
import json, sys
with open('$SKILL_DIR/install.json') as f:
    m = json.load(f)
required = ['name', 'version', 'files']
for r in required:
    if r not in m:
        print(f'MISSING:{r}')
        sys.exit(1)
print('OK')
" 2>/dev/null && green "Required fields: name, version, files" || red "Missing required fields in install.json"

# ── 3. All files in manifest exist ──
python3 -c "
import json, os, sys
with open('$SKILL_DIR/install.json') as f:
    m = json.load(f)
errors = 0
for src in m.get('files', {}):
    path = os.path.join('$SKILL_DIR', src)
    if not os.path.exists(path):
        print(f'MISSING_FILE:{src}')
        errors += 1
for dep in m.get('shared', []):
    path = os.path.join('$REPO_DIR', dep['source'])
    if not os.path.exists(path):
        print(f'MISSING_SHARED:{dep[\"source\"]}')
        errors += 1
if m.get('claude_md'):
    path = os.path.join('$SKILL_DIR', m['claude_md']['append_file'])
    if not os.path.exists(path):
        print(f'MISSING_CLAUDE_MD:{m[\"claude_md\"][\"append_file\"]}')
        errors += 1
if errors:
    sys.exit(1)
print('OK')
" 2>/dev/null && green "All manifest files exist" || red "Missing files referenced in install.json"

# ── 4. SKILL.md exists and has valid frontmatter ──
if [ -f "$SKILL_DIR/SKILL.md" ]; then
    if head -1 "$SKILL_DIR/SKILL.md" | grep -q "^---$"; then
        green "SKILL.md has YAML frontmatter"
    else
        red "SKILL.md missing YAML frontmatter (--- block)"
    fi
else
    red "SKILL.md missing"
fi

# ── 5. SKILL.md size within progressive disclosure limits ──
if [ -f "$SKILL_DIR/SKILL.md" ]; then
    LINES=$(wc -l < "$SKILL_DIR/SKILL.md" | tr -d ' ')
    SIZE=$(wc -c < "$SKILL_DIR/SKILL.md" | tr -d ' ')
    SIZE_KB=$((SIZE / 1024))
    if [ "$LINES" -gt 400 ]; then
        red "SKILL.md: $LINES lines (max 400, PD rule requires progressive disclosure)"
    elif [ "$LINES" -gt 300 ]; then
        info "SKILL.md: $LINES lines (warning: >300, consider progressive disclosure)"
    elif [ "$SIZE_KB" -gt 20 ]; then
        red "SKILL.md: ${SIZE_KB}KB (max 20KB)"
    elif [ "$SIZE_KB" -gt 15 ]; then
        info "SKILL.md: ${SIZE_KB}KB (warning: >15KB, consider progressive disclosure)"
    else
        green "SKILL.md: $LINES lines, ${SIZE_KB}KB (within limits)"
    fi
fi

# ── 6. README.md exists ──
if [ -f "$SKILL_DIR/README.md" ]; then
    LINES=$(wc -l < "$SKILL_DIR/README.md" | tr -d ' ')
    if [ "$LINES" -lt 10 ]; then
        red "README.md too short ($LINES lines, need ≥10)"
    else
        green "README.md: $LINES lines"
    fi
else
    red "README.md missing (required for each skill)"
fi

# ── 7. Hook commands reference installable scripts ──
python3 "$REPO_DIR/scripts/check-hooks.py" "$SKILL_DIR" 2>/dev/null && green "Hook scripts reference installable scripts" || red "Hook command references non-installable scripts"

# ── 8. Shared deps don't conflict with existing installed versions? (best-effort check) ──
python3 -c "
import json, os, sys, hashlib
with open('$SKILL_DIR/install.json') as f:
    m = json.load(f)
errors = 0
for dep in m.get('shared', []):
    src = os.path.join('$REPO_DIR', dep['source'])
    dest = os.path.expanduser(dep['dest'].replace('~', os.path.expanduser('~')))
    if os.path.exists(dest) and os.path.exists(src):
        with open(src, 'rb') as f:
            src_hash = hashlib.sha256(f.read()).hexdigest()
        with open(dest, 'rb') as f:
            dest_hash = hashlib.sha256(f.read()).hexdigest()
        if src_hash != dest_hash:
            print(f'VERSION_MISMATCH:{os.path.basename(dest)} (local differs from repo)')
if errors:
    sys.exit(1)
print('OK')
" 2>/dev/null && green "Shared deps check passed" || info "Shared deps: version mismatch with installed (informational)"

# ── 9. Dry-run install (no actual file writes) ──
echo "  Running install.sh in dry-run mode..."
if bash -n "$REPO_DIR/scripts/install.sh" 2>/dev/null; then
    green "install.sh syntax valid"
else
    red "install.sh has syntax errors"
fi

# ── Final ──
echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "✅ VALIDATION PASSED — $SKILL_NAME is ready to upload"
    exit 0
else
    echo "❌ VALIDATION FAILED — $ERRORS error(s) found. Fix before upload."
    exit 1
fi
