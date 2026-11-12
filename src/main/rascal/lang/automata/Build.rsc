module lang::automata::Build

import lang::automata::Core;
import lang::automata::Syntax;
import ParseTree;

str labelOf(Label l) = "<l>" in {"λ", "ε", "lambda"} ? "" : "<l>";

str wordOf(Word w) = "<w>" in {"λ", "ε"} ? "" : "<w>"[1..-1];

set[str] declared(Decl d) = { "<c>" | v <- d.over, c <- v.symbols };

Delta edges(Decl d)
  = { <"<p>", labelOf(l), "<q>"> | (Item) `<Name p> -<{Label ","}+ ls>-\> <{Name ","}+ qs>` <- d.items, l <- ls, q <- qs }
  + { <"<p>", "", "<q>"> | (Item) `<Name p> -\> <{Name ","}+ qs>` <- d.items, q <- qs };

set[str] used(Decl d) = d is regex ? { "<c>" | /Char c := d.re } : { c | <_, l, _> <- edges(d), c <- chars(l) };

set[str] alphabetOf(Decl d) = declared(d) == {} ? used(d) : declared(d);

Automaton build(Decl d) {
  set[str] initial = { "<q>" | (Item) `start <{Name ","}+ qs>` <- d.items, q <- qs };
  set[str] final = { "<q>" | (Item) `final <{Name ","}+ qs>` <- d.items, q <- qs };
  Delta delta = edges(d);
  return automaton(alphabetOf(d), initial + final + delta<from> + delta<to>, initial, final, delta);
}

Re toRe(Regex r) {
  switch (r) {
    case (Regex) `∅`: return Re::zero();
    case (Regex) `(<Gap _><Regex x><Gap _>)`: return toRe(x);
    case (Regex) `<Regex x>*`: return star(toRe(x));
    case (Regex) `<Regex x>+`: return cat(toRe(x), star(toRe(x)));
    case (Regex) `<Regex x>?`: return alt(toRe(x), eps());
    case (Regex) `<Regex x><Gap _><Regex y>`: return cat(toRe(x), toRe(y));
    case (Regex) `<Regex x><Gap _>|<Gap _><Regex y>`: return alt(toRe(x), toRe(y));
  }
  return r is eps ? eps() : sym("<r>");
}

alias Env = map[str, Automaton];

Automaton eval((Expr) `<Name x>`, Env defs) = defs["<x>"];
Automaton eval((Expr) `determinize(<Expr e>)`, Env defs) = determinize(eval(e, defs));
Automaton eval((Expr) `minimize(<Expr e>)`, Env defs) = minimize(eval(e, defs));
Automaton eval((Expr) `complement(<Expr e>)`, Env defs) = complement(eval(e, defs));
Automaton eval((Expr) `rename(<Expr e>)`, Env defs) = rename(eval(e, defs));
Automaton eval((Expr) `union(<Expr x>, <Expr y>)`, Env defs) = product(eval(x, defs), eval(y, defs), "union");
Automaton eval((Expr) `intersection(<Expr x>, <Expr y>)`, Env defs) = product(eval(x, defs), eval(y, defs), "intersection");
Automaton eval((Expr) `difference(<Expr x>, <Expr y>)`, Env defs) = product(eval(x, defs), eval(y, defs), "difference");

Env env(start[Program] p) {
  Env defs = ();
  for (Decl d <- p.top.decls) {
    try {
      if (d is machine) {
        defs["<d.name>"] = build(d);
      } else if (d is regex) {
        defs["<d.name>"] = thompson(toRe(d.re), alphabetOf(d));
      } else if (d is let) {
        defs["<d.name>"] = eval(d.expr, defs);
      }
    } catch _: {
      ;
    }
  }
  return defs;
}

start[Program] load(loc file) = parse(#start[Program], file);

start[Program] load(str text, loc origin) = parse(#start[Program], text, origin);
