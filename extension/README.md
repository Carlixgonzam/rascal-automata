# Automata

Write finite automata, regular expressions, pushdown automata and Turing
machines in `.auto` files. Mistakes are underlined as you type, every test
word shows whether it is accepted, and a viewer next to the editor runs a word
one step at a time.

```
nfa End0Or1
  start A
  final D
  A -> B, C
  B -1-> D
  C -0,1-> C
  C -0-> D

regex Ends0 = (0|1)*0 | 1

run End0Or1 "1", "10", "11"
check End0Or1 = Ends0
```

## Features

- DFAs, NFAs with λ transitions, and regular expressions.
- Determinization, minimization, complement, union, intersection and
  difference.
- `check A = B` decides equivalence exactly and gives the shortest word on
  which `A` and `B` differ.
- Pushdown automata with push, pop, ignore, skip, changeTop and pushOn.
- Turing machines in the composed-machine notation of GOLD.
- Grammars, with the leftmost derivation and its tree shown step by step.
- A step-by-step viewer with the tape, the stack and the active states, which
  works offline.

## Requirements

VS Code 1.90 or newer. The extension runs on Java 11 or newer and downloads a
JDK on first start if none is installed.

## Documentation

The language reference, the list of messages and notes for GOLD users are in
the [repository](https://github.com/Carlixgonzam/rascal-automata).

This extension is built with [Rascal](https://www.rascal-mpl.org) and its
language server library.
