module lang::automata::Build

import lang::automata::Core;
import lang::automata::Stack;
import lang::automata::Syntax;
import lang::automata::Turing;
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

str unquote(/^\'<c:.>\'$/) = c;
default str unquote(str s) = s;

str readOf(Read r) = "<r>" in {"λ", "ε"} ? "" : unquote("<r>");

str sym(Sym s) = unquote("<s>");

tuple[str top, list[str] put] effect((Stack) `push(<Sym e>)`) = <"", [sym(e)]>;
tuple[str top, list[str] put] effect((Stack) `pop(<Sym e>)`) = <sym(e), []>;
tuple[str top, list[str] put] effect((Stack) `ignore`) = <"", []>;
tuple[str top, list[str] put] effect((Stack) `skip(<Sym e>)`) = <sym(e), [sym(e)]>;
tuple[str top, list[str] put] effect((Stack) `changeTop(<Sym e>, <Sym f>)`) = <sym(e), [sym(f)]>;
tuple[str top, list[str] put] effect((Stack) `pushOn(<Sym e>, <Sym f>)`) = <sym(f), [sym(e), sym(f)]>;

Pda buildPda(Decl d) {
  Moves delta = { <"<p>", readOf(r), effect(s).top, effect(s).put, "<q>", "<r>, <s>">
                | (PItem) `<Name p> -<Read r>, <Stack s>-\> <Name q>` <- d.moves };
  list[str] starts = [ "<q>" | (PItem) `start <Name q>` <- d.moves ];
  set[str] final = { "<q>" | (PItem) `final <{Name ","}+ qs>` <- d.moves, q <- qs };
  return pushdown({ r | <_, r, _, _, _, _> <- delta, r != "" }, toSet(starts) + final + delta<from> + delta<to>,
                  starts == [] ? "" : starts[0], final, delta);
}

Move instr(/^R$/) = moveRight("", false);
Move instr(/^L$/) = moveLeft("", false);
Move instr(/^R\[<n:!?><x:.+>\]$/) = moveRight(unquote(x), n == "!");
Move instr(/^L\[<n:!?><x:.+>\]$/) = moveLeft(unquote(x), n == "!");
Move instr(/^W\[<x:.+>\]$/) = writes(unquote(x));
Move instr(/^C\[<x:.+>\]$/) = calls(x);

Guard guardOf(Cond c) = inSet({ unquote("<x>") | x <- c.cells }, "<c.not>" == "!", c is bind ? "<c.var>" : "");

Tm buildTm(Decl d) {
  map[str, list[Move]] code = ( "<x>" : [ instr("<i>")[text = "<i>"] | /Instr i := c ] | (TItem) `<Name x>: <Code c>` <- d.parts );
  Edges edges = { <"<p>", guardOf(k), "<q>", "<k>"> | (TItem) `<Name p> -<Cond k>-\> <Name q>` <- d.parts }
              + { <"<p>", always(), "<q>", ""> | (TItem) `<Name p> -\> <Name q>` <- d.parts };
  list[str] starts = [ "<q>" | (TItem) `start <Name q>` <- d.parts ];
  return turing(starts == [] ? "" : starts[0], code, edges);
}

map[str, Pda] pdas(start[Program] p) = ( "<d.name>" : buildPda(d) | d <- p.top.decls, d is pda );

map[str, Tm] tms(start[Program] p) = ( "<d.name>" : buildTm(d) | d <- p.top.decls, d is tm );

set[str] statesOf(Tm m) = m.code<0> + m.edges<from> + m.edges<to> + {m.initial};
