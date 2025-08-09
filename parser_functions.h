#ifndef PARSER_FUNCTIONS_H
#define PARSER_FUNCTIONS_H

#define SCALAR 0
#define VECTOR 1
#define VECTOR_CONSTANT 2

extern FILE *yyin;

FILE *outfile;
int temp_counter = 0;
int label_counter = 0;
int indent_level = 1;

typedef struct {
    char name[64];
    int type;
    int size;
} Symbol;

Symbol symbol_table[100];
int symbol_count = 0;

typedef struct {
    char *code;
    char *place;
    int type;
    int size;
    int *values;
} ExprInfo;

void yyerror(const char *s);
void add_symbol(char *name, int type, int size);
Symbol* find_symbol(char *name);
char* new_temp();
char* new_label();
void emit(const char *str);
void emit_indent(const char *str);
ExprInfo make_scalar(char *place);
ExprInfo make_vector(char *place, int size);

#endif