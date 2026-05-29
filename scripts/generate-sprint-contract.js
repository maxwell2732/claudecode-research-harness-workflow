#!/usr/bin/env node

const { runHarnessSubcommand } = require('./lib/run-harness-subcommand');
const { spawnSync } = require('child_process');
const path = require('path');

const args = process.argv.slice(2);
let planName = '';
const forwarded = [];

for (let i = 0; i < args.length; i += 1) {
  if (args[i] === '--plan') {
    if (!args[i + 1] || args[i + 1].startsWith('--')) {
      process.stderr.write('--plan requires a plan name\n');
      process.exit(2);
    }
    planName = args[i + 1] || '';
    i += 1;
    continue;
  }
  forwarded.push(args[i]);
}

if (planName) {
  if (forwarded.length < 1 || forwarded.length > 2) {
    process.stderr.write('Usage with --plan: generate-sprint-contract.js --plan NAME <task-id> [output-file]\n');
    process.exit(2);
  }

  const helper = path.join(__dirname, 'plan-registry.sh');
  const result = spawnSync('bash', [helper, 'path', planName], {
    cwd: process.cwd(),
    env: process.env,
    encoding: 'utf8',
  });

  if (result.status !== 0) {
    process.stderr.write(result.stderr || `unknown or unsafe plan: ${planName}\n`);
    process.exit(result.status || 1);
  }

  const plansPath = result.stdout.trim();
  if (!plansPath) {
    process.stderr.write(`empty plan path for plan: ${planName}\n`);
    process.exit(1);
  }

  forwarded.splice(1, 0, plansPath);
}

runHarnessSubcommand(['sprint-contract', ...forwarded]);
