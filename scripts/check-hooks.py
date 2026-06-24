#!/usr/bin/env python3
"""Check that hook commands reference scripts installable from shared/ or skill dir."""
import json, os, sys

skill_dir = sys.argv[1]
repo_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

with open(os.path.join(skill_dir, 'install.json')) as f:
    m = json.load(f)

installable = set()
for dep in m.get('shared', []):
    installable.add(os.path.basename(dep['source']))
for root, dirs, files in os.walk(skill_dir):
    for f in files:
        if f.endswith('.js') or f.endswith('.sh'):
            installable.add(f)

errors = 0
for event, entries in m.get('hooks', {}).items():
    for entry in entries:
        for hook in entry.get('hooks', []):
            cmd = hook.get('command', '')
            words = cmd.replace('"', ' ').replace("'", ' ').split()
            for w in words:
                if w.endswith('.js') or w.endswith('.sh'):
                    basename = os.path.basename(w)
                    if basename not in installable:
                        print(f'  HOOK_SCRIPT_NOT_INSTALLABLE: {basename}')
                        errors += 1

if errors:
    sys.exit(1)
print('OK')
