---
name: audit-health
description: System health audit for Claude Code — checks skills, MCPs, rules, hooks, plugins against post-optimization baseline. Use weekly or when startup feels slow.
type: global
---

# Audit Health — System Performance Monitor

Audit Claude Code system health. Run the diagnostic checks below automatically, compare against the 2026-06-24 post-optimization baseline, and present a clear HEALTHY / WARNING / CRITICAL report.

## When to Use

- User types `/audit-health`
- User says "check system health", "audit performance", "is my Claude bloated?"
- New session startup feels slow
- After installing any plugin, MCP server, or batch of skills

## How It Works

Run ALL of the following checks in a single Bash call. Then interpret the results against the thresholds table. Present the user with a health score and specific recommendations.

### Step 1: Run Diagnostics

Execute this exact script:

```bash
echo "=== SYSTEM HEALTH AUDIT ==="
echo "Baseline: 2026-06-24 post-optimization"
echo ""

# --- Skills ---
USER_SKILLS=$(find ~/.claude/skills -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
echo "SKILLS: $USER_SKILLS (baseline: 77, safe: <100, critical: >120)"

# --- MCP Servers ---
MCP_TOTAL=0
if [ -f "$HOME/.claude.json" ]; then
    MCP_CLAUDE=$(python3 -c "import json; c=json.load(open('$HOME/.claude.json')); print(len(c.get('mcpServers',{})))" 2>/dev/null)
    MCP_TOTAL=$((MCP_TOTAL + ${MCP_CLAUDE:-0}))
fi
if [ -f "$HOME/.claude/mcp-configs/mcp-servers.json" ]; then
    MCP_CONF=$(python3 -c "import json; c=json.load(open('$HOME/.claude/mcp-configs/mcp-servers.json')); print(len(c.get('mcpServers',{})))" 2>/dev/null)
    MCP_TOTAL=$((MCP_TOTAL + ${MCP_CONF:-0}))
fi
echo "MCP: $MCP_TOTAL (baseline: 5, safe: <8, critical: >10)"

# --- Rules ---
RULES_SIZE=$(du -sk ~/.claude/rules/ 2>/dev/null | awk '{print $1}')
echo "RULES: ${RULES_SIZE}K (baseline: 112K, safe: <120K, critical: >150K)"

# --- Hooks ---
python3 -c "
import json
total = 0
try:
    h = json.load(open('$HOME/.claude/hooks/hooks.json'))
    for v in h.get('hooks',{}).values(): total += len(v)
except: pass
try:
    s = json.load(open('$HOME/.claude/settings.json'))
    for v in s.get('hooks',{}).values(): total += len(v)
except: pass
print(f'HOOKS: {total} (baseline: 10, safe: <12, critical: >15)')
"

# --- Plugins ---
python3 -c "
import json
s = json.load(open('$HOME/.claude/settings.json'))
enabled = [k for k,v in s.get('enabledPlugins',{}).items() if v]
disabled = [k for k,v in s.get('enabledPlugins',{}).items() if not v]
print(f'PLUGINS_ENABLED: {len(enabled)} — {\", \".join(enabled)}')
print(f'PLUGINS_DISABLED: {\", \".join(disabled)}' if disabled else 'PLUGINS_DISABLED: none')
print(f'(baseline: 4 enabled, safe: <5, critical: >5)')
"

# --- claude-mem ---
python3 -c "
import json
s = json.load(open('$HOME/.claude-mem/settings.json'))
obs = s.get('CLAUDE_MEM_CONTEXT_OBSERVATIONS', '?')
chroma = s.get('CLAUDE_MEM_CHROMA_ENABLED', '?')
print(f'CLAUDE_MEM_OBS: {obs} (baseline: 15, safe: <25)')
print(f'CLAUDE_MEM_CHROMA: {chroma} (baseline: false, safe: false)')
"

# --- Session Stats (from last session) ---
python3 -c "
import json
c = json.load(open('$HOME/.claude.json'))
cache = c.get('lastTotalCacheReadInputTokens', 0)
inp = c.get('lastTotalInputTokens', 0)
out = c.get('lastTotalOutputTokens', 0)
cost = c.get('lastTotalCostUSD', 0)
model = c.get('lastModelCalled', '?')
print(f'LAST_CACHE_TOKENS: {cache:,} (incident: 7,332,272, safe: <1,000,000)')
print(f'LAST_INPUT: {inp:,}')
print(f'LAST_OUTPUT: {out:,}')
print(f'LAST_MODEL: {model}')
print(f'LAST_COST: \${cost:.2f}')
"

# --- Process Check ---
PROC_COUNT=$(ps aux | grep -E "worker-service.cjs|chroma-mcp" | grep -v grep | wc -l | tr -d ' ')
echo "DAEMONS: $PROC_COUNT (baseline: 1, safe: <2, critical: >3)"

# --- Progressive Disclosure Compliance ---
echo ""
echo "=== PROGRESSIVE DISCLOSURE ==="
python3 -c "
import os

skills_dir = os.path.expanduser('~/.claude/skills')
violations = []
total_skills = 0
total_size = 0

# Match find -maxdepth 2 to avoid recursing into plugin skill trees
def scan_skills(path, depth=0):
    global total_skills, total_size
    if depth > 1 or not os.path.isdir(path):
        return
    for entry in sorted(os.listdir(path)):
        entry_path = os.path.join(path, entry)
        if not os.path.isdir(entry_path):
            continue
        fp = os.path.join(entry_path, 'SKILL.md')
        if os.path.isfile(fp):
            total_skills += 1
            try:
                size = os.path.getsize(fp)
                lines = len(open(fp).readlines())
                total_size += size
                name = entry if depth == 0 else os.path.basename(path) + '/' + entry
                issues = []
                if size > 20000: issues.append(f'SIZE:{size/1024:.0f}KB')
                elif size > 15000: issues.append(f'SIZE_WARN:{size/1024:.0f}KB')
                if lines > 400: issues.append(f'LINES:{lines}')
                elif lines > 300: issues.append(f'LINES_WARN:{lines}')
                content = open(fp).read()
                # Progressive disclosure: find supporting .md files up to 1 level deep
                # (covers skills/pipeline-*.md, intake/*.md, memory/mistakes/*.md)
                other_md = []
                for root, dirs, files in os.walk(entry_path):
                    rel = os.path.relpath(root, entry_path)
                    depth_from_entry = rel.count(os.sep) if rel != '.' else 0
                    if depth_from_entry > 1:
                        dirs.clear()
                        continue
                    for f in files:
                        if f.endswith('.md') and not (depth_from_entry == 0 and f == 'SKILL.md'):
                            other_md.append(f)
                has_progressive = len(other_md) > 0
                looks_multimode = ('mode selector' in content.lower() or 
                                  'mode table' in content.lower() or
                                  '| mode' in content.lower())
                if looks_multimode and not has_progressive and lines > 100:
                    issues.append('NO_PIPELINE:multi-mode skill without extracted pipeline files')
                if issues:
                    violations.append({'skill': name, 'issues': issues, 'size_kb': size/1024, 'lines': lines})
            except:
                pass
        else:
            scan_skills(entry_path, depth + 1)

scan_skills(skills_dir)

# Also scan current project skills (skip if same as global)
cwd = os.getcwd()
project_skills_dir = os.path.join(cwd, '.claude', 'skills')
project_skills_real = os.path.realpath(project_skills_dir) if os.path.isdir(project_skills_dir) else None
global_skills_real = os.path.realpath(skills_dir)
if project_skills_real and project_skills_real != global_skills_real:
    print(f'PD_PROJECT: {project_skills_dir}')
    project_violations_before = len(violations)
    scan_skills(project_skills_dir)
    project_violations = len(violations) - project_violations_before
    print(f'PD_PROJECT_VIOLATIONS: {project_violations}')
else:
    print('PD_PROJECT: (none or same as global)')

print(f'PD_SKILLS: {total_skills} skills, {total_size/1024:.0f}KB total')
print(f'PD_VIOLATIONS: {len(violations)}')
for v in violations:
    print(f'  PD_ISSUE: {v[\"skill\"]} ({v[\"size_kb\"]:.0f}KB, {v[\"lines\"]} lines) — {\", \".join(v[\"issues\"])}')
if not violations:
    print('  All skills comply with progressive disclosure thresholds.')
"

echo ""
echo "=== AUDIT COMPLETE ==="
```

### Step 2: Rate Each Metric

Compare each metric against the thresholds table:

| Metric | Safe (<) | Warning (≥) | Critical (≥) |
|--------|----------|-------------|--------------|
| Skills | 100 | 100 | 120 |
| MCPs | 8 | 8 | 10 |
| Rules | 120K | 120K | 150K |
| Hooks | 12 | 12 | 15 |
| Plugins | 5 | 5 | 6 |
| Cache tokens | 1M | 1M | 3M |
| Daemons | 2 | 2 | 3 |
| claude-mem obs | 25 | 25 | 40 |
| Chroma | false | — | true |
| SKILL.md >15KB | 0 | 1+ | 3+ |
| SKILL.md >300 lines | 0 | 1+ | 3+ |
| No pipeline files | 0 | 1+ | 3+ |

### Step 3: Present Health Report

Format the output as:

```
## System Health Report

**Status: 🟢 HEALTHY / 🟡 WARNING / 🔴 CRITICAL**

### Metrics
| Metric | Value | Status | Trend |
|--------|-------|--------|-------|
| Skills | 77 | 🟢 | — |
| MCPs | 5 | 🟢 | — |
| ... | ... | ... | ... |

### Warnings (if any)
- [Specific warning with value and threshold]

### Recommendations (if any)
- [Actionable advice]
```

### Step 4: Take Action If Needed

If any metric is at WARNING or CRITICAL level:
1. Explain what caused the drift from baseline
2. Propose a specific cleanup action
3. Ask user for confirmation before executing

## Baseline Reference (2026-06-24)

Post-optimization state after three-phase cleanup:
- Skills: 77 user + 21 plugin = ~98 total
- MCP: 5 (claude-mem, blender, chrome-devtools, tavily, stitch)
- Rules: 112KB (common, cpp, python, typescript)
- Hooks: 10 total (1 DIY format + 9 GSD)
- Plugins: 4 enabled (claude-mem, claude-hud, minimax, claude-code-setup)
- ECC: DISABLED
- claude-mem: observations=15, Chroma=false
- Daemons: 1 (bun worker, ~78MB)
- Last cache tokens: <500K
