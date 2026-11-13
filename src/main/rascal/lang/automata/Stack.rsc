module lang::automata::Stack

import lang::automata::Core;
import List;
import Set;
import String;

alias Moves = rel[str from, str read, str top, list[str] put, str to, str op];

data Pda = pushdown(set[str] alphabet, set[str] states, str initial, set[str] final, Moves delta);

alias Config = tuple[str state, list[str] stack, int at];

alias Step = tuple[Config config, str move];

public int maxConfigs = 200000;

list[Step] successors(Pda m, list[str] w, Config c)
  = [ <<q, put + (top == "" ? c.stack : c.stack[1..]), c.at + size(r)>, "<c.state> -<op>-\> <q>">
    | <p, r, top, put, q, op> <- m.delta, p == c.state,
      r == "" || (c.at < size(w) && w[c.at] == r),
      top == "" || (c.stack != [] && c.stack[0] == top) ];

bool accepting(Pda m, list[str] w, Config c) = c.at == size(w) && c.state in m.final && c.stack == [];

list[Step] pathTo(map[Config, Step] parent, Config c) {
  list[Step] path = [];
  while (c in parent) {
    path = [<c, parent[c].move>] + path;
    c = parent[c].config;
  }
  return [<c, "">] + path;
}

tuple[bool accepted, list[Step] path, bool cut] search(Pda m, str word) {
  list[str] w = chars(word);
  int height = (size(w) + 1) * (size(m.states) + 1);
  Config init = <m.initial, [], 0>;
  map[Config, Step] parent = ();
  list[Config] todo = [init];
  set[Config] seen = {init};
  Config best = init;
  int i = 0;
  while (i < size(todo)) {
    Config c = todo[i];
    i += 1;
    if (accepting(m, w, c)) {
      return <true, pathTo(parent, c), false>;
    }
    if (c.at > best.at) {
      best = c;
    }
    if (size(seen) > maxConfigs) {
      return <false, pathTo(parent, best), true>;
    }
    for (<Config d, str move> <- successors(m, w, c), size(d.stack) <= height, d notin seen) {
      seen += {d};
      parent[d] = <c, move>;
      todo += [d];
    }
  }
  return <false, pathTo(parent, best), false>;
}

bool accepts(Pda m, str word) = search(m, word).accepted;
