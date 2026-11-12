module lang::automata::Ide

import IO;
import lang::automata::Build;
import lang::automata::Check;
import lang::automata::Core;
import lang::automata::Report;
import lang::automata::Syntax;
import lang::automata::View;
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

lrel[loc, Command] buttons(start[Program] p) {
  if (hasErrors(check(p))) {
    return [];
  }
  Env defs = env(p);
  lrel[loc, Command] out = [];
  for (Decl d <- p.top.decls) {
    if (isDef(d)) {
      out += [<d.src, showName(p, "<d.name>", "", title = "Show")>];
    } else if (d is run) {
      out += [<d.src, showExpr(p, d.subject, wordOf([ w | w <- d.words ][0]), title = "Show")>];
    } else if (d is show) {
      out += [<d.src, showExpr(p, d.subject, "", title = "Show")>];
    } else if (just(str w) := counterexample(eval(d.subject, defs), eval(d.expected, defs))) {
      out += [<d.src, showExpr(p, d.subject, w, title = "Show counterexample")>];
    }
  }
  return out;
}

list[InlayHint] hints(start[Program] p) {
  if (hasErrors(check(p))) {
    return [];
  }
  Env defs = env(p);
  list[InlayHint] out = [];
  for (Decl d <- p.top.decls) {
    if (d is let) {
      out += [hint(d.src, "  <describe(defs["<d.name>"])>", \type(), atEnd = true)];
    } else if (d is run) {
      out += [ hint(w.src, " <verdict(eval(d.subject, defs), wordOf(w))>", \type(), atEnd = true) | w <- d.words ];
    } else if (d is check) {
      str result = compare("<d.subject>", "<d.expected>", eval(d.subject, defs), eval(d.expected, defs));
      out += [hint(d.src, "  <result>", \type(), atEnd = true)];
    }
  }
  return out;
}

value execute(showName(start[Program] p, str name, str word)) {
  showInteractiveContent(view(name, env(p)[name], word = word));
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
