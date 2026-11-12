module lang::automata::Print

import lang::automata::Core;
import List;
import Set;

str print(str name, Automaton a, str kind = isDfa(a) ? "dfa" : "nfa") {
  list[str] lines = ["<kind> <name><a.alphabet == {} ? "" : " over {<intercalate(", ", sort(a.alphabet))>}">"];
  if (a.initial != {}) {
    lines += ["  start <intercalate(", ", sort(a.initial))>"];
  }
  if (a.final != {}) {
    lines += ["  final <intercalate(", ", sort(a.final))>"];
  }
  for (<p, l, q> <- sort(a.delta)) {
    lines += [l == "" ? "  <p> -\> <q>" : "  <p> -<l>-\> <q>"];
  }
  return intercalate("\n", lines) + "\n";
}

int level(alt(_, _)) = 0;
int level(cat(_, _)) = 1;
int level(star(_)) = 2;
default int level(Re _) = 3;

str wrap(Re r, int min) = level(r) < min ? "(<print(r)>)" : print(r);

str print(sym(str c)) = c;
str print(eps()) = "λ";
str print(Re::zero()) = "∅";
str print(alt(Re l, Re r)) = "<wrap(l, 0)> | <wrap(r, 1)>";
str print(cat(Re l, Re r)) = "<wrap(l, 1)><wrap(r, 2)>";
str print(star(Re r)) = "<wrap(r, 3)>*";
