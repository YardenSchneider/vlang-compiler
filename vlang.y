%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser_functions.h"

extern int yylex();
char buf[256];

%}

%union {
    int ival;
    char *sval;
    ExprInfo expr;
    struct {
        int *values;
        int count;
    } numlist;
}

%token <ival> NUMBER
%token <sval> IDENTIFIER STRING
%token SCL VEC IF LOOP PRINT
%token AT PLUS MINUS MULT DIV ASSIGN COLON SEMICOLON COMMA
%token LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET

%left AT
%left PLUS MINUS
%left MULT DIV

%type <expr> expression primary_expr
%type <numlist> number_list

%%

program:
    block {
        emit_indent("return 0;");
    }
    ;

block:
    LBRACE { indent_level++; } statement_list { indent_level--; } RBRACE
    ;

statement_list:
    statement_list statement
    | statement
    ;

statement:
    variable_declaration
    | assignment_statement
    | conditional_statement
    | loop_statement
    | print_statement
    ;

variable_declaration:
    SCL IDENTIFIER SEMICOLON {
        add_symbol($2, 0, 0);
        sprintf(buf, "int %s;", $2);
        emit_indent(buf);
        free($2);
    }
    | VEC IDENTIFIER LBRACE NUMBER RBRACE SEMICOLON {
        add_symbol($2, 1, $4);
        sprintf(buf, "int %s[%d];", $2, $4);
        emit_indent(buf);
        free($2);
    }
    ;

assignment_statement:
    IDENTIFIER ASSIGN expression SEMICOLON {
        Symbol *sym = find_symbol($1);
        if (!sym) {
            yyerror("Undefined variable");
        } else if (sym->type == SCALAR && $3.type == SCALAR) {
            // Scalar = Scalar
            sprintf(buf, "%s = %s;", $1, $3.place);
            emit_indent(buf);
        } else if (sym->type == VECTOR && $3.type == SCALAR) {
            // Vector = Scalar
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) {", sym->size);
            emit_indent(buf);
            indent_level++;
            sprintf(buf, "%s[_i] = %s;", $1, $3.place);
            emit_indent(buf);
            indent_level--;
            emit_indent("}");
        } else if (sym->type == VECTOR && $3.type == VECTOR) {
            // Vector = Vector
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) {", sym->size);
            emit_indent(buf);
            indent_level++;
            sprintf(buf, "%s[_i] = %s[_i];", $1, $3.place);
            emit_indent(buf);
            indent_level--;
            emit_indent("}");
        } else if (sym->type == VECTOR && $3.type == VECTOR_CONSTANT) {
            // Vector = Vector_Constant
            emit_indent("{");
            indent_level++;
            emit_indent("int _tmp[] = {");
            for (int i = 0; i < $3.size; i++) {
                if (i > 0) fprintf(outfile, ", ");
                fprintf(outfile, "%d", $3.values[i]);
            }
            fprintf(outfile, "};\n");
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = _tmp[_i];", 
                       sym->size, $1);
            emit_indent(buf);
            indent_level--;
            emit_indent("}");
            free($3.values);
        }
        free($1);
    }
    | IDENTIFIER COLON expression ASSIGN expression SEMICOLON {
        sprintf(buf, "%s[%s] = %s;", $1, $3.place, $5.place);
        emit_indent(buf);
        free($1);
    }
    ;

conditional_statement:
    IF expression {
        sprintf(buf, "if (%s) {", $2.place);
        emit_indent(buf);
        indent_level++;
    } block {
        indent_level--;
        emit_indent("}");
    }
    ;

loop_statement:
    LOOP expression {
        char *loop_var = new_temp();
        sprintf(buf, "for(int %s = 0; %s < %s; %s++) {", 
                   loop_var, loop_var, $2.place, loop_var);
        emit_indent(buf);
        indent_level++;
    } block {
        indent_level--;
        emit_indent("}");
    }
    ;

print_statement:
    PRINT STRING COLON print_elements SEMICOLON {
        char *str = $2;
        int len = strlen(str);
        if (len >= 2 && str[0] == '"' && str[len-1] == '"') {
            str[len-1] = '\0';
            str++;
        }
        sprintf(buf, "printf(\"%s: \");", str);
        emit_indent(buf);
        emit_indent("printf(\"\\n\");");
        free($2);
    }
    ;

print_elements:
    print_elements COMMA expression {
        Symbol *sym = find_symbol($3.place);
        if ($3.type == VECTOR || (sym && sym->type == VECTOR)) {
            int size = sym ? sym->size : $3.size;
            emit_indent("printf(\"[\");");
            sprintf(buf, "for(int _p = 0; _p < %d; _p++) {", size);
            emit_indent(buf);            
            indent_level++;
            emit_indent("if (_p > 0) printf(\", \");");
            sprintf(buf, "printf(\"%%d\", %s[_p]);", $3.place);
            emit_indent(buf);
            indent_level--;
            emit_indent("}");
            emit_indent("printf(\"]\");");
            emit_indent("printf(\" \");");
        } else {
            sprintf(buf, "printf(\"%%d \", %s);", $3.place);
            emit_indent(buf);
        }
    }
    | expression {
        Symbol *sym = find_symbol($1.place);
        if ($1.type == VECTOR || (sym && sym->type == VECTOR)) {
            int size = sym ? sym->size : $1.size;
            emit_indent("printf(\"[\");");
            sprintf(buf, "for(int _p = 0; _p < %d; _p++) {", size);
            emit_indent(buf);
            indent_level++;
            emit_indent("if (_p > 0) printf(\", \");");
            sprintf(buf, "printf(\"%%d\", %s[_p]);", $1.place);
            emit_indent(buf);
            indent_level--;
            emit_indent("}");
            emit_indent("printf(\"]\");");
        } else {
            sprintf(buf, "printf(\"%%d\", %s);", $1.place);
            emit_indent(buf);
        }
    }
    ;

expression:
    primary_expr { 
        if ($1.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            sprintf(buf, "int %s[%d] = {", temp, $1.size);
            for (int i = 0; i < $1.size; i++) {
                if (i > 0) fprintf(outfile, ", ");
                fprintf(outfile, "%d", $1.values[i]);
            }
            fprintf(outfile, "};\n");
            emit_indent("");
            
            $1.type = VECTOR;
            $1.place = temp;
            free($1.values);
            $1.values = NULL;
        }
        $$ = $1; 
    }
    | expression PLUS expression {
        if ($1.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            char array_buf[1024];
            sprintf(array_buf, "int %s[%d] = {", temp, $1.size);
            for (int i = 0; i < $1.size; i++) {
                if (i > 0) strcat(array_buf, ", ");
                char num_str[16];
                sprintf(num_str, "%d", $1.values[i]);
                strcat(array_buf, num_str);
            }
            strcat(array_buf, "};");
            emit_indent(array_buf);
            
            $1.type = VECTOR;
            $1.place = temp;
            free($1.values);
        }
        if ($3.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            char array_buf[1024];
            sprintf(array_buf, "int %s[%d] = {", temp, $3.size);
            for (int i = 0; i < $3.size; i++) {
                if (i > 0) strcat(array_buf, ", ");
                char num_str[16];
                sprintf(num_str, "%d", $3.values[i]);
                strcat(array_buf, num_str);
            }
            strcat(array_buf, "};");
            emit_indent(array_buf);
            
            $3.type = VECTOR;
            $3.place = temp;
            free($3.values);
        }
        
        if ($1.type == SCALAR && $3.type == SCALAR) {
            // Scalar + Scalar
            char *temp = new_temp();
            sprintf(buf, "int %s = %s + %s;", temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_scalar(temp);
        } else if ($1.type == VECTOR && $3.type == SCALAR) {
            // Vector + Scalar
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $1.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s[_i] + %s;",
                       $1.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $1.size);
        } else if ($1.type == SCALAR && $3.type == VECTOR) {
            // Scalar + Vector
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $3.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s + %s[_i];",
                       $3.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $3.size);
        } else {
            // Vector + Vector
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $1.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s[_i] + %s[_i];",
                       $1.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $1.size);
        }
    }
    | expression MINUS expression {
        if ($1.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            sprintf(buf, "int %s[%d] = {", temp, $1.size);
            for (int i = 0; i < $1.size; i++) {
                if (i > 0) fprintf(outfile, ", ");
                fprintf(outfile, "%d", $1.values[i]);
            }
            fprintf(outfile, "};\n");
            emit_indent("");
            $1.type = VECTOR;
            $1.place = temp;
            free($1.values);
        }
        if ($3.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            sprintf(buf, "int %s[%d] = {", temp, $3.size);
            for (int i = 0; i < $3.size; i++) {
                if (i > 0) fprintf(outfile, ", ");
                fprintf(outfile, "%d", $3.values[i]);
            }
            fprintf(outfile, "};\n");
            emit_indent("");
            $3.type = VECTOR;
            $3.place = temp;
            free($3.values);
        }
        
        if ($1.type == SCALAR && $3.type == SCALAR) {
            // Scalar - Scalar
            char *temp = new_temp();
            sprintf(buf, "int %s = %s - %s;", temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_scalar(temp);
        } else if ($1.type == VECTOR && $3.type == SCALAR) {
            // Vector - Scalar
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $1.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s[_i] - %s;",
                       $1.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $1.size);
        } else if ($1.type == SCALAR && $3.type == VECTOR) {
            // Scalar - Vector
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $3.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s - %s[_i];",
                       $3.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $3.size);
        } else {
            // Vector - Vector
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $1.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s[_i] - %s[_i];",
                       $1.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $1.size);
        }
    }
    | expression MULT expression {
        if ($1.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            sprintf(buf, "int %s[%d] = {", temp, $1.size);
            for (int i = 0; i < $1.size; i++) {
                if (i > 0) fprintf(outfile, ", ");
                fprintf(outfile, "%d", $1.values[i]);
            }
            fprintf(outfile, "};\n");
            emit_indent("");
            $1.type = VECTOR;
            $1.place = temp;
            free($1.values);
        }
        if ($3.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            sprintf(buf, "int %s[%d] = {", temp, $3.size);
            for (int i = 0; i < $3.size; i++) {
                if (i > 0) fprintf(outfile, ", ");
                fprintf(outfile, "%d", $3.values[i]);
            }
            fprintf(outfile, "};\n");
            emit_indent("");
            $3.type = VECTOR;
            $3.place = temp;
            free($3.values);
        }
        
        if ($1.type == SCALAR && $3.type == SCALAR) {
            // Scalar * Scalar
            char *temp = new_temp();
            sprintf(buf, "int %s = %s * %s;", temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_scalar(temp);
        } else if ($1.type == VECTOR && $3.type == SCALAR) {
            // Vector * Scalar
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $1.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s[_i] * %s;",
                       $1.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $1.size);
        } else if ($1.type == SCALAR && $3.type == VECTOR) {
            // Scalar * Vector
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $3.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s * %s[_i];",
                       $3.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $3.size);
        } else {
            // Vector * Vector
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $1.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s[_i] * %s[_i];",
                       $1.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $1.size);
        }
    }
    | expression DIV expression {
        if ($1.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            sprintf(buf, "int %s[%d] = {", temp, $1.size);
            for (int i = 0; i < $1.size; i++) {
                if (i > 0) fprintf(outfile, ", ");
                fprintf(outfile, "%d", $1.values[i]);
            }
            fprintf(outfile, "};\n");
            emit_indent("");
            $1.type = VECTOR;
            $1.place = temp;
            free($1.values);
        }
        if ($3.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            sprintf(buf, "int %s[%d] = {", temp, $3.size);
            for (int i = 0; i < $3.size; i++) {
                if (i > 0) fprintf(outfile, ", ");
                fprintf(outfile, "%d", $3.values[i]);
            }
            fprintf(outfile, "};\n");
            emit_indent("");
            $3.type = VECTOR;
            $3.place = temp;
            free($3.values);
        }
        
        if ($1.type == SCALAR && $3.type == SCALAR) {
            // Scalar / Scalar
            char *temp = new_temp();
            sprintf(buf, "int %s = %s / %s;", temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_scalar(temp);
        } else if ($1.type == VECTOR && $3.type == SCALAR) {
            // Vector / Scalar
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $1.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s[_i] / %s;",
                       $1.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $1.size);
        } else if ($1.type == SCALAR && $3.type == VECTOR) {
            // Scalar / Vector
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $3.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s / %s[_i];",
                       $3.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $3.size);
        } else {
            // Vector / Vector
            char *temp = new_temp();
            sprintf(buf, "int %s[%d];", temp, $1.size);
            emit_indent(buf);
            sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s[_i] / %s[_i];",
                       $1.size, temp, $1.place, $3.place);
            emit_indent(buf);
            $$ = make_vector(temp, $1.size);
        }
    }
    | expression AT expression {
        if ($1.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            sprintf(buf, "int %s[%d] = {", temp, $1.size);
            for (int i = 0; i < $1.size; i++) {
                if (i > 0) fprintf(outfile, ", ");
                fprintf(outfile, "%d", $1.values[i]);
            }
            fprintf(outfile, "};\n");
            emit_indent("");
            $1.type = VECTOR;
            $1.place = temp;
            free($1.values);
        }
        if ($3.type == VECTOR_CONSTANT) {
            char *temp = new_temp();
            sprintf(buf, "int %s[%d] = {", temp, $3.size);
            for (int i = 0; i < $3.size; i++) {
                if (i > 0) fprintf(outfile, ", ");
                fprintf(outfile, "%d", $3.values[i]);
            }
            fprintf(outfile, "};\n");
            emit_indent("");
            $3.type = VECTOR;
            $3.place = temp;
            free($3.values);
        }
        
        char *temp = new_temp();
        int size = $1.type == VECTOR ? $1.size : $3.size;
        sprintf(buf, "int %s = 0;", temp);
        emit_indent(buf);
        sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s += %s[_i] * %s[_i];",
                   size, temp, $1.place, $3.place);
        emit_indent(buf);
        $$ = make_scalar(temp);
    }
    | LPAREN expression RPAREN {
        $$ = $2;
    }
    ;

primary_expr:
    NUMBER {
        char *temp = new_temp();
        sprintf(buf, "int %s = %d;", temp, $1);
        emit_indent(buf);
        $$ = make_scalar(temp);
    }
    | IDENTIFIER {
        Symbol *sym = find_symbol($1);
        if (!sym) {
            yyerror("Undefined variable");
            $$ = make_scalar($1);
        } else {
            $$.place = strdup($1);
            $$.type = sym->type;
            $$.size = sym->size;
            $$.code = NULL;
            $$.values = NULL;
        }
        free($1);
    }
    | IDENTIFIER COLON expression {
        Symbol *sym = find_symbol($1);
        if (sym && sym->type == VECTOR) {
            if ($3.type == SCALAR) {
                char *temp = new_temp();
                sprintf(buf, "int %s = %s[%s];", temp, $1, $3.place);
                emit_indent(buf);
                $$ = make_scalar(temp);
            } else {
                char *temp = new_temp();
                sprintf(buf, "int %s[%d];", temp, $3.size);
                emit_indent(buf);
                sprintf(buf, "for(int _i = 0; _i < %d; _i++) %s[_i] = %s[%s[_i]];",
                           $3.size, temp, $1, $3.place);
                emit_indent(buf);
                $$ = make_vector(temp, $3.size);
            }
        }
        free($1);
    }
    | LBRACKET number_list RBRACKET {
        char *temp = new_temp();
        
        char array_buf[1024];
        sprintf(array_buf, "int %s[%d] = {", temp, $2.count);
        for (int i = 0; i < $2.count; i++) {
            if (i > 0) strcat(array_buf, ", ");
            char num_str[16];
            sprintf(num_str, "%d", $2.values[i]);
            strcat(array_buf, num_str);
        }
        strcat(array_buf, "};");
        
        emit_indent(array_buf);
        
        $$.type = VECTOR;       
        $$.size = $2.count;
        $$.place = temp;        
        $$.values = NULL;      
        $$.code = NULL;
        
        free($2.values);     
    }
    ;

number_list:
    number_list COMMA NUMBER {
        $$.values = realloc($1.values, ($1.count + 1) * sizeof(int));
        $$.values[$1.count] = $3;
        $$.count = $1.count + 1;
    }
    | NUMBER {
        $$.values = malloc(sizeof(int));
        $$.values[0] = $1;
        $$.count = 1;
    }
    ;

%%