#!/usr/bin/env node
const { readFileSync, existsSync } = require('fs');
const path = require('path');
const os = require('os');

const SAFE = 8, WARNING = 10;

let data = '';
process.stdin.on('data', c => data += c);
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data);
    const fp = input.tool_input?.file_path;
    if (!fp) return exit(data);

    const name = path.basename(fp);
    if (name !== 'mcp-servers.json' && name !== '.claude.json') return exit(data);

    // Count MCPs from both sources
    let total = 0;
    const sources = [];

    const claudeJson = path.join(os.homedir(), '.claude.json');
    if (existsSync(claudeJson)) {
      try {
        const c = JSON.parse(readFileSync(claudeJson, 'utf-8'));
        const count = Object.keys(c.mcpServers || {}).length;
        if (count > 0) { total += count; sources.push(`.claude.json:${count}`); }
      } catch {}
    }

    const mcpConfig = path.join(os.homedir(), '.claude', 'mcp-configs', 'mcp-servers.json');
    if (existsSync(mcpConfig)) {
      try {
        const c = JSON.parse(readFileSync(mcpConfig, 'utf-8'));
        const count = Object.keys(c.mcpServers || {}).length;
        if (count > 0) { total += count; sources.push(`mcp-servers.json:${count}`); }
      } catch {}
    }

    if (total >= WARNING) {
      process.stderr.write(
        `\n[GUARD] CRITICAL: ${total} MCP servers detected (${sources.join(', ')}). ` +
        `Threshold: ${SAFE} safe, ${WARNING}+ critical. ` +
        `Incident baseline: 5. Startup will be slow. Remove unused servers: /audit-health\n`
      );
    } else if (total > SAFE) {
      process.stderr.write(
        `\n[GUARD] WARNING: ${total} MCP servers (safe: ${SAFE}). ` +
        `Consider removing unused ones: /audit-health\n`
      );
    }
  } catch {}

  exit(data);
});

function exit(data) {
  process.stdout.write(data);
  process.exit(0);
}
