module lang::automata::Syntax

start syntax Program = Decl* decls;

syntax Decl
  = machine: Kind kind Name name Over? over Item* items
  | regex: "regex" Name name Over? over "=" Regex re
  | let: Name name "=" Expr expr
  | run: "run" Expr subject {Word ","}+ words
  | show: "show" Expr subject
  | check: "check" Expr subject "=" Expr expected
  ;

syntax Kind
  = dfa: "dfa"
  | nfa: "nfa"
  ;

syntax Over = "over" "{" {Symbol ","}+ symbols "}";

syntax Item
  = initial: "start" {Name ","}+ states
  | final: "final" {Name ","}+ states
  | edge: Name from "-" {Label ","}+ labels "-\>" {Name ","}+ to
  | jump: Name from "-\>" {Name ","}+ to
  ;

syntax Expr
  = ref: Name name
  | call: Op op "(" {Expr ","}+ args ")"
  ;

syntax Op
  = determinize: "determinize"
  | minimize: "minimize"
  | complement: "complement"
  | union: "union"
  | intersection: "intersection"
  | difference: "difference"
  | rename: "rename"
  ;

lexical Regex
  = symbol: Char symbol
  | eps: Eps
  | zero: "∅"
  | group: "(" Gap Regex inner Gap ")"
  > star: Regex arg "*"
  | plus: Regex arg "+"
  | optional: Regex arg "?"
  > left cat: Regex lhs Gap Regex rhs
  > left alt: Regex lhs Gap "|" Gap Regex rhs
  ;

lexical Gap = [\ \t]* !>> [\ \t];

lexical Char = [A-Za-z0-9];

lexical Name = ([A-Za-z0-9_] !<< [A-Za-z0-9_] [A-Za-z0-9_]* !>> [A-Za-z0-9_]) \ Keywords;

lexical Symbol = [A-Za-z0-9] !>> [A-Za-z0-9];

lexical Label
  = Lambda
  | ([A-Za-z0-9] !<< [A-Za-z0-9] [A-Za-z0-9]* !>> [A-Za-z0-9]) \ Keywords
  ;

lexical Lambda = Eps | "lambda";

lexical Eps = "λ" | "ε";

lexical Word
  = "\"" [A-Za-z0-9]* "\""
  | Eps
  ;

keyword Keywords
  = "dfa" | "nfa" | "regex" | "over" | "start" | "final" | "run" | "show" | "check"
  | "determinize" | "minimize" | "complement" | "union" | "intersection" | "difference"
  | "rename" | "lambda"
  ;

layout Layout = Space* !>> [\ \t\n\r] !>> "//";

lexical Space
  = [\ \t\n\r]
  | @category="comment" "//" ![\n]* $
  ;
