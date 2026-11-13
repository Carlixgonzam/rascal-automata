module lang::automata::Ide

import Content;
import IO;
import lang::automata::Build;
import lang::automata::Check;
import lang::automata::Core;
import lang::automata::Report;
import lang::automata::Syntax;
import lang::automata::View;
import Location;
import Message;
import ParseTree;
import util::IDEServices;
import util::LanguageServer;
import util::Maybe;
import util::Reflective;

data Command
  = showName(start[Program] p, str name, str word)
  | showExpr(start[Program] p, Expr e, str word)
  ;

set[LanguageService] contributions() = {
  parsing(parser(#start[Program]), usesSpecialCaseHighlighting = false),
  analysis(summarize, providesImplementations = false),
  documentSymbol(outline),
  codeLens(buttons),
  inlayHint(hints),
  execution(execute)
};

Summary summarize(loc l, start[Program] p) {
  map[str, loc] defs = ( "<d.name>" : d.name.src | d <- p.top.decls, isDef(d) );
  return summary(l,
    messages = { <m.at, m> | m <- check(p) },
    definitions = { <x.src, defs["<x>"]> | /(Expr) `<Name x>` := p, "<x>" in defs });
}

DocumentSymbolKind kind(Decl d) = d is regex ? \string() : (d is let ? \function() : \class());

list[DocumentSymbol] outline(start[Program] p)
  = [ symbol("<d.name>", kind(d), d.src, selection = d.name.src) | d <- p.top.decls, isDef(d) ];

bool hit(Decl d, set[Message] msgs) = any(m <- msgs, m is error, isContainedIn(m.at, d.src));

bool uses(Decl d, set[str] names) = any(/(Expr) `<Name x>` := d, "<x>" in names);

list[Decl] healthy(start[Program] p) {
  set[Message] msgs = check(p);
  set[str] broken = { "<d.name>" | d <- p.top.decls, isDef(d), hit(d, msgs) };
  solve (broken) {
    broken += { "<d.name>" | d <- p.top.decls, isDef(d), uses(d, broken) };
  }
  return [ d | d <- p.top.decls, !hit(d, msgs), !uses(d, broken), !(isDef(d) && "<d.name>" in broken) ];
}

lrel[loc, Command] buttons(start[Program] p) {
  Env defs = env(p);
  lrel[loc, Command] out = [];
  for (Decl d <- healthy(p)) {
    if (isDef(d)) {
      out += [<d.src, showName(p, "<d.name>", "", title = "Show")>];
    } else if (d is run) {
      out += [<d.src, showIt(p, d.subject, wordOf([ w | w <- d.words ][0]))>];
    } else if (d is show) {
      out += [<d.src, showIt(p, d.subject, "")>];
    } else if (just(str w) := counterexample(eval(d.subject, defs), eval(d.expected, defs))) {
      out += [<d.src, showExpr(p, d.subject, w, title = "Show counterexample")>];
    }
  }
  return out;
}

list[InlayHint] hints(start[Program] p) {
  Env defs = env(p);
  list[InlayHint] out = [];
  for (Decl d <- healthy(p)) {
    if (d is let) {
      out += [hint(d.src, "  <describe(defs["<d.name>"])>", \type(), atEnd = true)];
    } else if (d is run) {
      out += [ hint(w.src, " <outcomeOf(p, d.subject, wordOf(w))>", \type(), atEnd = true) | w <- d.words ];
    } else if (d is check) {
      str result = compare("<d.subject>", "<d.expected>", eval(d.subject, defs), eval(d.expected, defs));
      out += [hint(d.src, "  <result>", \type(), atEnd = true)];
    }
  }
  return out;
}

Command showIt(start[Program] p, e:(Expr) `<Name x>`, str word) = showName(p, "<x>", word, title = "Show");
default Command showIt(start[Program] p, Expr e, str word) = showExpr(p, e, word, title = "Show");

Content viewOf(start[Program] p, str x, str w) {
  if (x in grammars(p)) {
    return view(x, grammars(p)[x], word = w);
  }
  if (x in pdas(p)) {
    return view(x, pdas(p)[x], word = w);
  }
  if (x in tms(p)) {
    return view(tms(p), x, word = w);
  }
  return view(x, env(p)[x], word = w);
}

value execute(showName(start[Program] p, str name, str word)) {
  showInteractiveContent(viewOf(p, name, word));
  return ("result": true);
}

value execute(showExpr(start[Program] p, Expr e, str word)) {
  showInteractiveContent(view("<e>", eval(e, env(p)), word = word));
  return ("result": true);
}

int main() {
  unregisterLanguage("Automata", {"auto"});
  registerLanguage(language(
    getProjectPathConfig(resolveLocation(|cwd:///|), mode = interpreter()),
    "Automata", {"auto"}, "lang::automata::Ide", "contributions"));
  return 0;
}
