module lang::automata::Tests

import lang::automata::Build;
import lang::automata::Check;
import lang::automata::Core;
import lang::automata::Syntax;
import lang::automata::View;
import Message;
import ParseTree;
import Set;
import util::Maybe;

map[str, Automaton] defsOf(str text) = env(load(text, |memory:///test.auto|));

set[str] errors(str text) = { msg.msg | msg <- check(load(text, |memory:///test.auto|)), msg is error };

Maybe[str] diffOf(str text, str a, str b) {
  map[str, Automaton] defs = defsOf(text);
  return counterexample(defs[a], defs[b]);
}

str course = "dfa Has01
             '  start Just1
             '  final Read01
             '  Just1 -1-\> Just1
             '  Just1 -0-\> Read0
             '  Read0 -0-\> Read0
             '  Read0 -1-\> Read01
             '  Read01 -0, 1-\> Read01
             'nfa End0Or1
             '  start A
             '  final D
             '  A -λ-\> B
             '  A -λ-\> C
             '  B -1-\> D
             '  C -0, 1-\> C
             '  C -0-\> D
             'regex Has01Re = (0 | 1)*01(0 | 1)*
             'regex End0Or1Re = (0 | 1)*0 | 1
             'nfa Blocks
             '  start E
             '  final E
             '  E -ab, aab, aba-\> E
             'regex BlocksRe = (ab | aab | aba)*
             'nfa SlideBlocks
             '  start E
             '  final C
             '  A -λ-\> C
             '  A -a-\> D
             '  D -λ-\> C
             '  C -λ-\> E
             '  E -a, b-\> E
             '  E -b-\> A
             'nfa Slide59
             '  start 0
             '  final 1, 2, 3
             '  0 -0, 1-\> 0
             '  0 -0-\> 1
             '  0 -1-\> 2
             '  2 -0, 1-\> 3
             'nfa Fixed59
             '  start 0, 4
             '  final 1, 3, 4
             '  0 -0, 1-\> 0
             '  0 -0-\> 1
             '  0 -1-\> 2
             '  2 -0, 1-\> 3
             '  4 -1-\> 3
             'regex Not01 = λ | 0 | 1 | (0 | 1)*(0 | 1(0 | 1))
             'regex Slide59Re = 0 | 1 | (0 | 1)*(0 | 1(0 | 1))
             'regex Odd0Even1 = 0((0 | 1)(0 | 1))* | 1(0 | 1)((0 | 1)(0 | 1))*
             'regex Slide7 = (0((0 | 1)(0 | 1))*) | (1(0 | 1)*)
             'dfa Odd
             '  start E
             '  final O
             '  E -0, 1-\> O
             '  O -0, 1-\> E
             'dfa Even1
             '  start E
             '  final E
             '  E -0-\> E
             '  E -1-\> O
             '  O -0-\> O
             '  O -1-\> E
             'Union = union(Odd, Even1)
             'Inter = intersection(Odd, Even1)
             'Diff = difference(Odd, Even1)
             'Min = minimize(End0Or1)
             'Twice = complement(complement(Has01))
             '";

test bool noErrors() = errors(course) == {};

test bool runDfa() {
  Automaton a = defsOf(course)["Has01"];
  return accepts(a, "01") && accepts(a, "1101") && !accepts(a, "") && !accepts(a, "1110");
}

test bool closureOfA() = closure(defsOf(course)["End0Or1"], {"A"}) == {"A", "B", "C"};

test bool subsets() {
  Automaton dfa = determinize(defsOf(course)["End0Or1"]);
  return dfa.initial == {"{A, B, C}"} && <"{A, B, C}", "0", "{C, D}"> in dfa.delta && <"{C, D}", "1", "{C}"> in dfa.delta;
}

test bool reMatchesDfa() = diffOf(course, "Has01", "Has01Re") == nothing();

test bool reMatchesNfa() = diffOf(course, "End0Or1", "End0Or1Re") == nothing();

test bool wordLabels() = diffOf(course, "Blocks", "BlocksRe") == nothing();

test bool slideBlocks() = diffOf(course, "SlideBlocks", "BlocksRe") == just("") && accepts(defsOf(course)["SlideBlocks"], "b");

test bool slide59() = diffOf(course, "Slide59", "Not01") == just("") && accepts(defsOf(course)["Slide59"], "01");

test bool fixed59() = diffOf(course, "Fixed59", "Not01") == nothing();

test bool slide59Re() = diffOf(course, "Slide59Re", "Not01") == just("");

test bool slide7() = diffOf(course, "Slide7", "Odd0Even1") == just("1");

test bool products() {
  map[str, Automaton] defs = defsOf(course);
  list[str] names = ["Union", "Inter", "Diff"];
  return [ accepts(defs[name], "01011100") | name <- names ] == [true, false, false]
      && [ accepts(defs[name], "1101001") | name <- names ] == [true, true, false]
      && [ accepts(defs[name], "11110100") | name <- names ] == [false, false, false];
}

test bool minSame() = diffOf(course, "Min", "End0Or1") == nothing();

test bool minSize() = size(defsOf(course)["Min"].states) == 3;

test bool twice() = diffOf(course, "Twice", "Has01") == nothing();

test bool renamed() {
  Automaton dfa = determinize(defsOf(course)["End0Or1"]);
  Automaton r = rename(dfa);
  return counterexample(dfa, r) == nothing() && r.initial == {"q0"};
}

test bool shortest() {
  str text = "regex A = (0 | 1)*00(0 | 1)*
             'regex B = 000*";
  return diffOf(text, "A", "B") == just("001");
}

test bool partialDiff() {
  str text = "dfa Odd
             '  start E
             '  final O
             '  E -0, 1-\> O
             '  O -0, 1-\> E
             'dfa Zeros
             '  start Z
             '  final Z
             '  Z -0-\> Z
             'D = difference(Odd, Zeros)";
  Automaton d = defsOf(text)["D"];
  return accepts(d, "1") && !accepts(d, "0");
}

test bool notDfa() {
  str text = "dfa X
             '  start P
             '  final Q
             '  P -0-\> Q
             '  P -0-\> P
             '";
  return errors(text) == {"P already goes to Q with 0, so this is not a DFA"};
}

test bool lambdaDfa() {
  str text = "dfa X
             '  start P
             '  final Q
             '  P -λ-\> Q
             '";
  return errors(text) == {"a DFA cannot have λ transitions; declare it as nfa"};
}

test bool badSymbol() = errors("regex R over {a, b} = a(c | b)*") == {"the symbol c is not in the alphabet {a, b}"};

test bool undefined() = errors("M = minimize(Missing)") == {"Missing is not defined"};

test bool badArity() {
  str text = "dfa X
             '  start P
             '  final P
             '  P -0-\> P
             'U = union(X)";
  return errors(text) == {"union takes two automata, not 1"};
}

test bool lambdaLoop() {
  Automaton a = automaton({"1"}, {"A", "B", "C"}, {"A"}, {"C"}, {<"A", "", "B">, <"B", "", "A">, <"B", "1", "C">});
  return accepts(a, "1") && !accepts(a, "") && !accepts(a, "11");
}

str easy = "nfa N   // ends in 0 or is 1
           '  start A
           '  final D
           '  A -\> B, C
           '  B -1-\> D
           '  C -0,1-\> C
           '  C -0-\> D
           'regex R = (0|1)*0 | 1
           'check N = R
           'run N λ, \"10\"
           '";

test bool easySyntax() = errors(easy) == {} && defsOf(easy)["N"].alphabet == {"0", "1"} && diffOf(easy, "N", "R") == nothing();

test bool lambdaWord() = !accepts(defsOf(easy)["N"], wordOf([ w | /Word w := load(easy, |memory:///e.auto|) ][0]));

test bool twoTargetsInDfa() {
  str text = "dfa X
             '  start P
             '  final Q
             '  P -0-\> P, Q
             '";
  return errors(text) == {"P already goes to P with 0, so this is not a DFA"};
}

test bool jumpInDfa() {
  str text = "dfa X
             '  start P
             '  final Q
             '  P -\> Q
             '";
  return errors(text) == {"a DFA cannot have λ transitions; declare it as nfa"};
}

test bool noStart() {
  str text = "dfa X
             '  final Q
             '  P -0-\> Q
             '";
  return errors(text) == {"X has no start state; add a line such as: start P"};
}

test bool wordOutsideAlphabet() = "the symbol 2 of this word is not in the alphabet {0, 1}" in errors(easy + "run N \"2\"\n");

list[map[str, value]] stepsOf(str name, str word) {
  if (list[map[str, value]] steps := runOf(defsOf(course)[name], word)["steps"]) {
    return steps;
  }
  return [];
}

test bool traceOfEnd0Or1() {
  list[map[str, value]] s = stepsOf("End0Or1", "10");
  return s[0]["states"] == ["A", "B", "C"]
      && s[0]["notes"] == ["start in A", "A: λ leads to B, C"]
      && s[0]["jumps"] == ["A→B", "A→C"]
      && s[1]["moves"] == ["B→D", "C→C"]
      && s[1]["notes"] == ["A: no move on 1", "B: 1 leads to D", "C: 1 leads to C"]
      && s[2]["notes"] == ["C: 0 leads to C, D", "D: no move on 0", "D is final, so the word is accepted"];
}

test bool traceInsideALabel() {
  list[map[str, value]] s = stepsOf("Blocks", "ab");
  return s[1]["states"] == [] && s[1]["moves"] == ["E→E"]
      && s[2]["notes"] == ["E -aab-\> E (a read): no move on b", "E -ab-\> E (a read): b leads to E",
                           "E -aba-\> E (a read): b leads to E -aba-\> E (ab read)", "E is final, so the word is accepted"];
}

test bool traceOfEmptyWord() = stepsOf("Has01", "")[0]["notes"] == ["start in Just1", "no active state is final, so the word is rejected"];
