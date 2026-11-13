const path = require('path');
const vscode = require('vscode');

const examples = path.resolve(__dirname, '..', '..', 'examples');

async function until(what, read, seconds) {
  for (let i = 0; i < seconds; i++) {
    const value = await read();
    if (value) {
      return value;
    }
    await new Promise(done => setTimeout(done, 1000));
  }
  throw new Error('timed out waiting for ' + what);
}

async function open(name) {
  const document = await vscode.workspace.openTextDocument(path.join(examples, name));
  await vscode.window.showTextDocument(document);
  return document;
}

async function lenses(document) {
  return await vscode.commands.executeCommand('vscode.executeCodeLensProvider', document.uri, 100) || [];
}

async function hints(document) {
  const range = new vscode.Range(0, 0, document.lineCount, 0);
  return await vscode.commands.executeCommand('vscode.executeInlayHintProvider', document.uri, range) || [];
}

exports.run = async function () {
  const errors = await open('errors.auto');
  const found = await until('the diagnostics of errors.auto', () => {
    const list = vscode.languages.getDiagnostics(errors.uri);
    return list.length >= 10 ? list : null;
  }, 600);
  console.log('errors.auto: ' + found.length + ' diagnostics');
  if (!found.some(d => d.message === 'P already goes to Q with 0, so this is not a DFA')) {
    throw new Error('missing the DFA error, got: ' + found.map(d => d.message).join(' | '));
  }

  for (const [name, count] of [['course.auto', 12], ['pda.auto', 4], ['turing.auto', 4], ['grammar.auto', 3]]) {
    const document = await open(name);
    const list = await until('the code lenses of ' + name, async () => {
      const got = await lenses(document);
      return got.length >= count ? got : null;
    }, 300);
    const inline = await until('the inlay hints of ' + name, async () => {
      const got = await hints(document);
      return got.length > 0 ? got : null;
    }, 300);
    console.log(name + ': ' + list.length + ' lenses, ' + inline.length + ' hints: '
      + inline.map(h => typeof h.label === 'string' ? h.label.trim() : h.label.map(p => p.value).join('')).join(', '));
  }
};
