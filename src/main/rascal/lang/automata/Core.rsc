module lang::automata::Core

import List;
import Map;
import Set;
import String;
import util::Maybe;

alias Delta = rel[str from, str label, str to];

data Automaton(map[str, str] notes = ())
  = automaton(set[str] alphabet, set[str] states, set[str] initial, set[str] final, Delta delta);

data Re = sym(str c) | eps() | zero() | cat(Re l, Re r) | alt(Re l, Re r) | star(Re r);

str dead = "∅";

list[str] chars(str w) = [ w[i] | i <- [0..size(w)] ];

set[str] closure(Automaton a, set[str] qs) {
  solve (qs) {
    qs += { q | <p, "", q> <- a.delta, p in qs };
  }
  return qs;
}

set[str] step(Automaton a, set[str] qs, str c)
  = closure(a, { q | <p, l, q> <- a.delta, l == c, p in qs });

Automaton expand(Automaton a) {
  Delta d = {};
  for (<p, l, q> <- a.delta) {
    if (size(l) <= 1) {
      d += <p, l, q>;
      continue;
    }
    list[str] path = [p] + [ "<p>·<l>·<q>·<i>" | i <- [1..size(l)] ] + [q];
    d += { <path[i], l[i], path[i + 1]> | i <- [0..size(l)] };
  }
  return a[states = a.states + d<from> + d<to>][delta = d];
}

list[set[str]] trace(Automaton a, str w) {
  a = expand(a);
  list[set[str]] steps = [closure(a, a.initial)];
  for (c <- chars(w)) {
    steps += [step(a, last(steps), c)];
  }
  return steps;
}

bool accepts(Automaton a, str w) = last(trace(a, w)) & a.final != {};

bool isDfa(Automaton a)
  = size(a.initial) == 1 && !any(<p, l, _> <- a.delta, size(l) != 1 || size(a.delta[p, l]) != 1);

str nameOf(set[str] qs) = qs == {} ? dead : "{<intercalate(", ", sort(qs))>}";

Automaton complete(Automaton a) {
  Delta missing = { <p, c, dead> | p <- a.states, c <- a.alphabet, a.delta[p, c] == {} };
  if (missing == {}) {
    return a;
  }
  return a[states = a.states + dead][delta = a.delta + missing + { <dead, c, dead> | c <- a.alphabet }];
}

Automaton determinize(Automaton a) {
  a = expand(a);
  set[str] init = closure(a, a.initial);
  set[set[str]] seen = {init};
  solve (seen) {
    seen += { step(a, qs, c) | qs <- seen, c <- a.alphabet };
  }
  return automaton(a.alphabet,
    { nameOf(qs) | qs <- seen },
    {nameOf(init)},
    { nameOf(qs) | qs <- seen, qs & a.final != {} },
    { <nameOf(qs), c, nameOf(step(a, qs, c))> | qs <- seen, c <- a.alphabet });
}

Automaton toDfa(Automaton a) = isDfa(a) ? complete(a) : determinize(a);

str next(Automaton a, str p, str c) = getOneFrom(a.delta[p, c]);

str startOf(Automaton a) = getOneFrom(a.initial);

Automaton reachable(Automaton a) {
  set[str] r = a.initial + (a.delta<from, to>+)[a.initial];
  return a[states = a.states & r][final = a.final & r][delta = { <p, l, q> | <p, l, q> <- a.delta, p in r }];
}

Automaton complement(Automaton a) {
  a = toDfa(a);
  return a[final = a.states - a.final];
}

bool keeps("union", bool x, bool y) = x || y;
bool keeps("intersection", bool x, bool y) = x && y;
bool keeps("difference", bool x, bool y) = x && !y;

str pair(str p, str q) = "(<p>, <q>)";

Automaton product(Automaton a, Automaton b, str mode) {
  set[str] sigma = a.alphabet + b.alphabet;
  a = toDfa(a[alphabet = sigma]);
  b = toDfa(b[alphabet = sigma]);
  rel[str, str] seen = {<startOf(a), startOf(b)>};
  solve (seen) {
    seen += { <next(a, p, c), next(b, q, c)> | <p, q> <- seen, c <- sigma };
  }
  return automaton(sigma,
    { pair(p, q) | <p, q> <- seen },
    {pair(startOf(a), startOf(b))},
    { pair(p, q) | <p, q> <- seen, keeps(mode, p in a.final, q in b.final) },
    { <pair(p, q), c, pair(next(a, p, c), next(b, q, c))> | <p, q> <- seen, c <- sigma });
}

Automaton minimize(Automaton a) {
  a = reachable(toDfa(a));
  list[str] sigma = sort(a.alphabet);
  set[set[str]] blocks = { a.final, a.states - a.final } - {{}};
  solve (blocks) {
    map[str, set[str]] home = ( q : b | b <- blocks, q <- b );
    rel[list[set[str]], str] sig = { <[home[q]] + [ home[next(a, q, c)] | c <- sigma ], q> | q <- a.states };
    blocks = { sig[s] | s <- sig<0> };
  }
  map[str, str] name = ( q : sort(b)[0] | b <- blocks, q <- b );
  map[str, str] notes = ( sort(b)[0] : "merges <intercalate(", ", sort(b))>" | b <- blocks, size(b) > 1 )
                      + ( q : a.notes[q] | {q} <- blocks, q in a.notes );
  return automaton(a.alphabet, range(name), { name[q] | q <- a.initial }, { name[q] | q <- a.final },
                   { <name[p], c, name[q]> | <p, c, q> <- a.delta }, notes = notes);
}

Maybe[str] counterexample(Automaton a, Automaton b) {
  set[str] sigma = a.alphabet + b.alphabet;
  a = toDfa(a[alphabet = sigma]);
  b = toDfa(b[alphabet = sigma]);
  list[tuple[str, str, str]] todo = [<startOf(a), startOf(b), "">];
  set[tuple[str, str]] seen = {<startOf(a), startOf(b)>};
  while (todo != []) {
    <p, q, w> = todo[0];
    todo = todo[1..];
    if ((p in a.final) != (q in b.final)) {
      return just(w);
    }
    for (c <- sort(sigma)) {
      tuple[str, str] t = <next(a, p, c), next(b, q, c)>;
      if (t notin seen) {
        seen += {t};
        todo += [<t[0], t[1], w + c>];
      }
    }
  }
  return nothing();
}

alias Part = tuple[Delta delta, str enter, str exit, int n];

Part part(sym(str c), int n) = <{<"q<n>", c, "q<n + 1>">}, "q<n>", "q<n + 1>", n + 2>;
Part part(eps(), int n) = <{<"q<n>", "", "q<n + 1>">}, "q<n>", "q<n + 1>", n + 2>;
Part part(zero(), int n) = <{}, "q<n>", "q<n + 1>", n + 2>;

Part part(cat(Re l, Re r), int n) {
  Part x = part(l, n);
  Part y = part(r, x.n);
  return <x.delta + y.delta + {<x.exit, "", y.enter>}, x.enter, y.exit, y.n>;
}

Part part(alt(Re l, Re r), int n) {
  Part x = part(l, n);
  Part y = part(r, x.n);
  str i = "q<y.n>";
  str f = "q<y.n + 1>";
  return <x.delta + y.delta + {<i, "", x.enter>, <i, "", y.enter>, <x.exit, "", f>, <y.exit, "", f>}, i, f, y.n + 2>;
}

Part part(star(Re r), int n) {
  Part x = part(r, n);
  str i = "q<x.n>";
  str f = "q<x.n + 1>";
  return <x.delta + {<i, "", x.enter>, <x.exit, "", f>, <i, "", f>, <x.exit, "", x.enter>}, i, f, x.n + 2>;
}

Automaton thompson(Re re, set[str] alphabet) {
  Part p = part(re, 0);
  return automaton(alphabet, p.delta<from> + p.delta<to> + {p.enter, p.exit}, {p.enter}, {p.exit}, p.delta);
}

Automaton rename(Automaton a) {
  list[str] order = [];
  list[str] todo = sort(a.initial);
  while (todo != []) {
    str p = todo[0];
    todo = todo[1..];
    order += [p];
    todo += dup([ q | l <- [""] + sort(a.alphabet), q <- sort(a.delta[p, l]), q notin order, q notin todo ]);
  }
  order += sort(a.states - toSet(order));
  map[str, str] name = ( order[i] : "q<i>" | i <- index(order) );
  return automaton(a.alphabet, range(name), { name[p] | p <- a.initial }, { name[p] | p <- a.final },
                   { <name[p], l, name[q]> | <p, l, q> <- a.delta },
                   notes = ( name[p] : p | p <- order, name[p] != p ));
}
