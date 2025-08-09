%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser_functions.h"
#include "vlang.tab.h"
%}

%%

"scl"           { return SCL; }
"vec"           { return VEC; }
"if"            { return IF; }
"loop"          { return LOOP; }
"print"         { return PRINT; }

[0-9]+          { yylval.ival = atoi(yytext); return NUMBER; }

[a-zA-Z_][a-zA-Z0-9_]{0,31}  { 
                    yylval.sval = strdup(yytext); 
                    return IDENTIFIER; 
                }

\"[^\"]*\"      { 
                    yylval.sval = strdup(yytext);
                    return STRING; 
                }

"@"             { return AT; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULT; }
"/"             { return DIV; }
"="             { return ASSIGN; }
":"             { return COLON; }
";"             { return SEMICOLON; }
","             { return COMMA; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }
"("             { return LPAREN; }
")"             { return RPAREN; }
"["             { return LBRACKET; }
"]"             { return RBRACKET; }

[ \t\n\r]       { /* skip whitespace */ }
"//".*          { /* skip comments */ }

.               { printf("Unknown character: %s\n", yytext); }

%%
