## System Health — Anti-Bloat Rules (OVERRIDES ALL)

These rules prevent the system from bloating again. The 2026-06-24 incident (40s startup delay, 7.3M cache tokens, 485 skills, 31 MCP servers) must not repeat.

### Hard Thresholds — DO NOT EXCEED

| Resource | Max | Current (2026-06-24) | Incident Level |
|----------|-----|---------------------|-------------------|
| Skills | 120 | 98 | 485 |
| MCP Servers | 10 | 5 | 31 |
| Rules directory | 150KB | 112KB | 212KB |
| Hooks (total) | 15 | 10 | 21 |
| Plugins (enabled) | 5 | 4 | 6 |
| SessionStart context | 5KB | ~3KB | 10KB (truncated) |

### When User Asks to ADD Anything — MANDATORY CHECK

Before adding any skill, MCP server, plugin, rule, or hook, you MUST:

1. **Check if built-in already covers it.** Claude Code has built-in memory, hooks mechanism, session resume. Prefer built-in over third-party.
2. **Check for duplicates.** Does an existing skill/MCP/rule already provide this?
3. **Check resource cost.** Will this add a daemon process? Background CPU? Memory?
4. **Check thresholds.** Will this push any metric beyond its max? If yes, **warn the user with the specific number** before proceeding.
5. **Challenge the necessity.** Apply Occam's razor — is this truly needed, or is there a simpler path?

### When User Asks to INSTALL a Plugin — MANDATORY WARNING

Before installing any plugin, you MUST warn the user about:
- How many skills/hooks/commands it will add (check plugin directory)
- Whether it spawns background processes (daemons, MCP servers)
- Whether any existing functionality will be duplicated

**Exception:** The user can explicitly override any rule by saying "I understand the risk, proceed anyway." But you MUST still warn first.

### Anti-Sycophancy Clause

If the user asks you to add something that clearly violates the above — for example, installing a 300-skill plugin when skills are already near the threshold — you MUST push back. Do not comply silently. Cite the 2026-06-24 incident as evidence.

## Skill Design — Progressive Disclosure (OVERRIDES ALL)

When writing or modifying ANY SKILL.md file, you MUST follow the progressive disclosure pattern defined in `rules/common/progressive-disclosure.md`. This is a hard constraint — hooks enforce it at write time, and `/audit-health` verifies compliance post-hoc.

**Hard thresholds (enforced by guard-skill-bloat.js hook):**
- SKILL.md <15KB and <300 lines
- BLOCKED: >20KB or >400 lines — refuse to write, require refactoring
- Multi-mode skills MUST use pipeline files (`skills/pipeline-*.md`) for procedures >30 lines

**Before writing any new SKILL.md, answer:**
1. Does this need multiple modes? → Mode Selector + pipeline files
2. Is any procedure >30 lines? → extract to `pipeline-*.md`
3. Will this exceed 300 lines? → refactor before writing
4. Does an existing skill already cover this? → add a mode instead

**Why (2026-06-24):** Three skills (/prompts, /leemood, /leeconcept) were reduced from 90KB combined to 34KB (62% reduction) by applying this pattern. Monolithic SKILL.md files waste context on every invocation.

## Legend
