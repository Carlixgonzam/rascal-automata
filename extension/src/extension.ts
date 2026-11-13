import * as path from 'path';
import * as vscode from 'vscode';
import { LanguageParameter, ParameterizedLanguageServer, VSCodeUriResolverServer } from '@usethesource/rascal-vscode-dsl-lsp-server';

function loc(file: string, inside?: string): string {
    const uri = vscode.Uri.file(file).toString();
    return inside === undefined ? '|' + uri + '|' : '|' + uri.replace('file://', 'jar+file://') + '!/' + inside + '|';
}

export function activate(context: vscode.ExtensionContext) {
    const jars = context.asAbsolutePath(path.join('dist', 'rascal-lsp'));
    const automata = context.asAbsolutePath(path.join('assets', 'jars', 'automata.jar'));
    const rascal = path.join(jars, 'rascal.jar');
    const lsp = path.join(jars, 'rascal-lsp.jar');
    const language: LanguageParameter = {
        pathConfig: 'pathConfig(srcs=[' + [loc(automata, ''), loc(lsp, 'library'), '|std:///|'].join(', ') + '], '
            + 'libs=[' + [loc(rascal), loc(lsp)].join(', ') + '])',
        name: 'Automata',
        extensions: ['auto'],
        mainModule: 'lang::automata::Ide',
        mainFunction: 'contributions'
    };
    const logger = vscode.window.createOutputChannel('Automata', { log: true });
    const files = new VSCodeUriResolverServer(false, logger);
    const server = new ParameterizedLanguageServer(context, files, jars, true, 'automata', 'Automata', language);
    context.subscriptions.push(server, logger);
}

export function deactivate() {
}
