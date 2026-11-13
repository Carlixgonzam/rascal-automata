module lang::automata::Turing

import lang::automata::Core;
import List;
import Map;
import Set;
import String;

data Move(str text = "")
  = moveRight(str target, bool neg)
  | moveLeft(str target, bool neg)
  | writes(str cell)
  | calls(str machine)
  ;

data Guard = always() | inSet(set[str] cells, bool neg, str var);

alias Edges = rel[str from, Guard guard, str to, str text];

data Tm = turing(str initial, map[str, list[Move]] code, Edges edges);

data Result = fine() | failed(str why);

data Snap = snap(str machine, str state, list[str] tape, int head, str note, str edge);

alias Run = tuple[map[int, str] tape, int head, int steps, list[Snap] snaps, Result result];

public int maxSteps = 262144;
public int maxCells = 16384;
public int keep = 3000;
str blank = "#";

str cellAt(Run r, int i) = r.tape[i] ? blank;

list[str] cells(Run r) {
  int last = r.head;
  for (i <- r.tape, r.tape[i] != blank, i > last) {
    last = i;
  }
  return [ cellAt(r, i) | i <- [0..last + 2] ];
}

str tapeText(Run r) {
  str t = intercalate("", cells(r));
  while (size(t) > 1 && endsWith(t, blank)) {
    t = t[..-1];
  }
  return t;
}

Run record(Run r, str machine, str state, str note, str edge)
  = size(r.snaps) < keep ? r[snaps = r.snaps + [snap(machine, state, cells(r), r.head, note, edge)]] : r;

Run tick(Run r) = r.steps >= maxSteps ? r[result = failed("the machine ran for more than <maxSteps> steps")] : r[steps = r.steps + 1];

bool broken(Run r) = failed(_) := r.result;

Run shift(Run r, int d) {
  int h = r.head + d;
  if (h < 0) {
    return r[result = failed("the head fell off the left end of the tape")];
  }
  if (h >= maxCells) {
    return r[result = failed("the head went past the last cell of the tape")];
  }
  return r[head = h];
}

Run slide(Run r, int d, str target, bool neg, map[str, str] vars) {
  if (startsWith(target, "$") && target notin vars) {
    return r[result = failed("<target> has no value yet")];
  }
  str goal = vars[target] ? target;
  r = shift(r, d);
  while (target != "" && !broken(r) && (cellAt(r, r.head) == goal) == neg) {
    r = shift(r, d);
  }
  return r;
}

Run apply(map[str, Tm] tms, Run r, moveRight(str t, bool n), map[str, str] vars) = slide(r, 1, t, n, vars);
Run apply(map[str, Tm] tms, Run r, moveLeft(str t, bool n), map[str, str] vars) = slide(r, -1, t, n, vars);
Run apply(map[str, Tm] tms, Run r, calls(str x), map[str, str] vars) = exec(tms, x, r);
Run apply(map[str, Tm] tms, Run r, writes(str c), map[str, str] vars) {
  if (startsWith(c, "$") && c notin vars) {
    return r[result = failed("<c> has no value yet")];
  }
  return r[tape = r.tape + (r.head : vars[c] ? c)];
}

bool holds(always(), str _) = true;
bool holds(inSet(set[str] cs, bool neg, str _), str c) = (c in cs) != neg;

map[str, str] binds(inSet(_, _, str v), str c) = v == "" ? () : (v : c);
default map[str, str] binds(Guard _, str _) = ();

Run exec(map[str, Tm] tms, str name, Run r) {
  Tm m = tms[name];
  str state = m.initial;
  map[str, str] vars = ();
  while (true) {
    r = tick(r);
    for (Move x <- m.code[state] ? [], !broken(r)) {
      r = tick(apply(tms, r, x, vars));
      r = broken(r) ? r : record(r, name, state, "<state>: <x.text>", "");
    }
    if (broken(r)) {
      return r;
    }
    str c = cellAt(r, r.head);
    list[tuple[str to, str text, Guard guard]] next = [ <q, t, g> | <p, g, q, t> <- sort(m.edges), p == state, holds(g, c) ];
    if (next == []) {
      return record(r, name, state, "reads <c>; no transition of <state> applies, so <name> stops", "");
    }
    if (size(next) > 1) {
      return r[result = failed("two transitions of <state> apply reading <c>: <next[0].text> and <next[1].text>")];
    }
    vars += binds(next[0].guard, c);
    r = record(r, name, state, "reads <c>; follows <state> -<next[0].text>-\> <next[0].to>", edgeId(state, next[0].to));
    state = next[0].to;
  }
  return r;
}

Run simulate(map[str, Tm] tms, str name, str word) {
  list[str] w = chars(word);
  Run r = <( i + 1 : w[i] | i <- [0..size(w)] ), 0, 0, [], fine()>;
  r = record(r, name, tms[name].initial, "start in <tms[name].initial> with the head on cell 0", "");
  return exec(tms, name, r);
}

str verdict(Run r) {
  if (failed(str why) := r.result) {
    return "error: <why>";
  }
  list[str] t = cells(r);
  if ("Y" in t && "N" notin t) {
    return "accepted";
  }
  if ("N" in t && "Y" notin t) {
    return "rejected";
  }
  return "halted with <tapeText(r)>";
}
