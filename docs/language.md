# The language

A `.auto` file is a list of declarations: automata, regular expressions,
definitions built from them, and commands that run words or compare automata.
Declarations end where the next one starts, so there are no braces or
semicolons. Comments start with `//` and run to the end of the line.

Names are made of letters, digits and `_`, and may start with a digit, so
`q0`, `Read01` and `5` are all valid names. The following words are reserved
and cannot be used as names:

```
dfa nfa pda tm regex over start final run show check in lambda
determinize minimize complement union intersection difference rename
push pop ignore skip changeTop pushOn
```

A name has to be declared before it is used. Using it earlier gives the
error `X is defined further down`.

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

The first line gives the kind (`dfa` or `nfa`) and the name. Then come the
lines of the automaton, in any order:

| Line | Meaning |
|---|---|
| `start a` | `a` is a start state. An NFA may list several: `start a, b`. |
| `final b, c` | `b` and `c` are final states. |
| `p -0-> q` | reading `0` in `p` goes to `q`. |
| `p -0,1-> q` | one line for several symbols. |
| `p -0-> q, r` | one line for several targets (NFA only). |
| `p -> q` | a λ transition. `p -λ-> q`, `p -ε-> q` and `p -lambda-> q` mean the same. |
| `p -ab-> q` | reads the whole word `ab` (NFA only). |

States do not have to be declared: a state exists once it appears in one of
these lines.

A `dfa` must have exactly one start state, one symbol per label and no λ
transitions, and a state cannot go to two different states with the same
symbol. The checker reports each of these. A DFA does not have to be
complete: a missing transition means the word is rejected, as if it went to an
error state that is not final and never leaves.

### The alphabet

The alphabet is the set of symbols used in the labels. To fix it explicitly,
for instance because some symbol never appears in a transition, write it after
the name:

```
dfa Zeros over {0, 1}
  start z
  final z
  z -0-> z
```

With `over`, a label that uses a symbol outside the alphabet is an error. The
alphabet matters for `complement` and for `check`: the complement of `Zeros`
over `{0, 1}` accepts every word that contains a `1`.

Symbols are single letters or digits.

## Regular expressions

```
regex NoAA = a(b|ba)* | (b|ba)*
regex NoAA2 = (b|ab)*(a|λ)
```

The expression runs to the end of the line. Spaces may separate its parts,
except right before `*`, `+` and `?`: `(b | ba)*` is fine, `a *` is not.

| Syntax | Meaning |
|---|---|
| `a`, `0` | a symbol |
| `λ` or `ε` | the empty word |
| `∅` | the empty language |
| `rs` | concatenation |
| `r|s` | union |
| `r*` | zero or more |
| `r+` | one or more |
| `r?` | zero or one |
| `(r)` | grouping |

`*`, `+` and `?` bind tighter than concatenation, and concatenation binds
tighter than `|`, so `ab*|c` means `(a(b*))|c`.

The alphabet of an expression is the set of symbols in it; `regex R over {a,
b} = a*` fixes it as for automata. Internally each expression becomes an NFA
by Thompson's construction, so `show R` draws that NFA and every operation
below accepts expressions as well as automata.

## Definitions and operations

A definition gives a name to the result of an operation:

```
Dfa = rename(determinize(End0Or1))
Min = minimize(Dfa)
```

| Operation | Result |
|---|---|
| `determinize(A)` | the subset construction. Each state is named after the set of states of `A` it stands for, such as `{A, B, C}`; `∅` is the empty set. λ transitions and word labels are handled first. |
| `minimize(A)` | the minimal DFA. Unreachable states are removed and equivalent states merged; a merged state keeps the alphabetically smallest name, and the viewer shows which states it merges. |
| `complement(A)` | a DFA for the words over the alphabet of `A` that `A` rejects. |
| `union(A, B)` | the product construction for the words accepted by `A` or `B`. |
| `intersection(A, B)` | the same, for words accepted by both. |
| `difference(A, B)` | the same, for words accepted by `A` and not by `B`. |
| `rename(A)` | the same automaton with states `q0`, `q1`, ... in the order a breadth-first walk from the start meets them. The old names are kept as notes. |

The product operations work over the union of both alphabets. Operations
only accept finite automata and regular expressions; using a pushdown
automaton or a Turing machine gives an error.

## Commands

```
run Has01 λ, "01", "1101"
show Min
check NoAA = NoAA2
```

`run X w1, w2, ...` runs each word. Words are written in double quotes, and
`λ` stands for the empty word. In the editor the result appears after each
word; on the command line it is printed.

`show X` draws `X`. In the editor it opens the viewer; on the command line it
prints the states and transitions.

`check A = B` decides whether two finite automata or regular expressions
accept the same language. The answer is exact: it walks the product of the
two determinized automata, so `equal` means equal for every word, not only
for the words tried. When they differ it gives the shortest word on which
they disagree (the first in alphabetical order among those of that length),
for example

```
different: Has01 rejects "0" and End0Or1 accepts it
```

## Pushdown automata

The notation follows the course: a transition reads one input symbol, or
nothing, and performs one operation on the stack.

```
pda AnBn
  start A
  final B
  A -a, push(a)-> A
  A -λ, ignore-> B
  B -b, pop(a)-> B
```

A transition is `p -σ, op-> q`, where `σ` is an input symbol or `λ`. The
operations are:

| Operation | Needs on top | Effect |
|---|---|---|
| `push(e)` | anything | puts `e` on top |
| `pop(e)` | `e` | removes `e` |
| `ignore` | anything | leaves the stack as it is |
| `skip(e)` | `e` | leaves `e` where it is |
| `changeTop(e, f)` | `e` | replaces `e` by `f` |
| `pushOn(e, f)` | `f` | puts `e` on top of `f` |

`skip` comes from GOLD; the other five are the ones in the slides. The order
of the arguments of `pushOn` is the one in the slides ("put `e` on top if the
current top is `f`"), which is the reverse of GOLD's; see
[docs/gold.md](gold.md).

A pushdown automaton has one start state. It starts with an empty stack and
accepts a word when it can read the whole word and end in a final state with
an empty stack. All three conditions are needed.

Input and stack symbols are single characters. Letters, digits and
`$ # + * / = . ;` can be written as they are; any other character goes
between single quotes:

```
pda Wff
  start E
  final F
  E -p, ignore-> F
  E -N, ignore-> E
  E -'(', push(P)-> E
  F -A, ignore-> E
  F -')', pop(P)-> F
```

Words in `run` may contain any character except `"`.

### How words are run

A pushdown automaton may be nondeterministic, so running a word is a search:
the tool explores configurations (state, stack, input read) in breadth-first
order and stops at the first one that accepts. The viewer then shows that
computation, which is one of the shortest accepting ones. If none accepts, it
shows the computation that read the most input.

λ transitions that push can make the stack grow forever. The search does not
follow stacks taller than (n + 1)(k + 1), for a word of length n and an
automaton with k states, and gives up after 200000 configurations; the viewer
says so when that happens.

## Turing machines

Turing machines are written as composed machines, in the notation of GOLD's
Turing machine tool. Each node runs a short sequence of basic machines; after
the sequence the machine looks at the cell under the head and follows the
edge whose condition holds.

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

### Nodes

`name: instructions` defines a node. The instructions are written one after
the other, with or without spaces:

| Instruction | Effect |
|---|---|
| `R` | move one cell right |
| `L` | move one cell left |
| `R[x]` | move right at least once, until the head is on an `x` |
| `R[!x]` | move right at least once, until the head is on something other than `x` |
| `L[x]`, `L[!x]` | the same, to the left |
| `W[x]` | write `x` |
| `C[M]` | run the machine `M` of the same file on the same tape, then continue |

The blank symbol is `#`. Variables `$a` to `$z` can be used wherever a symbol
can: `W[$s]` writes the symbol stored in `$s`, and `R[$s]` moves right until
it finds it.

### Edges

| Edge | Followed when the symbol under the head is |
|---|---|
| `p -a-> q` | `a` |
| `p -a,b-> q` | `a` or `b` |
| `p -!a,b-> q` | anything except `a` and `b` |
| `p -$s in {a,b}-> q` | `a` or `b`; the symbol is stored in `$s` |
| `p -$s in !{#}-> q` | anything except `#`; the symbol is stored in `$s` |
| `p -> q` | anything |

If no edge applies, the machine stops. If two apply, it stops with an error;
the checker warns about pairs of edges that can apply at the same time.

### Running

`run M "aabb"` starts with the tape `#aabb` followed by blanks, the head on
the first `#` (cell 0) and the machine in its start node. Following the
conventions of the GOLD examples, the result is

- `accepted` if the final tape contains `Y` and no `N`,
- `rejected` if it contains `N` and no `Y`,
- `halted with <tape>` otherwise, which is the normal result for machines that
  compute something, such as `Copy`.

The tape has 16384 cells and a run has at most 262144 steps, the same limits
as GOLD. A run stops with an error when the head moves left of cell 0, moves
past the last cell, the step limit is reached, two edges apply, or a variable
is used before it has a value.
