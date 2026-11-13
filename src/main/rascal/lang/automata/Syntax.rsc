module lang::automata::Syntax

start syntax Program = Decl* decls;

syntax Decl
  = machine: Kind kind Name name Over? over Item* items
  | regex: "regex" Name name Over? over "=" Regex re
  | let: Name name "=" Expr expr
  | run: "run" Expr subject {Word ","}+ words
  | show: "show" Expr subject
  | check: "check" Expr subject "=" Expr expected
  | pda: "pda" Name name PItem* moves
  | tm: "tm" Name name TItem* parts
  | grammar: "grammar" Name name Rule* rules
  ;

syntax Rule = Name lhs "-\>" {Alt "|"}+ alts;

syntax Alt
  = none: Eps
  | some: Tok+ toks
  ;

lexical Tok
  = ([A-Za-z0-9_] !<< [A-Za-z0-9_] [A-Za-z0-9_]* !>> [A-Za-z0-9_]) \ Keywords
  | [()+*/=\[\]{}.,;:\<!?&%$#@~^]
  | [\>] !<< [\-] !>> [\>]
  | "\'" ![\'\n]+ "\'"
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

syntax PItem
  = initial: "start" Name state
  | final: "final" {Name ","}+ states
  | move: Name from "-" Read read "," Stack op "-\>" Name to
  ;

lexical Read = Sym | Eps;

syntax Stack
  = push: "push" "(" Sym e ")"
  | pop: "pop" "(" Sym e ")"
  | ignore: "ignore"
  | skip: "skip" "(" Sym e ")"
  | changeTop: "changeTop" "(" Sym e "," Sym f ")"
  | pushOn: "pushOn" "(" Sym e "," Sym f ")"
  ;

syntax TItem
  = initial: "start" Name state
  | does: Name name ":" Code code
  | edge: Name from "-" Cond cond "-\>" Name to
  | jump: Name from "-\>" Name to
  ;

syntax Cond
  = among: Not? not {Cell ","}+ cells
  | bind: Var var "in" Not? not "{" {Cell ","}+ cells "}"
  ;

lexical Not = "!";

lexical Code = {Instr Gap}+;

lexical Instr
  = right: "R"
  | left: "L"
  | rightTo: "R[" Not? not Cell cell "]"
  | leftTo: "L[" Not? not Cell cell "]"
  | write: "W[" Cell cell "]"
  | call: "C[" Name machine "]"
  ;

lexical Cell = Sym | Var;

lexical Var = "$" [a-z];

lexical Sym
  = [A-Za-z0-9$#+*/=.;]
  | "\'" ![\'\n] "\'"
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
  = "\"" ![\"\n]* "\""
  | Eps
  ;

keyword Keywords
  = "dfa" | "nfa" | "regex" | "over" | "start" | "final" | "run" | "show" | "check"
  | "determinize" | "minimize" | "complement" | "union" | "intersection" | "difference"
  | "rename" | "lambda" | "pda" | "tm" | "in" | "push" | "pop" | "ignore" | "skip" | "changeTop" | "pushOn" | "grammar"
  ;

layout Layout = Space* !>> [\ \t\n\r] !>> "//";

lexical Space
  = [\ \t\n\r]
  | @category="comment" "//" ![\n]* $
  ;
