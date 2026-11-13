#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")"
GOLD_TM="${GOLD_TM:-$HOME/Desktop/gold-tm}"
GOLD_LIB="${GOLD_LIB:-$HOME/Desktop/GOLD/gold-mac/eclipseGOLD_KEPLER/plugins/org.gold.dsl.lib_3.0.0}"
TEST=../../test

TM_CP="$GOLD_TM/gold-tm.jar:$(ls "$GOLD_TM"/lib/*/*.jar | tr '\n' ':')"
python3 convert.py "$GOLD_TM"/examples/{anbn_simplified,anbncn_simplified,anbn,anbncn,Copy,ShiftRight,TestCheck,TestLoop}.txt > "$TEST/turing.auto"
java -Djava.awt.headless=true -cp "$TM_CP" Oracle.java "$GOLD_TM/examples" \
  anbn_simplified ab 6 anbncn_simplified abc 5 anbn abc 5 anbncn abc 5 Copy ab 4 ShiftRight ab 4 TestCheck ab 2 TestLoop a 0 \
  > "$TEST/turing-gold.txt"

PDA_CP="$GOLD_LIB/lib/gold/gold.jar:$(ls "$GOLD_LIB"/lib/*/*.jar | grep -v gold.jar | tr '\n' ':')"
: > "$TEST/pda-gold.txt"
for spec in "anbn ab 8" "wff pNA() 5" "subtraction 10-= 6" "pushOn2 abcd 4" "change1 abc 4" "skip1 abc 4"; do
  set -- $spec
  java -Djava.awt.headless=true -cp "$PDA_CP" Pda.java "pda/$1.pda" "$2" "$3" | sed "s/^/$1 /" >> "$TEST/pda-gold.txt"
done
wc -l "$TEST/turing-gold.txt" "$TEST/pda-gold.txt"
