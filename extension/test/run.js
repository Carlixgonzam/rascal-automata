const path = require('path');
const { runTests } = require('@vscode/test-electron');

async function main() {
  const root = path.resolve(__dirname, '..');
  await runTests({
    version: process.env.VSCODE_VERSION || 'stable',
    extensionDevelopmentPath: root,
    extensionTestsPath: path.join(__dirname, 'suite.js'),
    launchArgs: [path.resolve(root, '..', 'examples'), '--disable-extensions']
  });
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
