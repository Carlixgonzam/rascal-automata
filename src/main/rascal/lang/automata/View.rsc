module lang::automata::View

import Content;
import IO;
import lang::automata::Core;
import lang::automata::Stack;
import lang::automata::Turing;
import List;
import Set;
import String;

str shown(str l) = l == "" ? "λ" : l;

map[str, value] vertex(str q, bool initial, bool final, str note) = ("id": q, "initial": initial, "final": final, "note": note);

map[str, value] edge(str p, str q, list[str] labels) = ("id": edgeId(p, q), "source": p, "target": q, "label": intercalate("\n", labels));

map[str, value] graph(str name, Automaton a, str word) = (
  "name": name,
  "word": word,
  "nodes": [ vertex(q, q in a.initial, q in a.final, a.notes[q] ? "") | q <- sort(a.states) ],
  "edges": [ edge(p, q, [intercalate(", ", sort({ shown(l) | <x, l, y> <- a.delta, x == p, y == q }))]) | <p, q> <- sort(a.delta<from, to>) ]
);

map[str, value] graph(str name, Pda m, str word) = (
  "name": name,
  "word": word,
  "nodes": [ vertex(q, q == m.initial, q in m.final, "") | q <- sort(m.states) ],
  "edges": [ edge(p, q, sort([ op | <x, _, _, _, y, op> <- m.delta, x == p, y == q ])) | <p, q> <- sort(m.delta<from, to>) ]
);

map[str, value] graph(str name, Tm m, str word) = (
  "name": name,
  "word": word,
  "nodes": [ vertex(q, q == m.initial, false, intercalate("", [ x.text | x <- m.code[q] ? [] ])) | q <- sort(m.code<0> + m.edges<from> + m.edges<to>) ],
  "edges": [ edge(p, q, sort([ t | <x, _, y, t> <- m.edges, x == p, y == q ])) | <p, q> <- sort(m.edges<from, to>) ]
);

str named(str q) {
  if ([p, l, t, n] := split("·", q)) {
    return "<p> -<l>-\> <t> (<l[..toInt(n)]> read)";
  }
  return q;
}

str names(set[str] qs) = intercalate(", ", sort([ named(q) | q <- qs ]));

str edgeOf(str x, str y) {
  if ([p, _, q, _] := split("·", x)) {
    return edgeId(p, q);
  }
  if ([p, _, q, _] := split("·", y)) {
    return edgeId(p, q);
  }
  return edgeId(x, y);
}

list[str] jumps(Automaton s, set[str] now) = dup([ edgeOf(p, q) | <p, "", q> <- sort(s.delta), p in now ]);

list[str] lambdaNotes(Automaton s, set[str] now)
  = [ "<named(p)>: λ leads to <names(s.delta[p, ""])>" | p <- sort(now), s.delta[p, ""] != {} ];

str move(str p, str c, set[str] qs) = qs == {} ? "<named(p)>: no move on <c>" : "<named(p)>: <c> leads to <names(qs)>";

str verdict(Automaton a, set[str] now) {
  set[str] hits = now & a.final;
  if (hits != {}) {
    return "<names(hits)> <size(hits) == 1 ? "is" : "are"> final, so the word is accepted";
  }
  return now & a.states == {} ? "no state is active, so the word is rejected" : "no active state is final, so the word is rejected";
}

map[str, value] outside(set[str] sigma, str word) {
  list[str] bad = [ c | c <- chars(word), c notin sigma ];
  return bad == [] ? () : ("error": "the symbol <bad[0]> is not in the alphabet {<intercalate(", ", sort(sigma))>}");
}

map[str, value] runOf(Automaton a, str word) {
  if (outside(a.alphabet, word) != ()) {
    return outside(a.alphabet, word);
  }
  Automaton s = expand(a);
  set[str] now = closure(s, s.initial);
  list[tuple[set[str] states, list[str] moves, list[str] jumps, list[str] notes]] steps
    = [<now, [], jumps(s, now), ["start in <names(s.initial)>"] + lambdaNotes(s, now)>];
  for (c <- chars(word)) {
    set[str] before = now;
    rel[str, str] moved = { <p, q> | <p, l, q> <- s.delta, l == c, p in before };
    now = closure(s, moved<1>);
    steps += [<now, dup([ edgeOf(p, q) | <p, q> <- sort(moved) ]), jumps(s, now),
               [ move(p, c, moved[p]) | <_, p> <- sort({ <named(p), p> | p <- before }) ] + lambdaNotes(s, now)>];
  }
  steps[size(steps) - 1].notes += [verdict(a, now)];
  bool yes = now & a.final != {};
  return (
    "verdict": yes ? "accepted" : "rejected",
    "accepted": yes,
    "steps": [ ("states": sort(steps[i].states & a.states), "moves": steps[i].moves, "jumps": steps[i].jumps,
                "notes": steps[i].notes, "tape": chars(word), "head": i, "read": true) | i <- index(steps) ]
  );
}

str stackText(list[str] s) = s == [] ? "empty" : intercalate("", s);

map[str, value] runOf(Pda m, str word) {
  if (outside(m.alphabet, word) != ()) {
    return outside(m.alphabet, word);
  }
  <yes, path, cut> = search(m, word);
  list[map[str, value]] steps = [];
  for (i <- index(path)) {
    <c, how> = path[i];
    list[str] notes = i == 0 ? ["start in <c.state> with an empty stack"] : ["<how>; the stack is now <stackText(c.stack)>"];
    list[str] moves = i == 0 ? [] : [edgeId(path[i - 1].config.state, c.state)];
    steps += [("states": [c.state], "moves": moves, "jumps": [], "notes": notes, "tape": chars(word), "head": c.at, "stack": c.stack, "read": true)];
  }
  str last = yes
    ? "<path[size(path) - 1].config.state> is final, the word is read and the stack is empty, so the word is accepted"
    : "no computation reads the whole word and ends in a final state with an empty stack, so the word is rejected; this is the computation that read the most";
  if (cut) {
    last += " (the search stopped after <maxConfigs> configurations)";
  }
  if (list[str] ns := steps[size(steps) - 1]["notes"]) {
    steps[size(steps) - 1]["notes"] = ns + [last];
  }
  return ("verdict": yes ? "accepted" : "rejected", "accepted": yes, "steps": steps);
}

map[str, value] runOf(map[str, Tm] machines, str name, str word) {
  Run r = simulate(machines, name, word);
  list[map[str, value]] steps = [ ("states": s.machine == name ? [s.state] : [], "moves": s.machine == name && s.edge != "" ? [s.edge] : [],
                                   "jumps": [], "notes": [(s.machine == name ? "" : "inside <s.machine>, ") + s.note],
                                   "tape": s.tape, "head": s.head, "read": false) | s <- r.snaps ];
  str v = verdict(r);
  list[str] tail = [v];
  if (size(r.snaps) >= keep) {
    tail = ["only the first <keep> of <r.steps> steps are shown", v];
  }
  if (list[str] ns := steps[size(steps) - 1]["notes"]) {
    steps[size(steps) - 1]["notes"] = ns + tail;
  }
  return ("verdict": v, "accepted": v == "accepted", "steps": steps);
}

Response (Request) server(map[str, value] shape, map[str, value] (str) runner) {
  Response reply(get(/^\/automaton/)) = jsonResponse(ok(), (), shape);
  Response reply(get(/^\/run/, parameters = ps)) = jsonResponse(ok(), (), runner(ps["word"] ? ""));
  Response reply(get(/^\/lib\/<file:[a-z\-]+\.js>$/)) = response(getResource("automata-<file>"));
  default Response reply(get(_)) = response(getResource("automata-view.html"));
  return reply;
}

Content window(str name, map[str, value] shape, map[str, value] (str) runner)
  = content("automaton-<name>", server(shape, runner), title = name, viewColumn = -2);

Content view(str name, Automaton a, str word = "")
  = window(name, graph(name, a, word), map[str, value] (str w) { return runOf(a, w); });

Content view(str name, Pda m, str word = "")
  = window(name, graph(name, m, word), map[str, value] (str w) { return runOf(m, w); });

Content view(map[str, Tm] machines, str name, str word = "")
  = window(name, graph(name, machines[name], word), map[str, value] (str w) { return runOf(machines, name, w); });
