# Makefile for Vlang Compiler
# Works on Linux/Unix systems with lex/yacc or flex/bison

CC = gcc
FLEX = flex
BISON = bison
CFLAGS = -g -Wall
TARGET = vlang_compiler

# Main target
all: $(TARGET)

# Build the compiler
$(TARGET): vlang.tab.c lex.yy.c parser_functions.o
	@echo "Compiling Vlang compiler..."
	$(CC) $(CFLAGS) -o $(TARGET) vlang.tab.c lex.yy.c parser_functions.o -lfl
	@echo "Build successful! Compiler created: $(TARGET)"

# Generate parser
vlang.tab.c vlang.tab.h: vlang.y parser_functions.h
	@echo "Generating parser with bison..."
	$(BISON) -d -b vlang vlang.y

# Generate lexer
lex.yy.c: vlang.l vlang.tab.h parser_functions.h
	@echo "Generating lexer with flex..."
	$(FLEX) vlang.l

parser_functions.o: parser_functions.c parser_functions.h
	$(CC) $(CFLAGS) -c parser_functions.c

# Clean build files
clean:
	@echo "Cleaning build files..."
	rm -f lex.yy.c vlang.tab.c vlang.tab.h $(TARGET) *.o output.c example_exec
	@echo "Clean complete."

# Test with example
test: $(TARGET)
	@echo "Testing with example.vl..."
	./$(TARGET) example.vlang output.c
	@echo "Compiling generated C code..."
	$(CC) -o example_exec output.c
	@echo "Running example program:"
	@echo "================================"
	@./example_exec
	@echo "================================"

# Build and test in one command
run: test

# Compile a specific .vl file
%.c: %.vl $(TARGET)
	./$(TARGET) $< $@

# Show help
help:
	@echo "Vlang Compiler Makefile"
	@echo "======================="
	@echo "Available targets:"
	@echo "  make         - Build the compiler"
	@echo "  make test    - Build and test with example.vl"
	@echo "  make run     - Same as 'make test'"
	@echo "  make clean   - Remove all generated files"
	@echo "  make help    - Show this help message"

.PHONY: all clean test run help