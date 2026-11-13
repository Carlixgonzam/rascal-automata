module lang::automata::GoldTests

import IO;
import lang::automata::Build;
import lang::automata::Stack;
import lang::automata::Turing;
import List;
import String;

str kind(/left end/) = "left";
str kind(/last cell/) = "right";
str kind(/steps/) = "steps";
str kind(/two transitions/) = "two";
default str kind(str why) = "other: <why>";

str outcome(Run r) = failed(str why) := r.result ? "error <kind(why)>" : "ok <r.head> <tapeText(r)>";

list[str] mismatches() {
  map[str, Tm] machines = tms(load(|cwd:///test/turing.auto|));
  list[str] bad = [];
  for (str line <- readFileLines(|cwd:///test/turing-gold.txt|), [name, word, *rest] := split(" ", line)) {
    str got = outcome(simulate(machines, name, word == "λ" ? "" : word));
    if (got != intercalate(" ", rest)) {
      bad += ["<name> <word>: GOLD gives <intercalate(" ", rest)>, we give <got>"];
    }
  }
  return bad;
}

test bool turingMachinesBehaveLikeGold() {
  list[str] bad = mismatches();
  for (str b <- take(10, bad)) {
    println(b);
  }
  return bad == [];
}

list[str] pdaMismatches() {
  map[str, Pda] machines = pdas(load(|cwd:///test/pda.auto|));
  list[str] bad = [];
  for (str line <- readFileLines(|cwd:///test/pda-gold.txt|), [name, word, expected] := split(" ", line)) {
    bool got = search(machines[name], word == "λ" ? "" : word).accepted;
    if ("<got>" != expected) {
      bad += ["<name> <word>: GOLD gives <expected>, we give <got>"];
    }
  }
  return bad;
}

test bool pushdownAutomataBehaveLikeGold() {
  list[str] bad = pdaMismatches();
  for (str b <- take(10, bad)) {
    println(b);
  }
  return bad == [];
}
