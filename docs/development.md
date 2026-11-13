# Development

## Layout

```
pom.xml, META-INF/RASCAL.MF    the Rascal project
src/main/rascal/lang/automata  the language
src/main/rascal/automata-*     the viewer page, its two JavaScript libraries and their licenses
examples/                      example files
test/                          reference files for GoldTests
tools/gold/                    the programs that produced the reference files
extension/                     the VS Code extension
test.sh, repl.sh               scripts for tests and for a Rascal prompt in this project
```

The Rascal modules, in the order the data flows through them:

| Module | Contents |
|---|---|
| `Syntax` | the grammar |
| `Core` | finite automata: acceptance, subset construction, product, minimization, equivalence, Thompson's construction |
| `Stack` | pushdown automata and the search over configurations |
| `Turing` | Turing machines: the instructions, the edges and the step-by-step run |
| `Build` | turns parse trees into the data of `Core`, `Stack` and `Turing`, and evaluates definitions |
| `Check` | errors and warnings |
| `Report` | the texts printed for `run`, `check` and `show` |
| `View` | the data behind the viewer and the small web server that serves it |
| `Ide` | the language server: parser, errors, outline, buttons, inline results |
| `Main` | the command line |
| `Tests`, `Props`, `IdeTests`, `GoldTests` | tests |

The viewer is a plain HTML page (`automata-view.html`). `View` serves it,
together with `automata-cytoscape.js` and `automata-cytoscape-dagre.js`, from
the files next to the modules; Rascal finds them with `getResource`, which
works the same from the source folder and from inside the jar. The page only
draws: every explanation in it is computed in `View`.

## Versions

The project is pinned to Rascal 0.42.2 and rascal-lsp 2.22.5 (in `pom.xml`)
and to version 0.13.5 of `@usethesource/rascal-vscode-dsl-lsp-server` (in
`extension/package.json`), which bundles those two jars. Newer versions need
VS Code 1.100, and this one works from VS Code 1.90. The Rascal code also runs
on Rascal 0.43; `test.sh` can be pointed at either.

When upgrading, keep in mind that the npm package renamed
`VSCodeUriResolverServer` to `VSCodeFileSystemInRascal` in 0.14.

## Building

```
mvn package                       type-checks the Rascal code and builds the jar
cd extension
npm ci
npm run vsix                      builds the jar, the extension and automata-0.1.0.vsix
```

`mvn package` runs Rascal's type checker over every module. The interpreter
used by the REPL and the language server is more lenient, so a module that
works in the REPL can still fail here; run it before committing.

## Working on the language in VS Code

With the Rascal extension installed, open this folder, open any `.rsc` file,
run **Rascal: Create Rascal Terminal**, and type

```
import lang::automata::Ide;
main();
```

`.auto` files now use the language from the source folder. After changing a
module, run `main();` again; the language server does not reload modules on
its own. If VS Code keeps showing old behaviour, run **Developer: Reload
Window** and start again.

## Tests

```
./test.sh
```

runs four groups of Rascal tests and then the command line on
`examples/course.auto`:

- `Tests`: one test per feature or error message, including the automata
  from the course slides that turned out to be wrong.
- `Props`: random tests. Each algorithm is compared, on every word of up to
  five letters, with a separate and much simpler definition (acceptance by
  searching pairs of state and position, regular expressions by their
  recursive definition). They also print random automata as text and parse
  them back. 150 cases per property; set `rounds` higher for a longer run.
- `IdeTests`: evaluates the language server's services the way VS Code does,
  on every example file. This catches name clashes with `util::LanguageServer`
  that only show up inside the editor.
- `GoldTests`: compares the pushdown automata and Turing machines with the
  results of GOLD (see [docs/gold.md](gold.md#how-the-comparison-was-made)).

`test.sh` uses the newest Rascal jar of the installed VS Code extension, or the
one given in `RASCAL_JAR` (with `rascal-lsp.jar` next to it, or in `LSP_JAR`).

```
cd extension
npm test
```

downloads a separate copy of VS Code, opens the example files with only this
extension enabled, and waits for the errors, buttons and inline results of
each one. `VSCODE_VERSION=1.95.0 npm test` picks the VS Code version. When
started from a terminal inside VS Code, run it as
`env -u ELECTRON_RUN_AS_NODE npm test`, or the test copy of VS Code starts in
Node mode and fails.

## Things about Rascal that cost time

- `all(x <- [], ...)` is `false` on an empty generator. Use
  `!any(x <- ..., !condition)`.
- `o`, `node` and `start` are reserved words and cannot be variable or
  function names.
- Importing `List` makes `head(...)` call `List::head` even where the HTML
  constructor `head` was meant.
- A grammar label is also a constructor, so a label such as `zero` clashes
  with an ADT constructor of the same name; qualify it as `Re::zero()`.
- rascal-lsp 2.22.5 has a deprecated function called `lenses`. A service
  function with that name makes `contributions()` fail, but only inside VS
  Code.

## Continuous integration

`.github/workflows/build.yml` runs on every push and pull request: the Rascal
tests, `mvn package`, the extension build, and `npm test` under a virtual
display. The `.vsix` is kept as a build artifact. Pushing a tag such as
`v0.1.0` also attaches it to a draft GitHub release, which stays private until
someone publishes it by hand.

## Publishing

Nothing is published yet. When it is time:

1. Set the version in `extension/package.json` and tag the commit.
2. Create a publisher on the Visual Studio Marketplace with the id used in
   `package.json` (`carlixgonzam` at the moment), and a personal access token.
3. `cd extension && npx vsce publish`.
4. For editors based on Open VSX (VSCodium, Cursor), `npx ovsx publish` with a
   token from open-vsx.org.
