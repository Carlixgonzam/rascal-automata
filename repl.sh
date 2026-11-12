#!/usr/bin/env bash
RASCAL_JAR="${RASCAL_JAR:-$(ls -d "$HOME"/.vscode/extensions/usethesource.rascalmpl-*/assets/jars/rascal.jar | sort -V | tail -1)}"
cd "$(dirname "$0")" && TERM=dumb java -jar "$RASCAL_JAR" 2>&1 | sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g'
