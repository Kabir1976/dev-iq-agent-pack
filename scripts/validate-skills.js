#!/usr/bin/env node
// Validates frontmatter in all SKILL.md files and agent .md files.
// Run: node scripts/validate-skills.js
// Exit 0 = all valid. Exit 1 = validation failures found.

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SKILLS_DIR = path.join(ROOT, '.github', 'skills');
const AGENTS_DIR = path.join(ROOT, '.github', 'agents');

const SKILL_REQUIRED = ['name', 'description', 'di_signal', 'maturity_required', 'status'];
const SKILL_VALID_SIGNAL = ['INTENT', 'DESIGN', 'QUALITY', 'RISK',
  'INTENT + DESIGN', 'DESIGN + QUALITY', 'INTENT + DESIGN + QUALITY + RISK'];
const SKILL_VALID_STATUS = ['approved', 'draft', 'deprecated'];
const SKILL_VALID_MATURITY = ['early', 'mid', 'higher'];

const AGENT_REQUIRED = ['description']; // Copilot agent spec uses description, not name

let errors = 0;

function parseFrontmatter(content, filePath) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) {
    console.error(`  FAIL  no frontmatter found: ${filePath}`);
    errors++;
    return null;
  }
  const fm = {};
  for (const line of match[1].split('\n')) {
    const colon = line.indexOf(':');
    if (colon === -1) continue;
    const key = line.slice(0, colon).trim();
    const val = line.slice(colon + 1).trim();
    fm[key] = val;
  }
  return fm;
}

function validateSkill(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const fm = parseFrontmatter(content, filePath);
  if (!fm) return;

  const rel = path.relative(ROOT, filePath);
  let fileErrors = 0;

  for (const field of SKILL_REQUIRED) {
    if (!fm[field]) {
      console.error(`  FAIL  missing '${field}': ${rel}`);
      fileErrors++;
    }
  }

  if (fm.maturity_required && !SKILL_VALID_MATURITY.includes(fm.maturity_required)) {
    console.error(`  FAIL  invalid maturity_required '${fm.maturity_required}' (expected: ${SKILL_VALID_MATURITY.join(', ')}): ${rel}`);
    fileErrors++;
  }

  if (fm.status && !SKILL_VALID_STATUS.includes(fm.status)) {
    console.error(`  FAIL  invalid status '${fm.status}' (expected: ${SKILL_VALID_STATUS.join(', ')}): ${rel}`);
    fileErrors++;
  }

  if (fileErrors === 0) {
    console.log(`  OK    ${rel}`);
  } else {
    errors += fileErrors;
  }
}

function validateAgent(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const fm = parseFrontmatter(content, filePath);
  if (!fm) return;

  const rel = path.relative(ROOT, filePath);
  let fileErrors = 0;

  for (const field of AGENT_REQUIRED) {
    if (!fm[field]) {
      console.error(`  FAIL  missing '${field}': ${rel}`);
      fileErrors++;
    }
  }

  if (fileErrors === 0) {
    console.log(`  OK    ${rel}`);
  } else {
    errors += fileErrors;
  }
}

// Validate skills
console.log('\nValidating skills...');
if (fs.existsSync(SKILLS_DIR)) {
  for (const skillName of fs.readdirSync(SKILLS_DIR)) {
    const skillFile = path.join(SKILLS_DIR, skillName, 'SKILL.md');
    if (fs.existsSync(skillFile)) validateSkill(skillFile);
  }
}

// Validate agents
console.log('\nValidating agents...');
if (fs.existsSync(AGENTS_DIR)) {
  for (const agentFile of fs.readdirSync(AGENTS_DIR)) {
    if (agentFile.endsWith('.md')) {
      validateAgent(path.join(AGENTS_DIR, agentFile));
    }
  }
}

console.log(`\n${errors === 0 ? 'All files valid.' : `${errors} error(s) found.`}`);
process.exit(errors > 0 ? 1 : 0);
