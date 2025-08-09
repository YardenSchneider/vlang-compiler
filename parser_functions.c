#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser_functions.h"

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
    exit(1);
}

void add_symbol(char *name, int type, int size) {
    strcpy(symbol_table[symbol_count].name, name);
    symbol_table[symbol_count].type = type;
    symbol_table[symbol_count].size = size;
    symbol_count++;
}

Symbol* find_symbol(char *name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return &symbol_table[i];
        }
    }
    return NULL;
}

char* new_temp() {
    static char temp[32];
    sprintf(temp, "_t%d", temp_counter++);
    return strdup(temp);
}

char* new_label() {
    static char label[32];
    sprintf(label, "_L%d", label_counter++);
    return strdup(label);
}

void emit(const char *str) {
    fprintf(outfile, "%s\n", str);
}

void emit_indent(const char *str) {
    for (int i = 0; i < indent_level; i++) {
        fprintf(outfile, "  ");
    }
    fprintf(outfile, "%s\n", str);
}

ExprInfo make_scalar(char *place) {
    ExprInfo e;
    e.place = place;
    e.type = SCALAR;
    e.size = 0;
    e.code = NULL;
    e.values = NULL;
    return e;
}

ExprInfo make_vector(char *place, int size) {
    ExprInfo e;
    e.place = place;
    e.type = VECTOR;
    e.size = size;
    e.code = NULL;
    e.values = NULL;
    return e;
}