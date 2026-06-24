# Progressive Disclosure — Mandatory Skill Design Rule

**Priority:** HIGH. This rule overrides convenience. All SKILL.md files MUST follow this pattern.

## Core Principle

**SKILL.md loads on EVERY skill invocation. Pipeline files load only when their mode triggers.** A 50KB monolithic SKILL.md wastes context on every call. A 10KB SKILL.md + 40KB of on-demand pipeline files saves ~80% context per invocation.

## Hard Thresholds (ENFORCED BY HOOKS)

| Metric | Safe | Warning | BLOCKED |
|--------|------|---------|---------|
| SKILL.md size | <15KB | 15-20KB | >20KB |
| SKILL.md lines | <300 | 300-400 | >400 |
| Pipeline file size | <10KB each | — | — |
| Total skill directory | <50KB | — | — |

A hook fires on every `Write` to `skills/*/SKILL.md`. If the file exceeds WARNING threshold, Claude warns. If it exceeds BLOCKED threshold, Claude MUST refuse and require progressive disclosure refactoring.

## What Stays in SKILL.md vs. Goes to Pipeline Files

| Stays in SKILL.md (<300 lines) | Goes to `skills/pipeline-*.md` |
|--------------------------------|-------------------------------|
| Frontmatter (name, description, triggers) | Step-by-step procedures per mode |
| Mode selector table (condition → mode → action) | Detailed input format docs |
| One-line mode descriptions with file references | Multi-step execution flows |
| Core rules enforced across all modes | Platform-specific reference tables |
| Common pitfalls (1-2 lines each) | Sub-agent prompt templates |
| Load-on-demand map (trigger → `pipeline-*.md`) | Examples and edge cases |

## Implementation Pattern

### 1. Mode Selector Table (in SKILL.md)

Every multi-mode skill MUST have this table immediately after the frontmatter:

```markdown
## Mode Selector

| Condition | Mode | Action |
|-----------|------|--------|
| user says "X" | `x-mode` | Load pipeline-x.md, execute procedure |
| user says "Y" | `y-mode` | Load pipeline-y.md, execute procedure |
| default | `default-mode` | [inline, or load pipeline-default.md] |
```

### 2. Load-on-Demand Map (in SKILL.md)

```markdown
## Pipeline Files

| Trigger | File | Description |
|---------|------|-------------|
| x-mode | [pipeline-x.md](pipeline-x.md) | Full procedure for X |
| y-mode | [pipeline-y.md](pipeline-y.md) | Full procedure for Y |
```

### 3. Pipeline File Template

Each `skills/pipeline-<name>.md`:

```markdown
<!-- trigger: [condition from Mode Selector] -->
<!-- mode: [mode name] -->
<!-- parent: [skill name] -->

# [Mode Name] — [Skill Name]

[Full step-by-step procedure, examples, edge cases]
```

### 4. Single-Mode Skills

If the skill genuinely only has ONE mode with no branching, the inline threshold is relaxed to 25KB/500 lines. But if it grows beyond that, consider whether the skill should be split into sub-skills instead of pipeline files.

## New Skill Checklist (MANDATORY)

Before writing any new SKILL.md, answer:

1. **Does this skill need multiple modes?** If yes → Mode Selector + pipeline files.
2. **Is any procedure >30 lines?** If yes → extract to pipeline file.
3. **Will this SKILL.md exceed 300 lines?** If yes → refactor before writing.
4. **Does an existing skill already cover this?** If yes → add a mode to that skill instead of creating a new one.

## Case Study: 2026-06-24 Optimization

| Skill | Before | After | Reduction |
|-------|--------|-------|-----------|
| /prompts | 53KB / 878 lines | 14KB / 224 lines | 73% |
| /leemood | 21KB / 402 lines | 12KB / 212 lines | 45% |
| /leeconcept | 13KB / 237 lines | 5.4KB / 133 lines | 59% |

Combined: 90KB → 34KB (62% reduction). Pipeline files (37KB total) load on-demand — only when their specific mode triggers.

## Anti-Patterns (DO NOT DO)

- **Monolithic SKILL.md:** All modes inlined → bloats every invocation
- **Fake progressive disclosure:** SKILL.md still contains full procedures, pipeline files are duplicates
- **Over-fragmentation:** 50 pipeline files of 200 bytes each → worse than one moderate SKILL.md
- **Missing load map:** Pipeline files exist but SKILL.md doesn't reference them → dead files
