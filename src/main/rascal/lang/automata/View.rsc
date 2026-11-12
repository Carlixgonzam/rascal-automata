module lang::automata::View

import Content;
import IO;
import lang::automata::Core;
import List;
import Set;
import String;

str shown(str l) = l == "" ? "λ" : l;

str edgeId(str p, str q) = "<p>→<q>";

map[str, value] graph(str name, Automaton a, str word) = (
  "name": name,
  "word": word,
  "nodes": [ ("id": q, "initial": q in a.initial, "final": q in a.final, "note": a.notes[q] ? "") | q <- sort(a.states) ],
  "edges": [ ("id": edgeId(p, q), "source": p, "target": q,
              "label": intercalate(", ", sort({ shown(l) | <x, l, y> <- a.delta, x == p, y == q })))
           | <p, q> <- sort(a.delta<from, to>) ]
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

map[str, value] runOf(Automaton a, str word) {
  list[str] bad = [ c | c <- chars(word), c notin a.alphabet ];
  if (bad != []) {
    return ("error": "the symbol <bad[0]> is not in the alphabet {<intercalate(", ", sort(a.alphabet))>}");
  }
  Automaton s = expand(a);
  set[str] now = closure(s, s.initial);
  list[tuple[str read, set[str] states, list[str] moves, list[str] jumps, list[str] notes]] steps
    = [<"", now, [], jumps(s, now), ["start in <names(s.initial)>"] + lambdaNotes(s, now)>];
  for (c <- chars(word)) {
    set[str] before = now;
    rel[str, str] moved = { <p, q> | <p, l, q> <- s.delta, l == c, p in before };
    now = closure(s, moved<1>);
    steps += [<c, now, dup([ edgeOf(p, q) | <p, q> <- sort(moved) ]), jumps(s, now),
               [ move(p, c, moved[p]) | <_, p> <- sort({ <named(p), p> | p <- before }) ] + lambdaNotes(s, now)>];
  }
  steps[size(steps) - 1].notes += [verdict(a, now)];
  return (
    "accepted": now & a.final != {},
    "steps": [ ("read": t.read, "states": sort(t.states & a.states), "moves": t.moves, "jumps": t.jumps, "notes": t.notes) | t <- steps ]
  );
}

Response (Request) server(str name, Automaton a, str word) {
  Response reply(get(/^\/automaton/)) = jsonResponse(ok(), (), graph(name, a, word));
  Response reply(get(/^\/run/, parameters = ps)) = jsonResponse(ok(), (), runOf(a, ps["word"] ? ""));
  default Response reply(get(_)) = response(getResource("automata-view.html"));
  return reply;
}

Content view(str name, Automaton a, str word = "")
  = content("automaton-<name>", server(name, a, word), title = name, viewColumn = -2);
