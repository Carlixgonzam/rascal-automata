module lang::automata::Report

import lang::automata::Core;
import List;
import Set;
import util::Maybe;

str quote(str w) = "\"<w>\"";

str describe(Automaton a) = "<isDfa(a) ? "DFA" : "NFA">, <size(a.states)> states";

str verdict(Automaton a, str w) = accepts(a, w) ? "accepted" : "rejected";

bool same(Automaton a, Automaton b) = counterexample(a, b) == nothing();

str compare(str x, str y, Automaton a, Automaton b) {
  if (just(str w) := counterexample(a, b)) {
    return accepts(a, w)
      ? "different: <x> accepts <quote(w)> and <y> rejects it"
      : "different: <x> rejects <quote(w)> and <y> accepts it";
  }
  return "equal";
}

str marks(Automaton a, str q) = (q in a.initial ? "→" : " ") + (q in a.final ? "*" : " ");

str note(Automaton a, str q) = q in a.notes ? "   <a.notes[q]>" : "";

list[str] table(Automaton a)
  = [ "<marks(a, q)> <q><note(a, q)>" | q <- sort(a.states) ]
  + [ "<p> -<l == "" ? "λ" : l>-\> <q>" | <p, l, q> <- sort(a.delta) ];
