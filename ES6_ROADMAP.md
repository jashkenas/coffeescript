# ES6 Backend Roadmap for CoffeeScript 3.0

## Executive Summary

CoffeeScript already outputs ES6 for most features. We need minimal changes to achieve full ES6 output, making CS 3.0 a complete modernization with the Solar parser + ES6 backend.

## Current State Analysis

### Already ES6 ✅
- ES6 classes with `class` keyword
- Template literals for string interpolation
- Destructuring (array & object)
- Default parameters
- Arrow functions (for `=>`)
- Async/await
- Spread operator (`...`)
- Shorthand object properties

### Still ES5 ❌
- `var` declarations instead of `let`/`const`
- C-style `for` loops instead of `for...of`
- Regular `function` for `->` (not arrow functions)

## Implementation Strategy: Minimal Flag Approach

### Why This Approach?
- **Minimal Changes**: ~100 lines of code modifications
- **Leverages Existing**: 90% of ES6 features already working
- **Single Codebase**: No duplicate backend maintenance
- **Fast Delivery**: 1-2 days of work
- **Easy Testing**: Run all 455 tests with `es6: true` flag

### Implementation Plan

#### Phase 1: Add ES6 Flag to Backend (30 minutes)
```coffee
# backends/es5/index.coffee
class ES5Backend  # Keep the name for now
  constructor: (@options = {}) ->
    @compileOptions =
      bare: @options.bare ? true
      cs3: true
      es6: @options.es6 ? false  # NEW: ES6 output mode flag
```

#### Phase 2: Variable Declarations (2-3 hours)

**File**: `src/nodes.coffee`

1. **Modify `Assign.compileNode`**:
   ```coffee
   # Current: Always outputs "var"
   # Change: Check o.es6 flag
   if o.es6
     @makeCode(if @isConst() then "const " else "let ")
   else
     @makeCode("var ")
   ```

2. **Add const detection logic**:
   - Variables assigned once → `const`
   - Variables reassigned → `let`
   - Use scope tracking to determine reassignment

#### Phase 3: For Loops (2-3 hours)

**File**: `src/nodes.coffee`

1. **Modify `For.compileNode`** for array iteration:
   ```coffee
   if o.es6 and @array
     # Output: for (const item of array)
     # Instead of: for (i = 0, len = arr.length; i < len; i++)
   ```

2. **Range loops**:
   ```coffee
   if o.es6
     # Keep numeric ranges as for loops (more efficient)
     # for (let i = start; i <= end; i++)
   ```

3. **Object iteration**:
   ```coffee
   if o.es6
     # for (const key of Object.keys(obj))
     # Instead of: for (key in obj)
   ```

#### Phase 4: Optional - Arrow Functions for `->` (4-6 hours)

**Consideration**: This is more complex due to `this` binding differences

1. **Safe cases** (can use arrow):
   - Functions that don't reference `this`
   - Functions that don't use `arguments`
   - Functions that aren't constructors

2. **Implementation**:
   ```coffee
   if o.es6 and @canUseArrow()
     # Output: (x) => x * 2
   else
     # Output: function(x) { return x * 2; }
   ```

## Testing Strategy

### Test Suite Validation
1. Run all 455 CS3 tests with `es6: false` (baseline)
2. Run all 455 CS3 tests with `es6: true`
3. Compare outputs - should be functionally identical

### Specific Test Cases
Create `test/34-es6-output.test.coffee`:
- Variable declarations (`const`, `let`)
- For...of loops
- Template literals (already working)
- Classes (already working)
- Async/await (already working)

## Command Line Integration

### Add ES6 Flag to CLI
```coffee
# src/command.coffee
.option '-6, --es6', 'compile to ES6 JavaScript'
```

### Usage Examples
```bash
coffee --es6 script.coffee       # ES6 output
coffee script.coffee              # ES5 output (default for now)
coffee --es6 --compile *.coffee  # Batch compile to ES6
```

## Build System Updates

### Cakefile Tasks
```coffee
task 'build:es6', 'build with ES6 output', ->
  # Compile CS3 internals with ES6 flag

task 'test:es6', 'run tests with ES6 output', ->
  # Run test suite with ES6 backend
```

## Migration Path

### Phase 1: CS 3.0 Release (This Week)
- ES6 flag available but not default
- Documentation shows both ES5 and ES6 examples
- Encourages testing with `--es6` flag

### Phase 2: CS 3.1 (Future)
- Make ES6 the default
- ES5 available via `--es5` flag
- Deprecation notice for ES5

### Phase 3: CS 4.0 (Far Future)
- Remove ES5 backend entirely
- ES6+ only output

## Documentation Updates

### README.md
- Add ES6 backend to feature list
- Show ES6 output examples
- Document `--es6` flag

### Website
- Toggle for ES5/ES6 output examples
- Migration guide from ES5 to ES6

## Success Criteria

✅ All 455 tests pass with `es6: true`
✅ Generated ES6 code runs in Node 14+
✅ No performance regression
✅ Clean, idiomatic ES6 output
✅ Documentation updated

## Timeline Estimate

- **Day 1**:
  - Morning: Implement ES6 flag + variable declarations
  - Afternoon: Implement for...of loops

- **Day 2**:
  - Morning: Testing & debugging
  - Afternoon: Documentation & CLI integration

**Total: 1-2 days for core ES6 support**

## Future Enhancements (Post CS 3.0)

- Optional chaining (`?.`)
- Nullish coalescing (`??`)
- Private class fields (`#field`)
- Static class fields
- Dynamic imports
- BigInt literals
- Numeric separators

## Conclusion

The ES6 backend is the final piece for CoffeeScript 3.0. With the Solar parser architecture and ES6 output, CS3 becomes a fully modern compiler. After this release, the path is clear for Rip development.

**The code is already 90% there. We just need to flip a few switches.**
