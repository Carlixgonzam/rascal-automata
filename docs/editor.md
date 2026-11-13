# Editor, viewer and command line

## In VS Code

Opening a `.auto` file starts the language server. The first time this takes
a few seconds, because Rascal loads the grammar; later edits are checked
right away.

**Errors and warnings.** Mistakes are underlined while you type and listed in
the Problems panel. The full list is at the end of this page.

**Results next to the code.** When the file has no errors, the editor shows:

- after each word of a `run` line, `accepted`, `rejected`, or for a Turing
  machine `halted with ...` or `error: ...`;
- after a `check` line, `equal` or `different: ...` with the shortest
  counterexample;
- after a definition, what it produced, for example `DFA, 3 states`.

These disappear while the file has errors, because they would be computed
from a broken file.

**Buttons.** A **Show** button sits above each automaton, expression,
definition, `run` and `show` line. On a `run` line it opens the viewer with
the first word already typed. A `check` that fails gets a **Show
counterexample** button that opens the left-hand side with the counterexample.

**Outline and navigation.** The Outline view lists every named declaration,
and *Go to Definition* on a name jumps to its declaration.

## The viewer

The viewer opens next to the file. It has the name of the automaton, a field
for the word, and three buttons: **Run** runs the whole word, and **◀** and
**▶** go one step back or forward. Pressing Enter in the field is the same as
Run.

Below the buttons:

- **tape**: the cells of the word. For finite and pushdown automata the cells
  already read are grey and the next one has a thick border. For Turing
  machines the tape changes as the machine writes, and the thick border marks
  the head.
- **stack**: only for pushdown automata, with the top on the left.
- the step number and a few lines that say what happened in this step: which
  symbol each active state read and where it went, which λ transitions were
  followed, and at the last step why the word is accepted or rejected.

In the graph, active states are filled in yellow, the transition taken in the
current step is drawn thicker, and λ transitions followed in the step are
dashed. Final states have a double border, and the start state has an
incoming arrow. States produced by `determinize` or `rename` show the set or
old name they stand for under their name.

The viewer works without an internet connection: the graph library is part
of the extension.

## Command line

The checker and the runner also work from a terminal. With a Rascal 0.42 jar
(the one inside the extension works, at
`dist/rascal-lsp/rascal.jar`):

```
java -jar rascal.jar lang::automata::Main examples/course.auto examples/pda.auto
```

run from the root of this repository. It prints the errors and warnings with
`file:line:column`, and then the result of every `run`, `check` and `show`:

```
run Has01 "01": accepted
check NoAA = NoAA2: equal
check Has01 = End0Or1: different: Has01 rejects "0" and End0Or1 accepts it
show Min: DFA, 3 states
  →  q0   {A, B, C}
   * q1   {C, D}
     q2   {C}
  q0 -0-> q1
  ...
```

In the listing of `show`, `→` marks the start state and `*` the final states.

The exit code is 0 when every file has no errors and every `check` says
`equal`, 1 otherwise, and 2 when no file is given. This makes the command
usable for grading: a student file whose `check` lines compare against
reference solutions fails exactly when one of them is wrong.

## Messages

Errors stop the results from being computed; warnings do not.

| Message | What to do |
|---|---|
| `X is not defined` | declare `X`, or fix the spelling. |
| `X is defined further down; move this line below its definition` | names must be declared before use. |
| `X is already defined` | two declarations share a name. |
| `X has no start state; add a line such as: start q` | every automaton needs `start`. |
| `a DFA has exactly one start state; X has 2` | use `nfa`, or keep one start state. |
| `p already goes to q with 0, so this is not a DFA` | two transitions leave `p` with the same symbol. |
| `a DFA cannot have λ transitions; declare it as nfa` | |
| `a DFA reads one symbol per transition, and ab has 2; declare it as nfa` | |
| `the symbol c is not in the alphabet {a, b}` | the symbol is outside the `over` alphabet. |
| `the symbol 2 of this word is not in the alphabet {0, 1}` | a `run` word uses a symbol the automaton does not know. |
| `minimize takes one automaton, not 2` | wrong number of arguments. |
| `minimize works on finite automata, and P is a pushdown automaton` | operations are only defined for finite automata and regular expressions. |
| `check compares finite automata and regular expressions, and T is a Turing machine` | equivalence is undecidable for the other two. |
| `X already has a start state` / `start node` | pushdown automata and Turing machines have one. |
| `the node 0 is defined twice` | two `0:` lines in one machine. |
| `q has no instructions; add a line such as: q: R` | an edge points to a node without a `q:` line. |
| `M is not a Turing machine of this file` | `C[M]` calls an unknown machine. |
| warning: `the state q cannot be reached from the start` | |
| warning: `X has no final states, so it accepts no word` | |
| warning: `this transition is repeated` | |
| warning: `the symbol a appears twice in the alphabet` | |
| warning: `p -a-> q and p -!b-> r can both apply; ...` | both conditions hold when reading `a`. |

A Turing machine can also stop with one of these errors while running:

| Error | Cause |
|---|---|
| `the head fell off the left end of the tape` | `L` on cell 0. |
| `the head went past the last cell of the tape` | more than 16384 cells, usually an `R[x]` that never finds `x`. |
| `the machine ran for more than 262144 steps` | the machine does not stop. |
| `two transitions of p apply reading a: a and !b` | the machine is not deterministic for this symbol. |
| `$s has no value yet` | a variable is used before an edge stores a symbol in it. |
