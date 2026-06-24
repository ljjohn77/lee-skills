---
description: Audit system health — compare against post-optimization baseline (2026-06-24)
---

# /audit-health — System Health Audit

Invoke Skill("audit-health") to run a full system diagnostic. Compares against the 2026-06-24 post-optimization baseline:

- Skills, MCPs, Rules, Hooks, Plugins, claude-mem config, daemon processes, session token stats
- Each metric rated: 🟢 SAFE / 🟡 WARNING / 🔴 CRITICAL
- Actionable cleanup recommendations

Reference: `/Users/lee/Library/Mobile Documents/com~apple~CloudDocs/sys_config/claude_simplify.md`
