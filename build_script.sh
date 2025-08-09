#!/bin/bash

echo "Building Vlang Compiler..."

# Clean previous builds
rm -f lex.yy.c vlang.tab.c vlang.tab.h vlang_compiler output.c example_exec

# Generate parser
echo "Generating parser with yacc..."
yacc -d vlang.y

# Generate lexer
echo "Generating lexer with lex..."
lex vlang.l

# Compile the compiler
echo "Compiling the Vlang compiler..."
gcc -o vlang_compiler vlang.tab.c lex.yy.c -lfl

if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # Test with example if it exists
    if [ -f "example.vl" ]; then
        echo ""
        echo "Testing with example.vl..."
        ./vlang_compiler example.vl output.c
        
        if [ $? -eq 0 ]; then
            echo "Compiling generated C code..."
            gcc -o example_exec output.c
            
            if [ $? -eq 0 ]; then
                echo "Running the example program:"
                echo "================================"
                ./example_exec
                echo "================================"
            fi
        fi
    fi
else
    echo "Build failed!"
    exit 1
fi
