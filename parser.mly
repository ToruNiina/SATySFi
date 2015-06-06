%{
  open Types

  let rec append_argument_list arglsta arglstb =
    match arglsta with
    | EndOfArgument -> arglstb
    | ArgumentCons(arg, arglstl) ->
        ArgumentCons(arg, (append_argument_list arglstl arglstb))

  let rec append_argument_variable_list avlsta avlstb =
    match avlsta with
    | EndOfArgumentVariable -> avlstb
    | ArgumentVariableCons(av, avlstl) ->
        ArgumentVariableCons(av, (append_argument_variable_list avlstl avlstb))

  let parse_error msg =
    print_string ("! [ERROR IN PARSER] " ^ msg ^ "\n")

%}
%token <Types.var_name> NUMVAR
%token <Types.var_name> STRVAR
%token <string> NUMCONST
%token <string> CHAR
%token SPACE
%token BREAK
%token <Types.ctrlseq_name> CTRLSEQ
%token <Types.id_name> IDNAME
%token <Types.class_name> CLASSNAME
%token END
%token LAMBDA ARROW
%token LET IN DEFEQ
%token IF THEN ELSE
%token EOI
%token LPAREN RPAREN
%token TIMES DIVIDES
%token MOD
%token PLUS MINUS
%token EQ NEQ GEQ LEQ GT LT
%token LNOT
%token LAND
%token LOR
%token CONCAT
%token OPENQT CLOSEQT
%token OPENSTR CLOSESTR
%token OPENNUM CLOSENUM
%token BGRP EGRP

%token IGNORED

%nonassoc LET DEFEQ IN
%nonassoc IF THEN ELSE
%left LOR
%left LAND
%nonassoc LNOT
%left EQ NEQ
%left GEQ LEQ GT LT
%left PLUS
%right MINUS
%left TIMES
%right MOD DIVIDES
%nonassoc NUMVAR
%nonassoc LPAREN RPAREN

%start main
%type <Types.abstract_tree> main
%type <Types.abstract_tree> nxlor
%type <Types.abstract_tree> nxland
%type <Types.abstract_tree> nxcomp
%type <Types.abstract_tree> nxconcat
%type <Types.abstract_tree> nxlplus
%type <Types.abstract_tree> nxltimes
%type <Types.abstract_tree> nxrplus
%type <Types.abstract_tree> nxrtimes
%type <Types.abstract_tree> nxun
%type <Types.abstract_tree> nxapp
%type <Types.abstract_tree> nxbot
%type <Types.abstract_tree> sxblock
%type <Types.abstract_tree> sxbot
%type <Types.argument_cons> narg
%type <Types.argument_cons> sarg
%type <Types.argument_cons> sargsub
%type <Types.argument_variable_cons> nargvar
%type <Types.argument_variable_cons> sargvar

%%

main:
  | nxlet EOI { $1 }
;
nxlet:
  | LET STRVAR DEFEQ nxlet IN nxlet { Types.LetStrIn($2, $4, $6) }
  | LET NUMVAR nargvar sargvar DEFEQ nxlet IN nxlet {
        let argcons = (append_argument_variable_list $3 $4) in
          match argcons with
          | EndOfArgumentVariable -> Types.LetNumIn($2, $6, $8)
          | _ -> Types.LetNumIn($2, Types.LambdaAbstract(argcons, $6), $8)
      }
  | LET CTRLSEQ nargvar sargvar DEFEQ nxlet IN nxlet {
        let argcons = (append_argument_variable_list $3 $4) in
          Types.LetNumIn($2, Types.LambdaAbstract(argcons, $6), $8)
      }
  | nxif { $1 }
;
nxif:
  | IF nxif THEN nxif ELSE nxif { Types.IfThenElse($2, $4, $6) }
  | nxlambda { $1 }
;
nxlambda:
  | LAMBDA nargvar sargvar ARROW nxlor {
        Types.LambdaAbstract((append_argument_variable_list $2 $3), $5)
      }
  | nxlor { $1 }
;
nargvar:
  | NUMVAR nargvar { Types.ArgumentVariableCons($1, $2) }
  | { Types.EndOfArgumentVariable }
;
sargvar:
  | STRVAR sargvar { Types.ArgumentVariableCons($1, $2) }
  | { Types.EndOfArgumentVariable }
;
nxlor:
  | nxland LOR nxlor { Types.LogicalOr($1, $3) }
  | nxland { $1 }
;
nxland:
  | nxcomp LAND nxland { Types.LogicalAnd($1, $3) }
  | nxcomp { $1 }
;
nxcomp:
  | nxconcat EQ nxcomp { Types.EqualTo($1, $3) }
  | nxconcat NEQ nxcomp { Types.LogicalNot(Types.EqualTo($1, $3)) }
  | nxconcat GEQ nxcomp { Types.LogicalNot(Types.LessThan($1, $3)) }
  | nxconcat LEQ nxcomp { Types.LogicalNot(Types.GreaterThan($1, $3)) }
  | nxconcat GT nxcomp { Types.GreaterThan($1, $3) }
  | nxconcat LT nxcomp { Types.LessThan($1, $3) }
  | nxconcat { $1 }
;
nxconcat:
  | nxlplus CONCAT nxconcat { Types.Concat($1, $3) }
  | nxlplus { $1 }
;
nxlplus:
  | nxlminus PLUS nxrplus { Types.Plus($1, $3) }
  | nxlminus { $1 }
;
nxlminus:
  | nxlplus MINUS nxrtimes { Types.Minus($1, $3) }
  | nxltimes { $1 }
;
nxrplus:
  | nxrminus PLUS nxrplus { Types.Plus($1, $3) }
  | nxrminus { $1 }
;
nxrminus:
  | nxrplus MINUS nxrtimes { Types.Minus($1, $3) }
  | nxrtimes { $1 }
;
nxltimes:
  | nxun TIMES nxrtimes { Types.Times($1, $3) }
  | nxltimes DIVIDES nxapp { Types.Divides($1, $3) }
  | nxltimes MOD nxapp { Types.Mod($1, $3) }
  | nxun { $1 }
;
nxrtimes:
  | nxapp TIMES nxrtimes { Types.Times($1, $3) }
  | nxrtimes DIVIDES nxapp { Types.Divides($1, $3) }
  | nxrtimes MOD nxapp { Types.Mod($1, $3) }
  | nxapp { $1 }
;
nxun:
  | MINUS nxapp { Types.Minus(Types.NumericConstant(0), $2) }
  | LNOT nxapp { Types.LogicalNot($2) }
  | nxapp { $1 }
;
nxapp:
  | nxapp nxbot { Types.NumericApply($1, $2) }
  | nxbot { $1 }
;
nxbot:
  | NUMVAR { Types.NumericContentOf($1) }
  | NUMCONST { Types.NumericConstant(int_of_string $1) }
  | LPAREN nxlet RPAREN { $2 }
  | OPENSTR sxblock CLOSESTR { $2 }
  | OPENQT sxblock CLOSEQT { $2 }
;
sxblock:
  | sxbot sxblock { Types.Concat($1, $2) }
  | { Types.StringEmpty }
;
sxbot:
  | CHAR { Types.StringConstant($1) }
  | SPACE { Types.StringConstant(" ") }
  | BREAK { Types.BreakAndIndent }
  | STRVAR END { Types.StringContentOf($1) }
  | CTRLSEQ narg sarg {
        Types.StringApply($1, Types.NoClassName, Types.NoIDName, (append_argument_list $2 $3))
      }
  | CTRLSEQ CLASSNAME narg sarg {
        Types.StringApply($1, Types.ClassName($2), Types.NoIDName, (append_argument_list $3 $4))
      }
  | CTRLSEQ IDNAME narg sarg {
        Types.StringApply($1, Types.NoClassName, Types.IDName($2), (append_argument_list $3 $4))
      }
  | CTRLSEQ CLASSNAME IDNAME narg sarg {
        Types.StringApply($1, Types.ClassName($2), Types.IDName($3), (append_argument_list $4 $5))
      }
;
narg: /* -> Types.argument_cons */
  | OPENNUM nxlet CLOSENUM narg { Types.ArgumentCons($2, $4) }
  | { Types.EndOfArgument }
;
sarg: /* -> Types.argument_cons */
  | BGRP sxblock EGRP sargsub { Types.ArgumentCons($2, $4) }
  | OPENQT sxblock CLOSEQT sargsub { Types.ArgumentCons($2, $4) }
  | END { Types.EndOfArgument }
;
sargsub: /* -> Types.argument_cons */
  | BGRP sxblock EGRP sargsub { Types.ArgumentCons($2, $4) }
  | OPENQT sxblock CLOSEQT sargsub { Types.ArgumentCons($2, $4) }
  | { Types.EndOfArgument }
;