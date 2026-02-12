const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const scriptsDir = path.join(__dirname, 'functions', 'scripts');
const functionsDir = path.join(__dirname, 'functions');

console.log('--- STARTING INGESTION PROCESS ---');

// 1. Install dependencies
console.log('1. Checking dependencies...');
try {
  execSync('npm install axios firebase-admin', { cwd: functionsDir, stdio: 'inherit' });
  console.log('Dependencies installed/verified.');
} catch (e) {
  console.error('Failed to install dependencies:', e.message);
  process.exit(1);
}

// 2. Run Ingest Indian Foods
console.log('\n2. Running Indian Foods Ingestion...');
try {
  const indianScriptPath = path.join(scriptsDir, 'ingest_indian.js');
  execSync(`node "${indianScriptPath}"`, { cwd: scriptsDir, stdio: 'inherit' });
  console.log('Indian Foods Ingestion COMPLETE.');
} catch (e) {
  console.error('Indian Foods Ingestion FAILED:', e.message);
}

// 3. Run Ingest USDA Foods
console.log('\n3. Running USDA Foods Ingestion...');
try {
  const usdaScriptPath = path.join(scriptsDir, 'ingest_usda.js');
  execSync(`node "${usdaScriptPath}"`, { cwd: scriptsDir, stdio: 'inherit' });
  console.log('USDA Foods Ingestion COMPLETE.');
} catch (e) {
  console.error('USDA Foods Ingestion FAILED:', e.message);
}

console.log('\n--- ALL TASKS FINISHED ---');
