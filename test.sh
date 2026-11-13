#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
RASCAL_JAR="${RASCAL_JAR:-$(ls -d "$HOME"/.vscode/extensions/usethesource.rascalmpl-*/assets/jars/rascal.jar | sort -V | tail -1)}"
LSP_JAR="${LSP_JAR:-$(dirname "$RASCAL_JAR")/rascal-lsp.jar}"
out=$(printf 'import lang::automata::Tests;\nimport lang::automata::Props;\nimport lang::automata::IdeTests;\nimport lang::automata::GoldTests;\n:test\n:quit\n' \
  | TERM=dumb java -cp "$RASCAL_JAR:$LSP_JAR" org.rascalmpl.shell.RascalShell 2>&1)
echo "$out" | grep -E "tests succeeded|tests failed|failed|FAILED|CallFailed|rror"
if ! echo "$out" | grep -q "tests succeeded" || echo "$out" | grep -q -E "failed|CallFailed|ERROR"; then
  exit 1
fi
java -jar "$RASCAL_JAR" lang::automata::Main examples/course.auto 2>&1 | grep -v -E '^\[INFO\]|^  - |^Job:|^WARNING'
