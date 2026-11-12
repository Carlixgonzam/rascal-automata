import * as path from 'path';
import * as vscode from 'vscode';
import { LanguageParameter, ParameterizedLanguageServer, VSCodeUriResolverServer } from '@usethesource/rascal-vscode-dsl-lsp-server';

function toLoc(file: string): string {
    return '|' + vscode.Uri.file(file).toString().replace('file://', 'jar+file://') + '!/|';
}

export function activate(context: vscode.ExtensionContext) {
    const jar = context.asAbsolutePath(path.join('assets', 'jars', 'automata.jar'));
    const language: LanguageParameter = {
        pathConfig: 'pathConfig(srcs=[' + toLoc(jar) + '], libs=[|mvn://org.rascalmpl--rascal--0.42.2/org/rascalmpl/library|, |mvn://org.rascalmpl--rascal-lsp--2.22.5|])',
        name: 'Automata',
        extensions: ['auto'],
        mainModule: 'lang::automata::Ide',
        mainFunction: 'contributions'
    };
    const logger = vscode.window.createOutputChannel('Automata', { log: true });
    const files = new VSCodeUriResolverServer(false, logger);
    const jars = context.asAbsolutePath(path.join('dist', 'rascal-lsp'));
    const server = new ParameterizedLanguageServer(context, files, jars, true, 'automata', 'Automata', language);
    context.subscriptions.push(server, logger);
}

export function deactivate() {
}
