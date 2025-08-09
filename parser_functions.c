#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser_functions.h"

FILE *outfile;
int temp_counter = 0;
int label_counter = 0;
int indent_level = 1;
Symbol symbol_table[100];
int symbol_count = 0;

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

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input.vl> <output.c>\n", argv[0]);
        return 1;
    }
    
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Cannot open input file: %s\n", argv[1]);
        return 1;
    }
    
    outfile = fopen(argv[2], "w");
    if (!outfile) {
        fprintf(stderr, "Cannot open output file: %s\n", argv[2]);
        return 1;
    }
    
    // Write C header
    fprintf(outfile, "#include <stdio.h>\n");
    fprintf(outfile, "#include <stdlib.h>\n\n");
    fprintf(outfile, "int main() {\n");
    
    yyparse();
    
    // Write C footer
    fprintf(outfile, "}\n");
    
    fclose(yyin);
    fclose(outfile);
    
    printf("Compilation successful! Output written to %s\n", argv[2]);
    
    return 0;
}