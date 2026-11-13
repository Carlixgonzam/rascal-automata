module lang::automata::Grammar

import List;
import Set;
import String;

alias Rules = lrel[str lhs, list[str] rhs];

data Grammar = cfg(str axiom, Rules rules);

set[str] nonterminals(Grammar g) = toSet(g.rules.lhs);

alias Form = list[str];

alias Expansion = tuple[Form form, int at, list[str] rhs];

public int maxForms = 100000;

int leftmost(Grammar g, Form f) {
  set[str] ns = nonterminals(g);
  for (i <- index(f), f[i] in ns) {
    return i;
  }
  return -1;
}

list[str] tokens(Grammar g, str word) {
  set[str] terminals = { s | <_, rhs> <- g.rules, s <- rhs } - nonterminals(g);
  if (any(t <- terminals, size(t) > 1)) {
    return [ x | x <- split(" ", word), x != "" ];
  }
  return [ word[i] | i <- [0..size(word)], word[i] != " " ];
}

bool fits(Grammar g, Form f, list[str] w) {
  int i = leftmost(g, f);
  list[str] fixed = i == -1 ? f : f[..i];
  int terminals = size([ s | s <- f, s notin nonterminals(g) ]);
  return size(fixed) <= size(w) && fixed == w[..size(fixed)] && terminals <= size(w);
}

tuple[bool found, list[Expansion] steps, bool cut] derive(Grammar g, list[str] w) {
  int longest = size(w) + size(nonterminals(g)) + 2;
  Form first = [g.axiom];
  map[Form, Expansion] parent = ();
  list[Form] todo = [first];
  set[Form] seen = {first};
  int k = 0;
  while (k < size(todo)) {
    Form f = todo[k];
    k += 1;
    if (f == w) {
      return <true, trail(parent, f), false>;
    }
    if (size(seen) > maxForms) {
      return <false, [], true>;
    }
    int i = leftmost(g, f);
    if (i == -1) {
      continue;
    }
    for (<lhs, rhs> <- g.rules, lhs == f[i]) {
      Form next = f[..i] + rhs + f[i + 1..];
      if (size(next) <= longest && next notin seen && fits(g, next, w)) {
        seen += {next};
        parent[next] = <f, i, rhs>;
        todo += [next];
      }
    }
  }
  return <false, [], false>;
}

list[Expansion] trail(map[Form, Expansion] parent, Form f) {
  list[Expansion] steps = [];
  while (f in parent) {
    steps = [parent[f]] + steps;
    f = parent[f].form;
  }
  return steps;
}

str sentence(list[str] syms) = syms == [] ? "λ" : intercalate(" ", syms);
