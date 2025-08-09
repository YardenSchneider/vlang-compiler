CC = gcc
FLEX = flex
BISON = bison
CFLAGS = -g -Wall
TARGET = vlang_compiler

all: $(TARGET)

$(TARGET): vlang.tab.c lex.yy.c parser_functions.o
	$(CC) $(CFLAGS) -o $(TARGET) vlang.tab.c lex.yy.c parser_functions.o -lfl

vlang.tab.c vlang.tab.h: vlang.y parser_functions.h
	$(BISON) -d -b vlang vlang.y

lex.yy.c: vlang.l vlang.tab.h parser_functions.h
	$(FLEX) vlang.l

parser_functions.o: parser_functions.c parser_functions.h
	$(CC) $(CFLAGS) -c parser_functions.c

clean:
	rm -f lex.yy.c vlang.tab.c vlang.tab.h $(TARGET) *.o output.c example_exec

test: $(TARGET)
	./$(TARGET) example.vlang output.c
	$(CC) -o example_exec output.c
	@echo "Running example program:"
	@echo "================================"
	@./example_exec
	@echo "================================"

run: test
