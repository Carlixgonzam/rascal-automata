module lang::automata::Check

import lang::automata::Build;
import lang::automata::Core;
import lang::automata::Syntax;
import List;
import Message;
import ParseTree;
import Set;
import String;

map[str, int] arity = ("determinize": 1, "minimize": 1, "complement": 1, "rename": 1,
                       "union": 2, "intersection": 2, "difference": 2);

str braces(set[str] s) = "{<intercalate(", ", sort(s))>}";

set[Message] repeated(Decl d) {
  list[str] seen = [];
  set[Message] msgs = {};
  for (v <- d.over, c <- v.symbols) {
    if ("<c>" in seen) {
      msgs += warning("the symbol <c> appears twice in the alphabet", c.src);
    }
    seen += ["<c>"];
  }
  return msgs;
}

set[Message] outside(set[str] used, set[str] sigma, loc at)
  = sigma == {} ? {} : { error("the symbol <c> is not in the alphabet <braces(sigma)>", at) | c <- used, c notin sigma };

set[Message] checkLabel(Label l, bool dfa, set[str] sigma) {
  str w = labelOf(l);
  if (w == "") {
    return dfa ? {error("a DFA cannot have λ transitions; declare it as nfa", l.src)} : {};
  }
  if (dfa && size(w) > 1) {
    return {error("a DFA reads one symbol per transition, and <w> has <size(w)>; declare it as nfa", l.src)};
  }
  return outside(toSet(chars(w)), sigma, l.src);
}

loc firstUse(Decl d, str q) = [ n.src | Item i <- d.items, /Name n := i, "<n>" == q ][0];

set[Message] checkMachine(Decl d) {
  bool dfa = d.kind is dfa;
  set[str] sigma = declared(d);
  set[Message] msgs = repeated(d);
  map[tuple[str, str], str] goesTo = ();
  for ((Item) `<Name p> -\> <{Name ","}+ _>` <- d.items, dfa) {
    msgs += error("a DFA cannot have λ transitions; declare it as nfa", p.src);
  }
  for ((Item) `<Name p> -<{Label ","}+ ls>-\> <{Name ","}+ qs>` <- d.items, l <- ls, q <- qs) {
    msgs += checkLabel(l, dfa, sigma);
    tuple[str, str] key = <"<p>", labelOf(l)>;
    if (!dfa || size(key[1]) != 1) {
      continue;
    }
    if (key notin goesTo) {
      goesTo[key] = "<q>";
    } else if (goesTo[key] != "<q>") {
      msgs += error("<p> already goes to <goesTo[key]> with <key[1]>, so this is not a DFA", q.src);
    } else {
      msgs += warning("this transition is repeated", l.src);
    }
  }
  Automaton a = build(d);
  int starts = size({ "<q>" | (Item) `start <{Name ","}+ qs>` <- d.items, q <- qs });
  if (starts == 0) {
    list[str] used = [ "<i.from>" | Item i <- d.items, i is edge || i is jump ] + [ "<n>" | Item i <- d.items, /Name n := i ];
    msgs += error("<d.name> has no start state; add a line such as: start <used == [] ? "q0" : used[0]>", d.name.src);
  } else {
    msgs += { warning("the state <q> cannot be reached from the start", firstUse(d, q)) | q <- a.states - reachable(a).states };
  }
  if (dfa && starts > 1) {
    msgs += error("a DFA has exactly one start state; <d.name> has <starts>", d.name.src);
  }
  if (a.final == {}) {
    msgs += warning("<d.name> has no final states, so it accepts no word", d.name.src);
  }
  return msgs;
}

set[Message] checkRegex(Decl d)
  = repeated(d) + { *outside({"<c>"}, declared(d), c.src) | /Char c := d.re };

set[Message] checkExpr((Expr) `<Name x>`, set[str] defined, set[str] later) {
  if ("<x>" in defined) {
    return {};
  }
  if ("<x>" in later) {
    return {error("<x> is defined further down; move this line below its definition", x.src)};
  }
  return {error("<x> is not defined", x.src)};
}

set[Message] checkExpr(e:(Expr) `<Op op>(<{Expr ","}+ args>)`, set[str] defined, set[str] later) {
  list[Expr] xs = [ x | x <- args ];
  set[Message] msgs = { *checkExpr(x, defined, later) | x <- xs };
  if (size(xs) != arity["<op>"]) {
    msgs += error("<op> takes <arity["<op>"] == 1 ? "one automaton" : "two automata">, not <size(xs)>", e.src);
  }
  return msgs;
}

set[Message] checkWords(Decl d, Env defs) {
  try {
    set[str] sigma = eval(d.subject, defs).alphabet;
    return { error("the symbol <c> of this word is not in the alphabet <braces(sigma)>", w.src)
           | w <- d.words, c <- chars(wordOf(w)), c notin sigma };
  } catch _: {
    return {};
  }
}

bool isDef(Decl d) = d is machine || d is regex || d is let;

set[Message] check(start[Program] p) {
  list[Decl] decls = [ d | d <- p.top.decls ];
  set[str] names = { "<d.name>" | d <- decls, isDef(d) };
  set[str] defined = {};
  set[Message] msgs = {};
  Env defs = env(p);
  for (Decl d <- decls) {
    set[str] later = names - defined;
    if (isDef(d)) {
      str x = "<d.name>";
      if (x in defined) {
        msgs += error("<x> is already defined", d.name.src);
      }
      if (d is machine) {
        msgs += checkMachine(d);
      } else if (d is regex) {
        msgs += checkRegex(d);
      } else {
        msgs += checkExpr(d.expr, defined, later - {x});
      }
      defined += {x};
    } else if (d is check) {
      msgs += checkExpr(d.subject, defined, later) + checkExpr(d.expected, defined, later);
    } else {
      set[Message] found = checkExpr(d.subject, defined, later);
      msgs += found;
      if (d is run && found == {}) {
        msgs += checkWords(d, defs);
      }
    }
  }
  return msgs;
}

bool hasErrors(set[Message] msgs) = any(m <- msgs, m is error);
