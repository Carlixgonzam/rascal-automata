module lang::automata::IdeTests

import IO;
import lang::automata::Ide;
import List;
import ParseTree;
import Set;
import util::LanguageServer;

list[loc] files = [|cwd:///examples/course.auto|, |cwd:///examples/errors.auto|, |cwd:///examples/pda.auto|, |cwd:///examples/turing.auto|, |cwd:///examples/grammar.auto|];

Tree parseWith(set[LanguageService] services, loc file) {
  for (parsing(Tree (str, loc) f) <- services) {
    return f(readFile(file), file);
  }
  throw "no parser";
}

test bool everyServiceRuns() {
  set[LanguageService] services = contributions();
  for (loc file <- files) {
    Tree t = parseWith(services, file);
    for (analysis(Summary (loc, Tree) f) <- services) {
      f(file, t);
    }
    for (documentSymbol(list[DocumentSymbol] (Tree) f) <- services) {
      f(t);
    }
    for (codeLens(lrel[loc, Command] (Tree) f) <- services) {
      f(t);
    }
    for (inlayHint(list[InlayHint] (Tree) f) <- services) {
      f(t);
    }
  }
  return true;
}

test bool courseGivesButtonsAndHints() {
  set[LanguageService] services = contributions();
  Tree t = parseWith(services, files[0]);
  int buttons = ( 0 | it + size(f(t)) | codeLens(lrel[loc, Command] (Tree) f) <- services );
  int hints = ( 0 | it + size(f(t)) | inlayHint(list[InlayHint] (Tree) f) <- services );
  return buttons == 12 && hints == 14;
}

test bool errorsAreReported() {
  set[LanguageService] services = contributions();
  Tree t = parseWith(services, files[1]);
  int messages = ( 0 | it + size(f(files[1], t).messages) | analysis(Summary (loc, Tree) f) <- services );
  return messages == 10;
}

test bool resultsSurviveAnErrorElsewhere() {
  set[LanguageService] services = contributions();
  str text = "dfa P\n  start a\n  final a\n  a -0-\> a\nrun P \"00\"\nrun P \"02\"\nM = minimize(P)\n";
  Tree t = [ f(text, |memory:///s.auto|) | parsing(Tree (str, loc) f) <- services ][0];
  int hints = ( 0 | it + size(f(t)) | inlayHint(list[InlayHint] (Tree) f) <- services );
  int buttons = ( 0 | it + size(f(t)) | codeLens(lrel[loc, Command] (Tree) f) <- services );
  return hints == 2 && buttons == 3;
}
