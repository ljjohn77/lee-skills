#!/usr/bin/env node
const { readFileSync, existsSync } = require('fs');
const path = require('path');

const WARN_KB = 15, BLOCK_KB = 20;
const WARN_LINES = 300, BLOCK_LINES = 400;

let data = '';
process.stdin.on('data', c => data += c);
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data);
    const fp = input.tool_input?.file_path;
    if (!fp) return exit(data);

    // Only fire for SKILL.md files
    if (path.basename(fp) !== 'SKILL.md') return exit(data);
    if (!fp.includes('/skills/') && !fp.includes('\\skills\\')) return exit(data);

    if (!existsSync(fp)) return exit(data);

    const content = readFileSync(fp, 'utf-8');
    const lines = content.split('\n').length;
    const kb = Buffer.byteLength(content, 'utf-8') / 1024;

    // Check progressive disclosure compliance
    const hasModeSelector = /mode\s*selector|mode\s*table|mode\s*router/i.test(content);
    const hasPipelineRef = /pipeline-\w+\.md/i.test(content);
    const hasLoadMap = /load.*map|pipeline files/i.test(content);
    const isMultiMode = hasModeSelector || hasPipelineRef;

    const checks = [];
    if (kb >= BLOCK_KB) checks.push(`BLOCKED: ${kb.toFixed(1)}KB (max ${BLOCK_KB}KB)`);
    else if (kb >= WARN_KB) checks.push(`WARNING: ${kb.toFixed(1)}KB (safe: ${WARN_KB}KB)`);

    if (lines >= BLOCK_LINES) checks.push(`BLOCKED: ${lines} lines (max ${BLOCK_LINES})`);
    else if (lines >= WARN_LINES) checks.push(`WARNING: ${lines} lines (safe: ${WARN_LINES})`);

    // If the skill looks multi-mode but lacks pipeline files
    if (isMultiMode && !hasPipelineRef && lines > 100) {
      checks.push('WARNING: Multi-mode skill detected but no pipeline-*.md references found. Apply progressive disclosure.');
    }

    if (checks.length > 0) {
      const hasBlocked = checks.some(c => c.startsWith('BLOCKED'));
      const prefix = hasBlocked ? '[GUARD] BLOCKED' : '[GUARD]';

      process.stderr.write(`\n${prefix}: ${path.basename(path.dirname(fp))}/SKILL.md\n`);
      checks.forEach(c => process.stderr.write(`  - ${c}\n`));
      process.stderr.write(`  Rule: ~/.claude/rules/common/progressive-disclosure.md\n`);

      if (hasBlocked) {
        process.stderr.write(`  ACTION: Refactor before proceeding. Extract procedures to pipeline-*.md files.\n`);
      } else {
        process.stderr.write(`  SUGGESTION: Consider progressive disclosure refactoring.\n`);
      }
    }
  } catch {}

  exit(data);
});

function exit(data) {
  process.stdout.write(data);
  process.exit(0);
}
