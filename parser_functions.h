#ifndef PARSER_FUNCTIONS_H
#define PARSER_FUNCTIONS_H

#define SCALAR 0
#define VECTOR 1
#define VECTOR_CONSTANT 2

extern FILE *yyin;

extern FILE *outfile;
extern int temp_counter;
extern int label_counter;
extern int indent_level;

typedef struct {
    char name[64];
    int type;
    int size;
} Symbol;

extern Symbol symbol_table[100];
extern int symbol_count;

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