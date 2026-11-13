module lang::automata::Report

import lang::automata::Build;
import lang::automata::Core;
import lang::automata::Grammar;
import lang::automata::Stack;
import lang::automata::Syntax;
import lang::automata::Turing;
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

str describe(Pda m) = "PDA, <size(m.states)> states";

str describe(Tm m) = "TM, <size(statesOf(m))> nodes";

list[str] table(Pda m)
  = [ "<q == m.initial ? "→" : " "><q in m.final ? "*" : " "> <q>" | q <- sort(m.states) ]
  + [ "<p> -<op>-\> <q>" | <p, _, _, _, q, op> <- sort(m.delta) ];

list[str] table(Tm m)
  = [ "<q == m.initial ? "→" : " "> <q>: <intercalate("", [ x.text | x <- m.code[q] ? [] ])>" | q <- sort(statesOf(m)) ]
  + [ t == "" ? "<p> -\> <q>" : "<p> -<t>-\> <q>" | <p, _, q, t> <- sort(m.edges) ];

str outcomeOf(start[Program] p, Expr e, str w) {
  str x = "<e>";
  map[str, Grammar] gs = grammars(p);
  if (x in gs) {
    return derivation(gs[x], w);
  }
  map[str, Pda] ps = pdas(p);
  if (x in ps) {
    return search(ps[x], w).accepted ? "accepted" : "rejected";
  }
  map[str, Tm] ts = tms(p);
  if (x in ts) {
    return verdict(simulate(ts, x, w));
  }
  return verdict(eval(e, env(p)), w);
}

list[str] showOf(start[Program] p, Expr e) {
  str x = "<e>";
  if (x in grammars(p)) {
    return [describe(grammars(p)[x])] + table(grammars(p)[x]);
  }
  if (x in pdas(p)) {
    return [describe(pdas(p)[x])] + table(pdas(p)[x]);
  }
  if (x in tms(p)) {
    return [describe(tms(p)[x])] + table(tms(p)[x]);
  }
  Automaton a = eval(e, env(p));
  return [describe(a)] + table(a);
}

str derivation(Grammar g, str w) {
  <found, steps, cut> = derive(g, tokens(g, w));
  if (found) {
    return "derived in <size(steps)> <size(steps) == 1 ? "step" : "steps">";
  }
  return cut ? "gave up after <maxForms> sentential forms" : "not derived";
}

str describe(Grammar g) = "grammar, <size(g.rules)> rules";

list[str] table(Grammar g)
  = [ "<n> -\> <intercalate(" | ", [ sentence(rhs) | <m, rhs> <- g.rules, m == n ])>" | n <- dup(g.rules.lhs) ];
