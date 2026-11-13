# rascal-automata

A small language for finite automata, regular expressions, pushdown automata
and Turing machines, together with a VS Code extension. You write the
automata in a `.auto` file; the editor marks mistakes while you type, prints
whether each test word is accepted, and opens a window where a word can be
run one step at a time.

It started as a replacement for GOLD in a programming languages course. GOLD
ran inside an Eclipse release from 2013 that is hard to install today, and the
course already teaches Rascal, so the language and its tools are written in
Rascal.

```
nfa End0Or1
  start A
  final D
  A -> B, C
  B -1-> D
  C -0,1-> C
  C -0-> D

regex Ends0 = (0|1)*0 | 1

Min = minimize(determinize(End0Or1))

run End0Or1 "1", "10", "11"
check End0Or1 = Ends0
show Min
```

In the editor, `run` prints `accepted` or `rejected` next to each word, and
`check` prints `equal` or the shortest word on which the two sides disagree.
The **Show** button above each definition opens the automaton next to the
file.

## What it covers

- DFAs and NFAs, with λ transitions and transitions labelled by whole words.
- Regular expressions, translated to NFAs with Thompson's construction.
- Determinization, minimization, complement, union, intersection, difference
  and renaming of states.
- An exact equivalence check that returns the shortest counterexample.
- Pushdown automata with the stack operations of the course: push, pop,
  ignore, skip, changeTop and pushOn.
- Turing machines written as composed machines, in the notation of GOLD's
  Turing machine tool.
- A viewer that shows the tape, the stack and the active states for every
  step, and explains what each state does with the symbol it reads.

## Installing

The extension is not on the Marketplace yet. To try it, build the `.vsix`
file (see [docs/development.md](docs/development.md)) and install it from VS
Code with **Extensions: Install from VSIX...**.

It needs VS Code 1.90 or newer. The language server runs on Java 11 or newer;
if no Java is installed, the extension downloads a JDK the first time it
starts, so that first start needs an internet connection. After that it works
offline, including the viewer.

## Documentation

- [The language](docs/language.md): every construct, with examples.
- [Editor, viewer and command line](docs/editor.md): what the extension does
  and what each message means.
- [Coming from GOLD](docs/gold.md): how GOLD programs translate, and where the
  two tools differ.
- [Development](docs/development.md): layout of the code, building, tests and
  the pinned versions.

The `examples` folder has three files to start from: `course.auto` (finite
automata and regular expressions), `pda.auto` and `turing.auto`.

## Command line

The same checks run without VS Code:

```
java -jar rascal.jar lang::automata::Main examples/course.auto
```

where `rascal.jar` is a Rascal 0.42 jar. See [docs/editor.md](docs/editor.md#command-line).

## Credits

The language is built with [Rascal](https://www.rascal-mpl.org) and its
[language server library](https://github.com/usethesource/rascal-language-servers);
the viewer draws graphs with [Cytoscape.js](https://js.cytoscape.org).

GOLD, by Alejandro Sotelo at Universidad de los Andes, is the tool this one
replaces. The Turing machine notation follows GOLD's Turing machine tool, and
the files in `test/turing.auto` and `examples/turing.auto` are converted from
its examples. The pushdown automata follow the definitions used in the course
slides.

## License

BSD 2-Clause, see [LICENSE](LICENSE). The extension also ships Rascal,
rascal-lsp and Cytoscape.js under their own licenses, listed in
[extension/THIRD-PARTY-NOTICES.txt](extension/THIRD-PARTY-NOTICES.txt).
