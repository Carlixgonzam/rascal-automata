module lang::automata::Main

import Exception;
import IO;
import lang::automata::Build;
import lang::automata::Check;
import lang::automata::Report;
import lang::automata::Syntax;
import List;
import Message;
import ParseTree;

str pos(loc l) = "<l.scheme == "cwd" ? l.path[1..] : l.path>:<l.begin.line>:<l.begin.column + 1>";

str level(error(_, _)) = "error";
str level(warning(_, _)) = "warning";
default str level(Message _) = "info";

bool runAll(start[Program] p) {
  set[Message] msgs = check(p);
  for (<_, m> <- sort([ <m.at.offset, m> | m <- msgs ])) {
    println("<pos(m.at)>: <level(m)>: <m.msg>");
  }
  if (hasErrors(msgs)) {
    return false;
  }
  Env defs = env(p);
  bool ok = true;
  for (Decl d <- p.top.decls) {
    if (d is run) {
      for (w <- d.words) {
        println("run <d.subject> <w>: <outcomeOf(p, d.subject, wordOf(w))>");
      }
    } else if (d is check) {
      println("check <d.subject> = <d.expected>: <compare("<d.subject>", "<d.expected>", eval(d.subject, defs), eval(d.expected, defs))>");
      ok = ok && same(eval(d.subject, defs), eval(d.expected, defs));
    } else if (d is show) {
      list[str] rows = showOf(p, d.subject);
      println("show <d.subject>: <rows[0]>");
      for (row <- rows[1..]) {
        println("  <row>");
      }
    }
  }
  return ok;
}

bool runFile(loc file) {
  try {
    return runAll(load(file));
  } catch ParseError(loc l): {
    println("<pos(l)>: error: the text does not follow the syntax of the language");
    return false;
  }
}

int main(list[str] args) {
  if (args == []) {
    println("usage: automata FILE.auto ...");
    return 2;
  }
  list[bool] results = [ runFile(arg[0] == "/" ? |file:///| + arg : |cwd:///| + arg) | arg <- args ];
  return false in results ? 1 : 0;
}
