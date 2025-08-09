# Vlang Compiler

A compiler for the Vlang language that translates Vlang source code to C/C++.

## Language Features

### Data Types
- **scl**: Integer scalar
- **vec**: Vector of scalars with fixed size

### Operators
- `@`: Vector dot product (highest precedence, left associative)
- `+`, `-`, `*`, `/`: Arithmetic operators (same precedence as C)
- `:`: Indexing operator for vectors

### Control Structures
- **if**: Conditional execution
- **loop**: Loop execution for a specified number of iterations
- **print**: Output statement

### Vector Operations
- Element-wise arithmetic operations
- Dot product using `@` operator
- Vector indexing (both single element and vector-based indexing)
- Broadcasting (assigning scalar to all vector elements)

## Files Included

1. **vlang.l** - Lexical analyzer (Lex/Flex file)
2. **vlang_improved.y** - Parser with code generation (Yacc/Bison file)
3. **Makefile** - Build configuration
4. **build.sh** - Shell script for building and testing
5. **example.vl** - Example Vlang program
6. **README.md** - This documentation

## Building the Compiler

### Prerequisites
- GCC compiler
- Lex/Flex
- Yacc/Bison
- Make (optional)

### Build Methods

#### Method 1: Using the build script
```bash
chmod +x build.sh
./build.sh
```

#### Method 2: Using Make
```bash
make
make test  # To compile and run the example
```

#### Method 3: Manual compilation
```bash
yacc -d vlang_improved.y
lex vlang.l
gcc -o vlang_compiler vlang.tab.c lex.yy.c -lfl
```

## Usage

### Compiling a Vlang program
```bash
./vlang_compiler input.vl output.c
```

### Compiling the generated C code
```bash
gcc -o program output.c
./program
```

## Example Program

The `example.vl` file demonstrates:
- Variable declarations (scalars and vectors)
- Vector initialization with constants
- Arithmetic operations
- Vector dot product
- Conditional statements
- Loops
- Vector indexing
- Print statements

## Example Output

Running the example program should produce output like:
```
V1<dot>V2: 48
v1 is: [0, 1, 2, 4, 4, 4]
v2 indexed: [1, 1, 2, 3, 3, 3]
that reversed: [3, 3, 3, 2, 1, 1]
: 2
Rotate: 0 [10, 0, 20]
Rotate: 1 [20, 10, 0]
z is: [5, 7, 9, 11]
z summed: 32
```

## Submission Materials

When submitting, include:
1. LEX file (vlang.l)
2. YACC file (vlang_improved.y)
3. Makefile
4. Compiler executable (vlang_compiler)
5. Example source file (example.vl)
6. Generated C file (output.c)
7. Final executable (example_exec)
8. Video demonstration of the build and execution process

## Platform Compatibility

This compiler has been tested on:
- Linux (Ubuntu, Debian, CentOS)
- macOS (with Xcode Command Line Tools)
- Windows (with Cygwin or WSL)

## Notes

- Variable names can be up to 32 characters
- Vectors must have their size specified at declaration
- The @ operator computes dot product and returns a scalar
- Vector indexing with another vector creates a new vector
- All arithmetic operations support vector-scalar and vector-vector operations
