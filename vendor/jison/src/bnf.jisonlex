
%%
\s+    	{/* skip whitespace */}
"//".*    	{/* skip comment */}
"/*"[^*]*"*"    	{return yy.lexComment(this);}
[a-zA-Z][a-zA-Z0-9_-]*    	{return 'ID';}
'"'[^"]+'"'    	{yytext = yytext.substr(1, yyleng-2); return 'STRING';}
"'"[^']+"'"    	{yytext = yytext.substr(1, yyleng-2); return 'STRING';}
":"    	{return ':';}
";"    	{return ';';}
"|"    	{return '|';}
"%%"    	{return '%%';}
"%prec"    	{return 'PREC';}
"%start"    	{return 'START';}
"%left"    	{return 'LEFT';}
"%right"    	{return 'RIGHT';}
"%nonassoc"    	{return 'NONASSOC';}
"%"[a-zA-Z]+[^\n]*    	{/* ignore unrecognized decl */}
"<"[a-zA-Z]*">"    	{ /* ignore type */}
"{{"[^}]*"}"    	{return yy.lexAction(this);}
"{"[^}]*"}"    	{yytext = yytext.substr(1, yyleng-2); return 'ACTION';}
"%{"(.|\n)*?"%}"    	{yytext = yytext.substr(2, yytext.length-4);return 'ACTION';}
.    	{/* ignore bad characters */}
<<EOF>>    	{return 'EOF';}

%%

