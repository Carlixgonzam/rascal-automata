# Coming from GOLD

GOLD is a general programming language with libraries for automata; you
build an automaton with statements and then call `GAutomataFrame.show`. Here
the file only describes the automata, and the editor does the rest. This page
shows how each kind of GOLD program translates, and lists the places where the
two tools behave differently.

## Finite automata

```
Q := {"A", "B"}
Σ := {'0', '1'}
q := "A"
F := {"B"}
δ := ⟦⟦"A", '0', "A"⟧, ⟦"B", '0', "B"⟧, ⟦"A", '1', "B"⟧, ⟦"B", '1', "A"⟧⟧
A : GDeterministicAutomaton := GDeterministicAutomaton(Q, Σ, q, F, δ)
GAutomataFrame.show(A)
```

becomes

```
dfa A over {0, 1}
  start A
  final B
  A -0-> A
  B -0-> B
  A -1-> B
  B -1-> A

show A
```

`Q` is not needed, and `over` is only needed when some symbol of `Σ` never
appears in a transition.

## Pushdown automata

Each `M.delta(from, to, read).operation(...)` call becomes one line
`from -read, operation(...)-> to`. An empty read string is `λ`, GOLD's
`$skip` is `skip`, and characters such as `-`, `(` or `)` go between single
quotes:

```
M := GPushdownAutomaton(Q, Σ, Γ, q₀, F)
M.delta(1, 2, "").push("$")
M.delta(2, 3, "-").$skip("1")
M.delta(3, 8, "1").pushOn("$", "1")
```

becomes

```
pda M
  start 1
  final 4, 5
  1 -λ, push($)-> 2
  2 -'-', skip(1)-> 3
  3 -1, pushOn(1, $)-> 8
```

The stack alphabet `Γ` is not declared.

Note the arguments of `pushOn`. In GOLD, `pushOn(a, b)` needs `a` on top and
puts `b` above it. The course slides define it the other way around, "put `e`
on top of the stack if the current top is `e'`", and this language follows the
slides. Translating from GOLD therefore swaps the two arguments, as in the
example. `changeTop` and the other operations are the same in both.

Acceptance is the same: final state, empty stack and the whole word read.

## Turing machines

GOLD's Turing machine tool saves machines in text files like this one:

```
ψ = TM
Z = "anbn_simplified"
N(0) = "W[N]"
N(5) = "R"
I = 5@0
E(5,0) = "b"
E(4,4) = "a,x"
E(2,5) = ""
ξ(0)=(52.00,84.00)
```

Each `N(i) = "code"` becomes `i: code`, `I = i@0` becomes `start i`, and each
`E(i,j) = "cond"` becomes `i -cond-> j`, or `i -> j` when the condition is
empty. The layout lines `ξ` are dropped.

```
tm anbn_simplified
  start 5
  0: W[N]
  5: R
  5 -b-> 0
  4 -a,x-> 4
  2 -> 5
```

`tools/gold/convert.py` does this for whole files:

```
python3 tools/gold/convert.py anbn.txt Copy.txt > machines.auto
```

## Differences

**What GOLD has and this does not.** Transducers, graphs and the rest of a
general programming language; drawing and moving automata with the mouse and
saving their layout.

**What this has and GOLD does not.** Errors while typing, results next to each
`run` line, an exact equivalence check with a shortest counterexample, and a
viewer that explains each step.

**Pushdown automata.** GOLD keeps exploring when λ transitions push forever
and runs out of memory. Here the search bounds the height of the stack and the
number of configurations (see [the language](language.md#how-words-are-run)).

**Turing machines.** The semantics are GOLD's: same blank, same starting
position of the head, `R[x]` and `L[x]` move at least once, a node with no
applicable edge stops, two applicable edges are an error, and the limits are
16384 cells and 262144 steps. GOLD only shows the final tape; here the result
also says `accepted` or `rejected` when the tape has `Y` or `N`, which is the
convention of the course examples.

## How the comparison was made

`test/turing-gold.txt` and `test/pda-gold.txt` hold the results of GOLD's own
Java libraries, run without their windows on the examples in
`test/turing.auto` and `test/pda.auto`: 1289 Turing machine runs (final tape,
position of the head or kind of error) and 10461 pushdown automaton runs
(accepted or not). `GoldTests.rsc` runs the same machines on the same words
and fails on the first difference. The programs that produced the files are in
`tools/gold`; `tools/gold/regenerate.sh` runs them again if GOLD is installed.
