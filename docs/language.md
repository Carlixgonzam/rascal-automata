# The language

A `.auto` file is a list of declarations. Each one ends where the next one
starts. Comments start with `//`. A name must be declared before it is used.

## Finite automata

```
dfa Has01
  start a
  final b
  a -1-> a
  a -0-> c
  c -0-> c
  c -1-> b
  b -0,1-> b
```

| Line | Meaning |
|---|---|
| `start a` | start state (an `nfa` may list several) |
| `final b, c` | final states |
| `p -0-> q` | reading `0` in `p` goes to `q` |
| `p -0,1-> q` | several symbols in one line |
| `p -0-> q, r` | several targets (`nfa` only) |
| `p -> q` | λ transition (`nfa` only) |
| `p -ab-> q` | reads the word `ab` (`nfa` only) |

The alphabet is the set of symbols used. `dfa Zeros over {0, 1}` fixes it.
A missing transition in a DFA rejects the word.

## Regular expressions

```
regex NoAA = a(b|ba)* | (b|ba)*
```

The expression runs to the end of the line. It uses `|`, concatenation, `*`,
`+`, `?`, parentheses, `λ` for the empty word and `∅` for the empty
language.

## Operations

```
Dfa = rename(determinize(End0Or1))
Min = minimize(Dfa)
```

`determinize`, `minimize`, `complement`, `union(A, B)`, `intersection(A, B)`,
`difference(A, B)` and `rename` work on finite automata and regular
expressions.

## Commands

```
run Has01 λ, "01", "1101"
show Min
check NoAA = NoAA2
```

`run` runs words on any automaton, machine or grammar. `show` opens the
viewer. `check` decides whether two finite automata or regular expressions
accept the same language; if they do not, it gives the shortest word on which
they differ.

## Pushdown automata

```
pda AnBn
  start A
  final B
  A -a, push(a)-> A
  A -λ, ignore-> B
  B -b, pop(a)-> B
```

A transition is `p -σ, op-> q` with `σ` a symbol or `λ`. A word is accepted
when it is read completely and the automaton ends in a final state with an
empty stack.

| Operation | Needs on top | Effect |
|---|---|---|
| `push(e)` | anything | puts `e` on top |
| `pop(e)` | `e` | removes `e` |
| `ignore` | anything | nothing |
| `skip(e)` | `e` | nothing |
| `changeTop(e, f)` | `e` | replaces `e` by `f` |
| `pushOn(e, f)` | `f` | puts `e` on top of `f` |

`pushOn` follows the course slides; GOLD uses the opposite order of
arguments. Characters other than letters, digits and `$ # + * / = . ;` go
between single quotes: `E -'(', push(P)-> E`.

## Turing machines

The notation of GOLD's Turing machine tool:

```
tm anbn_simplified
  start 5
  0: W[N]
  1: W[Y]
  2: W[x]L[#]
  3: W[x]
  4: R
  5: R
  2 -> 5
  3 -> 4
  4 -#-> 0
  4 -b-> 2
  4 -a,x-> 4
  5 -#-> 1
  5 -a-> 3
  5 -b-> 0
  5 -x-> 5
```

A node runs its instructions: `R`, `L`, `R[x]` and `L[x]` (move until `x`,
at least one cell), `R[!x]`, `W[x]` (write) and `C[M]` (run machine `M`).
Then the machine follows the edge whose condition matches the symbol under
the head: `-a->`, `-a,b->`, `-!a,b->` (anything else), `-$s in !{#}->`
(stores the symbol in `$s`, used later as `W[$s]`) or `->` (always). With no
edge it stops.

The tape starts as `#word` with the head on the first `#`. The result is
`accepted` if the tape has `Y`, `rejected` if it has `N`, and otherwise the
final tape.

## Grammars

```
grammar Expr
  E -> E + T | T
  T -> T * F | F
  F -> ( E ) | n
```

The first rule gives the start symbol. Symbols are separated by spaces and
`λ` is the empty word. `run Expr "n + n * n"` finds a leftmost derivation;
the viewer shows it step by step together with the derivation tree. When all
terminals are single characters, spaces in the word are optional.
