%%

spec
    : declaration_list '%%' grammar EOF
        {$$ = $1; $$.bnf = $3; return $$;}
    | declaration_list '%%' grammar '%%' EOF
        {$$ = $1; $$.bnf = $3; return $$;}
    ;

declaration_list
    : declaration_list declaration
        {$$ = $1; yy.addDeclaration($$, $2);}
    | 
        {{$$ = {};}}
    ;

declaration
    : START id
        {{$$ = {start: $2};}}
    | operator
        {{$$ = {operator: $1};}}
    ;

operator
    : associativity token_list
        {$$ = [$1]; $$.push.apply($$, $2);}
    ;

associativity
    : LEFT
        {$$ = 'left';}
    | RIGHT
        {$$ = 'right';}
    | NONASSOC
        {$$ = 'nonassoc';}
    ;

token_list
    : token_list symbol
        {$$ = $1; $$.push($2);}
    | symbol
        {$$ = [$1];}
    ;

grammar
    : production_list
        {$$ = $1;}
    ;

production_list
    : production_list production
        {$$ = $1; $$[$2[0]] = $2[1];}
    | production
        {{$$ = {}; $$[$1[0]] = $1[1];}}
    ;

production
    : id ':' handle_list ';'
        {$$ = [$1, $3];}
    ;

handle_list
    : handle_list '|' handle_action
        {$$ = $1; $$.push($3);}
    | handle_action
        {$$ = [$1];}
    ;

handle_action
    : handle prec action 
        {$$ = [($1.length ? $1.join(' ') : '')];
            if($3) $$.push($3);
            if($2) $$.push($2);
            if ($$.length === 1) $$ = $$[0];
        }
    ;

handle
    : handle symbol
        {$$ = $1; $$.push($2)}
    | 
        {$$ = [];}
    ;

prec
    : PREC symbol
        {{$$ = {prec: $2};}}
    | 
        {$$ = null;}
    ;

symbol
    : id
        {$$ = $1;}
    | STRING
        {$$ = yytext;}
    ;

id
    : ID
        {$$ = yytext;}
    ;

action
    : ACTION
        {$$ = yytext;}
    | 
        {$$ = '';}
    ;

