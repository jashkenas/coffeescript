/* Jison lexer file format grammar */

%nonassoc '/'

%left '*' '+' '?' RANGE_REGEX

%% 

lex 
    : definitions include '%%' rules '%%' EOF
        {{ $$ = {rules: $4};
          if ($1.length) $$.macros = $1;
          if ($2) $$.actionInclude = $2;
          return $$; }}
    | definitions include '%%' rules EOF
        {{ $$ = {rules: $4};
          if ($1.length) $$.macros = $1;
          if ($2) $$.actionInclude = $2;
          return $$; }}
    ;

include
    : action
    |
    ;

definitions
    : definitions definition
        { $$ = $1; $$.push($2); }
    | 
        { $$ = []; }
    ;

definition
    : name regex
        { $$ = [$1, $2]; }
    ;

name
    : NAME
        { $$ = yytext; }
    ;

rules
    : rules rule
        { $$ = $1; $$.push($2); }
    | rule
        { $$ = [$1]; }
    ;

rule
    : regex action
        { $$ = [$1, $2]; }
    ;

action
    : ACTION 
        { $$ = yytext; }
    ;

regex
    : regex_list 
        { $$ = $1; 
          if ($$.match(/[\w\d]$/))
              $$ += "\\b";
        }
    ;

regex_list
    : regex_list '|' regex_list
        { $$ = $1+'|'+$3; }
    | regex_concat
    ;

regex_concat
    : regex_concat regex_base
        { $$ = $1+$2; }
    | regex_base
    ;

regex_base
    : '(' regex_list ')'
        { $$ = '('+$2+')'; }
    | regex_base '+'
        { $$ = $1+'+'; }
    | regex_base '*'
        { $$ = $1+'*'; }
    | regex_base '?'
        { $$ = $1+'?'; }
    | '/' regex_base
        { $$ = '(?='+$2+')'; }
    | name_expansion
    | regex_base range_regex
        { $$ = $1+$2; }
    | any_group_regex
    | '.'
        { $$ = '.'; }
    | '^' 
        { $$ = '^'; }
    | '$'
        { $$ = '$'; }
    | string
    | escape_char
    ;

name_expansion
    : '{' name '}'
        {{ $$ = '{'+$2+'}'; }}
    ;

any_group_regex
    : ANY_GROUP_REGEX
        { $$ = yytext; }
    ;

escape_char
    : ESCAPE_CHAR
        { $$ = yytext; }
    ;

range_regex
    : RANGE_REGEX
        { $$ = yytext; }
    ;

string
    : STRING_LIT
        { $$ = yy.prepareString(yytext.substr(1, yytext.length-2)); }
    ;
