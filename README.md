# CoffeeScript 3: Data-Oriented Grammar Transformation

## Overview

CoffeeScript 3 (CS3) represents a **paradigm shift** in parser architecture: transforming all 420 production patterns (across 97 grammar rules) from function-based actions to **pure data structures**. This enables CoffeeScript to compile not just to JavaScript, but to **any target language**.

### Key Achievements
- **Complete parser rewrite** - Pure data-oriented architecture with no performance loss
- **100x faster parser generation** with Solar (12+ seconds → 100ms)
- **Ultra-compact rule definitions** - Single-line rules with efficient aliasing (`r` function)
- **ReductionFrame architecture** - Backends evaluate Solar directives against per-reduction RHS frames
- **Universal position resolution** - Automatic `1` → `'x'` resolution through frame slots
- **Complete Solar directive system** - All 404 patterns transformed to language-agnostic directives
- **100% test compatibility** - All 455 tests passing with the new architecture
- **Universal backend interface** - Any language can implement Solar directive evaluation

## The Solar Directive System

CS3 uses Solar's universal directive system with just 4 core directives:

1. **`$ast`** - Creates AST nodes (universal)
2. **`$ary`** - Creates arrays with optional properties (universal)
3. **`$ops`** - Performs operations (categorized by type)
4. **`$use`** - Universal references (stack elements, properties, methods)

Plus **`$pos`** for position tracking. No special cases or auxiliary directives needed.

**Note:** Plain objects need no directive - just use properties directly!

### 📖 Full Specification

The complete directive system specification is included below in the **CS3 Solar Directive System** section

## Quick Example

```coffee
# Old (function-based)
SimpleAssignable: [
  o 'Identifier', -> new Value $1
]
Class: [
  o 'CLASS SimpleAssignable EXTENDS Expression', -> new Class $2, $4
]

# New (data-oriented with semantic names)
SimpleAssignable: [
  o 'Identifier', $ast: 'Value', val: 1  # 'val' not 'base'!
]
Class: [
  o 'CLASS SimpleAssignable EXTENDS Expression', $ast: '@', variable: 2, parent: 4
  # Clear semantic names: 'variable' and 'parent', not 'arg1' and 'arg2'
]
```

## Architecture

```
CoffeeScript Code → Solar Parser → ReductionFrame → Solar Directive Evaluator → Target Code
                    (100ms gen)     (Per-reduction   (Universal backend)       ├── JavaScript ✅
                                    RHS frames)                               ├── Python
                                                                              ├── WASM
                                                                              └── Any Language
```

**ReductionFrame Innovation**: Backends evaluate Solar directives against **per-reduction RHS frames**, enabling:
- **Universal position resolution** (`1` → actual token value)
- **Language-agnostic evaluation** (any backend can implement Solar directive processing)
- **Clean separation** (parser stays dumb, backends stay smart)

### Project Structure

```
coffeescript/
├── src/
│   ├── grammar.coffee        # Original class-based grammar
│   ├── syntax.coffee         # NEW: Data-oriented grammar
│   └── cs3-*.coffee          # CS3 transformation tools
├── backends/
│   ├── es6/                  # JavaScript backend
│   ├── python/               # Python backend (planned)
│   └── wasm/                 # WebAssembly backend (planned)
└── README.md                # Complete documentation with CS3 specification
```

## Implementation Status

### 🎯 Production Ready!

The CS3 implementation is **complete and optimized**:
- **97 rules** perfectly match between `grammar.coffee` and `syntax.coffee`
- **420 patterns** successfully transformed to pure data
- **86 generic properties** updated to semantic names
- **Backend optimized** to 1,595 lines with clean, maintainable code
- **Performance validated** - No performance penalty (actually slightly faster in CPU utilization)
- **Parser generation optimized** - Streamlined frame construction and efficient aliasing

### ✅ Completed
- **Solar Parser Generator** - 100x faster generation (100ms vs 12+ seconds)
- **Complete Grammar Transformation** - All 404 patterns converted to Solar directives
- **ReductionFrame Architecture** - Per-reduction RHS frames with universal position resolution
- **Solar Directive Evaluator** - Backends evaluate directives against ReductionFrame
- **Working CS3 Pipeline** - `'x'` → `IdentifierLiteral('x')` → `"x"` JavaScript
- **Universal Backend Interface** - Any language can implement Solar directive evaluation
- **Test Framework Integration** - `cake test:cs3` validates CS3 against full test suite
- **JSX-free Grammar** - Cleaner, focused on core CoffeeScript features

### ✅ Complete Implementation
- **Test Suite Compatibility** - 100% pass rate (455/455 tests)
- **All language features** - Complete support for all CoffeeScript syntax
- **@params in destructuring** - Full support including `{@x, @y}` patterns
- **Super calls** - Working in all contexts including arrow functions
- **Performance** - Completely revamped parser/AST generation with no performance loss

### 📋 TODO
- Complete additional backend implementations (Python, WASM, LLVM)
- Source map support for debugging
- AST explorer tool for visualization
- Plugin system for custom backends
- Performance benchmarking suite

## ES6 Output Support

CS3 defaults to modern ES6+ JavaScript output with full support for:

### Variable Declarations
- **`const` for functions and classes** - Function and class declarations use `const` for immutability
- **`let` instead of `var`** - All other variables use `let` for proper block scoping
- **Block scoping** - Variables respect block boundaries

### Modern JavaScript Features
- **ES6 Classes** - Native `class` syntax with constructors and methods
- **Arrow functions** - Fat arrow methods compile to ES6 arrow functions
- **Template literals** - Backtick strings with `${interpolation}`
- **`for...of` loops** - Clean iteration over arrays and iterable objects
  ```javascript
  // CS3 compiles to:
  for (x of array) { ... }
  for (key of Object.keys(obj)) { ... }
  ```

### Destructuring & Spread
- **Object destructuring** - `{a, b} = obj`
- **Array destructuring** - `[first, ...rest] = array`
- **Spread operator** - Works in arrays, objects, and function calls

### Async Programming
- **Async/await** - First-class support for async functions
- **Promises** - Full promise chain support

### Usage
The ES6 backend is enabled by default in CS3. For explicit control:
```bash
coffee --cs3 --es6 script.coffee  # Explicit ES6 output
coffee --cs3 script.coffee        # Default (ES6)
```

## Key Innovation

CS3's approach is **revolutionary**: **Solar directives** provide universal, language-agnostic AST representation!

This means:
- **Direct directive consumption** - backends process Solar directives without normalization
- **Universal target support** - any language can consume Solar directives
- **Parser generator agnostic** - Solar directives work with any grammar
- **Zero intermediate formats** - clean, minimal data pipeline

## CS3 Solar Directive System

The CS3 Solar Directive System provides a universal, language-agnostic approach to AST representation using just 4 core directives.

**Key Insight**: These directives are **imperative instructions** to the backend - they tell it what to DO with the data, not what the data IS. This is fundamental to CS3's data-oriented architecture.

### Core Directives

Each directive is an **action verb** that instructs the backend:

- **`$ast`** → "**Create** an AST node"
- **`$ary`** → "**Build** an array"
- **`$ops`** → "**Perform** an operation"
- **`$use`** → "**Use** this value"

This imperative design makes the transformation pipeline explicit and universal.

#### 1. `$ast` - Create AST Nodes

Creates Abstract Syntax Tree nodes with a type and properties.

```coffee
# Basic syntax
$ast: 'NodeType', property1: value1, property2: value2

# Examples
$ast: 'If', condition: 1, body: 2              # Create If node
$ast: 'Value', val: 1                          # Create Value node with val property
$ast: 'Class', variable: 2, parent: 4          # Create Class node
$ast: 'Op', operator: '+', left: 1, right: 2   # Create operator node
$ast: '@', name: 1                             # Use rule name as node type
```

#### 2. `$ary` - Create Arrays

Creates arrays and can attach properties to them.

```coffee
# Basic syntax
$ary: [elements...]                  # Array with elements
$ary: position                       # Array from position reference
$ary: position, property: value      # Array with attached properties

# Examples
$ary: []                             # Empty array
$ary: [1, 2, 3]                      # Array from positions 1, 2, 3
$ary: 2                              # Use value at position 2 as array
$ary: 2, implicit: true              # Array with implicit property
$ary: [1], length: {$use: 2}         # Array with dynamic property
```

#### 3. `$ops` - Apply Operations

Performs categorized operations on existing values.

```coffee
# Basic syntax
$ops: 'category', operation: parameters

# Categories and operations
$ops: 'array', append: [1, 2]        # Array operations
$ops: 'array', gather: [1, 2, 3]     # Flatten and append

$ops: 'value', add: [1, 2]           # Add accessor to value
$ops: 'if', addElse: [1, 2]          # Add else branch to if

$ops: 'loop', addBody: [1, 2]        # Add body to loop
$ops: 'loop', addSource: [1, 2]      # Add source to loop
$ops: 'loop', addBody: [1, 2], postfix: true  # Postfix loop

$ops: 'prop', set: {target: 1, property: 'name', value: 2}  # Set property
```

#### 4. `$use` - Reference Values

References values from the parse stack or accesses their properties and methods.

```coffee
# Basic syntax
$use: position                        # Reference by position (1-based)
$use: position, prop: 'property'     # Access property
$use: position, method: 'name'        # Call method
$use: position, method: 'name', args: [...]  # Call with arguments
$use: position, index: n              # Array index access

# Examples
$use: 1                               # Value at position 1
$use: 2, prop: 'value'                # $2.value
$use: 1, method: 'toString'           # $1.toString()
$use: 1, method: 'slice', args: [0, -1]  # $1.slice(0, -1)
$use: 3, index: 0                     # $3[0]
```

### Metadata Directive

#### `$pos` - Position Tracking

Tracks source code location for error reporting and source maps.

```coffee
$pos: 1                               # Copy position from element 1
$pos: [1, 3]                          # Span from element 1 to 3
$pos: [line, col, endLine, endCol]   # Explicit position
```

### Plain Objects

Properties without directives create plain objects:

```coffee
# No directive needed for plain objects
name: 1, value: 2                    # {name: $1, value: $2}
soak: true, optional: false          # {soak: true, optional: false}
```

### Common Patterns

#### Creating Nodes with Properties

```coffee
# If statement with condition and body
$ast: 'If', condition: {$use: 1}, body: {$use: 2}

# Class with inheritance
$ast: 'Class', variable: {$use: 2}, parent: {$use: 4}

# Function with parameters and body
$ast: 'Code', params: {$ary: 1}, body: {$use: 2}
```

#### Building Complex Structures

```coffee
# Nested value with property access
$ast: 'Value', val: {$ast: 'IdentifierLiteral', value: 'foo'},
               properties: [{$ast: 'Access', name: 'bar'}]

# Array with mixed elements
$ary: [{$use: 1}, {$ast: 'Literal', value: 0}, {$use: 3}]

# Operations building loops
$ops: 'loop', addBody: [{$ast: 'For', source: 1}, 2]
```

#### Control Flow

```coffee
# If-else statement
$ast: 'If', condition: 1, body: 2, elseBody: 3

# While loop
$ast: 'While', condition: 1, body: 2

# For loop
$ast: 'For', body: 1, source: 2, name: 3

# Postfix while
$ops: 'loop', addBody: [2, 1], postfix: true
```

#### Operations by Category

##### Array Operations
- `append` - Add elements to array
- `gather` - Append with flattening

##### Value Operations
- `add` - Add accessor/property to value

##### If Operations
- `addElse` - Add else branch

##### Loop Operations
- `addBody` - Set loop body
- `addSource` - Set loop source
- `postfix` - Mark as postfix form

##### Property Operations
- `set` - Set object property

### Design Principles

1. **Universality**: Works for any programming language
2. **Simplicity**: Just 4 directives handle all cases
3. **Composability**: Directives combine naturally
4. **Readability**: Intent is always clear
5. **Consistency**: Uniform patterns throughout
6. **Imperative Nature**: Directives are instructions ("do this"), not descriptions ("this is")

### Grammar Rule Examples

```coffee
# Simple passthrough
Identifier: [
  o 'IDENTIFIER', $use: 1
]

# Creating AST nodes
SimpleAssignable: [
  o 'Identifier', $ast: 'Value', val: 1
]

# Using operations
While: [
  o 'WhileSource Block', $ops: 'loop', addBody: [1, 'Body $2']
  o 'Statement WhileSource', $ops: 'loop', addBody: [2, [1]], postfix: true
]

# Arrays with properties
Arguments: [
  o 'CALL_START CALL_END', $ary: [{}]
  o 'CALL_START ArgList CALL_END', $ary: 2, implicit: true
]

# Complex transformations
Class: [
  o 'CLASS SimpleAssignable', $ast: 'Class', variable: 2
  o 'CLASS SimpleAssignable EXTENDS Value', $ast: 'Class', variable: 2, parent: 4
  o 'CLASS EXTENDS Value Block', $ast: 'Class', parent: 3, body: 4
]
```

### Implementation Notes

- Position references are 1-based (1 = first element)
- Arrays are deeply flattened when used as arguments
- Properties on arrays are preserved through operations
- The `@` symbol in `$ast: '@'` uses the grammar rule name as the node type
- All directives evaluate recursively

### Backend Requirements

A Solar backend must implement:

1. **Directive evaluation**: Process `$ast`, `$ary`, `$ops`, `$use`
2. **Position references**: Handle 1-based stack positions
3. **Property/method access**: Support `$use` with prop/method/index
4. **Operations**: Implement categorized operations
5. **Metadata**: Track `$pos` for source mapping

### Directive System Summary

The CS3 Solar Directive System achieves complete AST transformation with minimal complexity:

- **4 directives** handle all transformations
- **Categorized operations** provide type safety
- **Clean syntax** makes intent obvious
- **Universal design** works for any target language
- **No special cases** - everything follows the same patterns
- **Ultra-compact output** - Single-line rules with efficient `r` function aliasing
- **Optimized frame construction** - Flattened arrays without redundant wrappers

This architecture enables CoffeeScript 3 to maintain 100% compatibility while providing a clean, maintainable, and extensible foundation for future development. The imperative directive system makes it crystal clear that we're building **data structures that describe transformations**, not executing code during parsing. This architectural honesty is what enables CS3 to target any backend - the directives are universal instructions that any language can interpret and execute.

## The Future: Rip

CoffeeScript 3 is a stepping stone toward **Rip**, a truly universal programming language that:
- Builds on CS3's data-oriented foundation
- Targets multiple platforms natively
- Provides seamless interop with any host platform
- Enables true "write once, run anywhere"

## Getting Started

```bash
# Build everything (parsers and backend)
cake build

# Test CS3 pipeline (455/455 tests passing - 100%!)
cake test:cs3

# View the Solar directive grammar
cat src/syntax.coffee

# Read the full specification (now included in this README)
# See the "CS3 Solar Directive System" section below
```

### Quick Start for New Contributors

1. **Understand the transformation**: Read the **CS3 Solar Directive System** section below for the complete directive system
2. **Compare the grammars**: Open `src/grammar.coffee` (old) and `src/syntax.coffee` (new) side by side
3. **See it in action**: Look at the `Class` rule transformation as a representative example
4. **Key insight**: We're not changing WHAT the grammar does, just HOW it's expressed (functions → data)

## Contributing

CS3 is an ambitious project that needs community involvement:

1. **Backend Development** - Help implement Python, WASM, or other backends
2. **Testing** - Ensure compatibility with existing CoffeeScript code
3. **Tooling** - Build AST explorers, linters, and development tools
4. **Documentation** - Improve examples and migration guides

## Philosophy

> "Make the common case easy, and the rare case possible."

> "The best abstractions are those that hide complexity while revealing possibility."

> "Every language should compile to every platform." - The Rip Manifesto

## Learn More

- **CS3 Solar Directive System** - Complete specification (see section above)
- **[src/syntax.coffee](src/syntax.coffee)** - The transformed data-oriented grammar

---

*CoffeeScript 3: Where elegant syntax meets universal compilation.*

### CS3/ES5 Backend Status - 100% Pass Rate!

**Complete Feature Support:**
- ✅ All CoffeeScript syntax fully supported
- ✅ Classes with static properties and inheritance
- ✅ Arrow functions generating proper ES6 syntax
- ✅ String interpolation and template literals
- ✅ Exception handling (try/catch/finally)
- ✅ Destructuring with @ parameters
- ✅ Super calls in all contexts
- ✅ Nested loops and comprehensions
- ✅ For-own loops
- ✅ Async/await and generators
- ✅ All edge cases handled

**Test Results:**
- 455/455 tests passing (100%)
- Complete compatibility with CoffeeScript 2
- Production-ready implementation