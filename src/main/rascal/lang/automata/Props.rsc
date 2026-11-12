module lang::automata::Props

import IO;
import lang::automata::Build;
import lang::automata::Check;
import lang::automata::Core;
import lang::automata::Print;
import List;
import Message;
import Set;
import String;
import util::Math;
import util::Maybe;

int rounds = 150;

list[str] sigma = ["a", "b"];

list[str] wordsOf(0) = [""];
default list[str] wordsOf(int n) = [ w + c | w <- wordsOf(n - 1), c <- sigma ];

list[str] words = [ w | n <- [0..6], w <- wordsOf(n) ];

bool reference(Automaton a, str w) {
  set[tuple[str, int]] seen = { <q, 0> | q <- a.initial };
  solve (seen) {
    seen += { <q, i + size(l)> | <p, i> <- seen, <x, l, q> <- a.delta, x == p, startsWith(w[i..], l) };
  }
  return any(<q, i> <- seen, i == size(w), q in a.final);
}

bool matches(sym(str c), str w) = w == c;
bool matches(eps(), str w) = w == "";
bool matches(Re::zero(), str _) = false;
bool matches(alt(Re l, Re r), str w) = matches(l, w) || matches(r, w);
bool matches(cat(Re l, Re r), str w) = any(i <- [0..size(w) + 1], matches(l, w[..i]) && matches(r, w[i..]));
bool matches(star(Re r), str w) = w == "" || any(i <- [1..size(w) + 1], matches(r, w[..i]) && matches(star(r), w[i..]));

bool same(Automaton a, Automaton b) = !any(w <- words, reference(a, w) != reference(b, w));

str pick(list[str] xs) = xs[arbInt(size(xs))];

set[str] some(list[str] xs) = { x | x <- xs, arbInt(2) == 0 };

list[str] statesOf() = [ "p<i>" | i <- [0..1 + arbInt(4)] ];

Automaton tidy(Automaton a) = a[states = a.initial + a.final + a.delta<from> + a.delta<to>];

Automaton nfa() {
  list[str] qs = statesOf();
  Delta d = { <p, l, q> | p <- qs, l <- ["", "a", "b", "ab", "ba"], q <- qs, arbInt(6) == 0 };
  return tidy(automaton(toSet(sigma), toSet(qs), {pick(qs)} + (arbInt(3) == 0 ? some(qs) : {}), some(qs), d));
}

Automaton dfa() {
  list[str] qs = statesOf();
  Delta d = { <p, c, pick(qs)> | p <- qs, c <- sigma, arbInt(4) != 0 };
  return tidy(automaton(toSet(sigma), toSet(qs), {qs[0]}, some(qs), d));
}

Automaton random() = arbInt(2) == 0 ? nfa() : dfa();

Re re(0) = [sym("a"), sym("b"), sym("a"), sym("b"), eps(), Re::zero()][arbInt(6)];
default Re re(int n) {
  switch (arbInt(5)) {
    case 0: return alt(re(n - 1), re(n - 1));
    case 1: return cat(re(n - 1), re(n - 1));
    case 2: return star(re(n - 1));
  }
  return re(0);
}

bool fails(str what, value x) {
  println("FAILED <what>: <x>");
  return false;
}

bool total(Automaton a) = isDfa(a) && !any(p <- a.states, c <- a.alphabet, size(a.delta[p, c]) != 1);

test bool acceptsAgreesWithReference() {
  for (_ <- [0..rounds]) {
    Automaton a = random();
    if (w <- words, accepts(a, w) != reference(a, w)) {
      return fails("accepts on <w>", a);
    }
  }
  return true;
}

test bool determinizeKeepsLanguage() {
  for (_ <- [0..rounds]) {
    Automaton a = nfa();
    Automaton d = determinize(a);
    if (!total(d) || !same(a, d)) {
      return fails("determinize", a);
    }
  }
  return true;
}

test bool toDfaKeepsLanguage() {
  for (_ <- [0..rounds]) {
    Automaton a = random();
    Automaton d = toDfa(a);
    if (!total(d) || !same(a, d)) {
      return fails("toDfa", a);
    }
  }
  return true;
}

bool minimal(Automaton m)
  = reachable(m).states == m.states
  && !any(p <- m.states, q <- m.states, p != q, counterexample(m[initial = {p}], m[initial = {q}]) == nothing());

test bool minimizeKeepsLanguageAndIsMinimal() {
  for (_ <- [0..rounds]) {
    Automaton a = random();
    Automaton m = minimize(a);
    if (!total(m) || !same(a, m) || !minimal(m) || size(minimize(m).states) != size(m.states)) {
      return fails("minimize", a);
    }
  }
  return true;
}

test bool complementFlipsEveryWord() {
  for (_ <- [0..rounds]) {
    Automaton a = random();
    Automaton c = complement(a);
    if (w <- words, reference(c, w) == reference(a, w)) {
      return fails("complement on <w>", a);
    }
  }
  return true;
}

test bool productFollowsSetOperations() {
  for (_ <- [0..rounds]) {
    Automaton a = random();
    Automaton b = random();
    Automaton u = product(a, b, "union");
    Automaton i = product(a, b, "intersection");
    Automaton d = product(a, b, "difference");
    for (w <- words) {
      bool x = reference(a, w);
      bool y = reference(b, w);
      if (reference(u, w) != (x || y) || reference(i, w) != (x && y) || reference(d, w) != (x && !y)) {
        return fails("product on <w>", <a, b>);
      }
    }
  }
  return true;
}

test bool counterexampleIsShortestAndCorrect() {
  for (_ <- [0..rounds]) {
    Automaton a = random();
    Automaton b = arbInt(2) == 0 ? rename(minimize(a)) : random();
    switch (counterexample(a, b)) {
      case nothing(): {
        if (!same(a, b)) {
          return fails("counterexample missed a difference", <a, b>);
        }
      }
      case just(str w): {
        if (reference(a, w) == reference(b, w)) {
          return fails("counterexample <w> is not a difference", <a, b>);
        }
        if (v <- words, size(v) < size(w), reference(a, v) != reference(b, v)) {
          return fails("counterexample <w> is not the shortest, <v> is shorter", <a, b>);
        }
      }
    }
  }
  return true;
}

test bool thompsonMatchesRegex() {
  for (_ <- [0..rounds]) {
    Re r = re(3);
    Automaton t = thompson(r, toSet(sigma));
    if (w <- words, reference(t, w) != matches(r, w)) {
      return fails("thompson on <w>", r);
    }
  }
  return true;
}

test bool renameKeepsLanguage() {
  for (_ <- [0..rounds]) {
    Automaton a = random();
    Automaton r = rename(a);
    if (!same(a, r) || isDfa(a) != isDfa(r) || size(r.states) != size(a.states)) {
      return fails("rename", a);
    }
  }
  return true;
}

test bool printedAutomataLoadBack() {
  for (_ <- [0..rounds]) {
    Automaton a = random();
    str text = print("X", a);
    set[Message] msgs = check(load(text, |memory:///x.auto|));
    Automaton b = env(load(text, |memory:///x.auto|))["X"];
    if (hasErrors(msgs) || b != a) {
      return fails("print and load", text);
    }
  }
  return true;
}

test bool nonDeterministicDfaIsRejected() {
  for (_ <- [0..rounds]) {
    Automaton a = nfa();
    if (!isDfa(a) && !hasErrors(check(load(print("X", a, kind = "dfa"), |memory:///x.auto|)))) {
      return fails("a DFA with nondeterminism was accepted", print("X", a, kind = "dfa"));
    }
  }
  return true;
}

test bool printedRegexLoadsBack() {
  for (_ <- [0..rounds]) {
    Re r = re(3);
    str text = "regex R over {a, b} = <print(r)>\n";
    Automaton t = env(load(text, |memory:///r.auto|))["R"];
    if (w <- words, reference(t, w) != matches(r, w)) {
      return fails("regex print and load on <w>", text);
    }
  }
  return true;
}
