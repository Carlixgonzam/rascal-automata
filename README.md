# rascal-automata

A VS Code extension for writing finite automata, regular expressions,
pushdown automata, Turing machines and grammars in `.auto` files. Mistakes
are marked while you type, each test word shows its result, and a window next
to the editor runs a word one step at a time.

It is meant as a replacement for GOLD in a programming languages course, and
it is written in [Rascal](https://www.rascal-mpl.org).

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

The language is described in [docs/language.md](docs/language.md), and the
`examples` folder has one file per kind of automaton.

## Trying it

Install the `.vsix` file with **Extensions: Install from VSIX...** in VS Code
1.90 or newer, open a folder, and create a file ending in `.auto`. The
extension needs Java 11 or newer and downloads it the first time if it is
missing.

To build the `.vsix`:

```
cd extension
npm ci
npm run vsix
```

`./test.sh` runs the tests of the language, and `npm test` inside
`extension` runs the extension in a separate copy of VS Code.

## Credits

Built with Rascal and its language server library; graphs are drawn with
Cytoscape.js. The Turing machine notation and the examples in
`examples/turing.auto` come from GOLD, by Alejandro Sotelo at Universidad de
los Andes, and the pushdown automata follow the course slides.

## License

BSD 2-Clause, see [LICENSE](LICENSE).
