
%%
\n+    	{yy.freshLine = true;}
\s+    	{if (yy.ruleSection) yy.freshLine = false;}
"y{"[^}]*"}"    	{yytext = yytext.substr(2, yytext.length-3);return 'ACTION';}
[a-zA-Z_][a-zA-Z0-9_-]*    	{return 'NAME';}
'"'("\\\\"|'\"'|[^"])*'"'    	{yytext = yytext.replace(/\\"/g,'"');return 'STRING_LIT';}
"'"("\\\\"|"\'"|[^'])*"'"    	{yytext = yytext.replace(/\\'/g,"'");return 'STRING_LIT';}
"|"    	{return '|';}
"["("\]"|[^\]])*"]"    	{return 'ANY_GROUP_REGEX';}
"("    	{return '(';}
")"    	{return ')';}
"+"    	{return '+';}
"*"    	{return '*';}
"?"    	{return '?';}
"^"    	{return '^';}
"/"    	{return '/';}
"\\"[a-zA-Z0]    	{return 'ESCAPE_CHAR';}
"$"    	{return '$';}
"<<EOF>>"    	{return '$';}
"."    	{return '.';}
"%%"    	{yy.ruleSection = true; return '%%';}
"{"\d+(","\s?\d+|",")?"}"    	{return 'RANGE_REGEX';}
/"{"    	%{if (yy.freshLine) {this.input('{');return '{';} else this.unput('y');%}
"}"    	%{return '}';%}
"%{"(.|\n)*?"%}"    	{yytext = yytext.substr(2, yytext.length-4);return 'ACTION';}
.    	{/* ignore bad characters */}
<<EOF>>    	{return 'EOF';}

%%

