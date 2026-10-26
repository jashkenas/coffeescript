**Scope** is a base class for scoping behaviors, covering both lexical and
function scope.

    exports.Scope = class Scope

      constructor: ({@lexParent}) ->
        throw new TypeError 'parent key must be provided, even if null' if typeof @lexParent is 'undefined'

The `@root` is the top-level **TopLevelScope** object for a given file. Similarly,
the `@varParent` is the enclosing `var` scope (either top-level, or function
scope). The `@lexParent` is the enclosing block scope, which may be a function scope,
or the top level.

        if @lexParent?
          throw new TypeError "parent must be null or Scope: #{@lexParent}" unless @lexParent instanceof Scope
          @root = @lexParent.root
          @varParent = if @lexParent instanceof VarScope
            @lexParent
          else
            @lexParent.varParent
          throw new TypeError "an enclosing var scope key must be provided: #{@varParent}/#{@lexParent}" unless @varParent instanceof VarScope
        else
          throw new TypeError "if parent is null, this must be a TopLevelScope: #{@}" unless @ instanceof TopLevelScope
          @root = @
          @varParent = null

        throw new TypeError "a top-level root key must be provided: #{@root}/#{@lexParent}" unless @root instanceof TopLevelScope

This method returns the current function scope, which may contain any number of
internal lexical/block scopes. This method always succeeds, unlike
`VarScope#tryAsFunctionScope()`.

      asVarScope: -> if @ instanceof VarScope then @ else @varParent

The **VarScope** class regulates lexical scoping within CoffeeScript. As you
generate code, you create a tree of scopes in the same shape as the nested
function bodies. Each scope knows about the variables declared within it,
and has a reference to its parent enclosing scope. In this way, we know which
variables are new and need to be declared with `var`, and which are shared
with external scopes.

    exports.VarScope = class VarScope extends Scope

      constructor: ({lexParent}) ->
        super {lexParent}

        @variables = new Map
        @comments  = {}

Return whether a variable was declared by the given name in exactly this scope,
without checking any parents.

      hasName: (name) -> @variables.has name

Retrieves the `spec` data stored from a prior `@internNew(name, spec)` invocation, or
`undefined`.

      getSpec: (name) -> @variables.get name

Determine whether a proposed new specification for the name binding should overwrite
the previous value.

      overwriteSpec: (name, newSpec) ->
        prevSpec = @getSpec name

        @variables.set name, newSpec
        return

If the types are the same, we have nothing to do.

        if prevSpec.type is newSpec.type
          return

If a variable was previously referenced within the body of a scope, but it was registered via `utilities` as e.g. a polyfill with special meaning (like `indexOf`), then overwrite the specification.

        if prevSpec.type is 'var' and newSpec.type is 'assigned'
          @variables.set name, newSpec
          return

Otherwise, we do not accept the modification (this should never occur).

        throw new Error "decl with type '#{newSpec}' named '#{name}' was already reserved with type '#{prevSpec}'"

Internal method to add a new variable to the scope, erroring if already seen (this
should never happen).

      internNew: (name, spec) ->
        if @varParent? and @delegateToParent
          return @varParent.internNew name, spec
        throw new Error "already interned existing name '#{name}'" if @variables.has name
        @variables.set name, spec
        @

Just check to see if a variable has already been declared, without reserving,
walks up to the root scope.

      check: (name) -> @hasName(name) or @varParent?.check(name)

Like `check()`, but returns the registered specification. This can be used to
introspect based upon the type of declaration assigned to the given name. For
example, imported symbols from the top-level scope cannot be assigned to at
runtime, so we also verify this at compile-time.

      checkSpec: (name) -> @getSpec(name) ? @varParent?.checkSpec(name)

Adds a new variable or overrides an existing one.

      add: (name, spec, immediate) ->
        if @varParent? and @shared and not immediate
          return @varParent.add name, spec, immediate
        if @hasName name
          return @overwriteSpec name, spec
        @internNew name, spec

Look up a variable name in lexical scope, and declare it if it does not
already exist.

**TODO: "find" is an extremely misleading name, as is "check".** Neither of them
indicate whether they mutate the scope data structure, nor even whether their
search is recursive or single-level.

      find: (name, type = 'var') ->
        return yes if @check name
        @add name, {type}
        no

Reserve a variable name as originating from a function parameter, or seeded from the
`locals` argument at top level. No `var` required for internal references.

      parameter: (name) ->
        return if @shared and @varParent?.check name
        @add name, {type: 'param'}

Generate a temporary variable name at the given index.

      @temporary: (name, index, single = no) =>
        throw new TypeError "invalid single arg: #{single}" unless typeof single is 'boolean'
        return "#{name}#{index or ''}" unless single

        startCode = name.charCodeAt(0)
        endCode = 'z'.charCodeAt(0)
        diff = endCode - startCode
        newCode = startCode + index % (diff + 1)
        letter = String.fromCharCode(newCode)
        num = index // (diff + 1)
        "#{letter}#{num or ''}"

If we need to store an intermediate result, find an available name for a
compiler-generated variable. `_var`, `_var2`, and so on...

      freeVariable: (name, {single, reserve}={}) ->
        reserve ?= yes
        index = 0
        loop
          temp = @constructor.temporary name, index, single
          break unless @check(temp) or @root.referencedVars.has(temp)
          index++
        @add temp, {type: 'var'}, yes if reserve
        temp

Ensure that an assignment is made at the top of this scope
(or at the top-level scope, if requested).

      assign: (name, value) ->
        @add name, {type: 'assigned', value}, yes
        @hasAssignments = yes

Does this scope have any declared variables?

Note that this is computed dynamically, *unlike* `@hasAssignments`, because a `'var'`
can be overwritten later with `.overwriteSpec()`!

      hasDeclarations: -> not @declaredVariables().next().done

Return the list of variables first declared in this scope.

      declaredVariables: -> yield name for [name, spec] from @variables when spec.type is 'var'

Return the list of assignments that are supposed to be made at the top
of this scope.

      assignedVariables: ->
        "#{name} = #{value}" for [name, {type, value}] from @variables when type is 'assigned'

Try downcasting this scope to a function scope. This will fail at the top level,
for example.

      tryAsFunctionScope: -> if @ instanceof FunctionScope then @ else null

A function scope is much more common than the top-level scope, and has a few extras,
including (often) a method name, and a provided `arguments` parameter.

    exports.FunctionScope = class FunctionScope extends VarScope

Initialize a scope with its parent, for lookups up the chain,
as well as a reference to the **Block** node it belongs to, which is
where it should declare its variables, a reference to the function that
it belongs to, and a list of variables referenced in the source code
and therefore should be avoided when generating variables. Also track comments
that should be output as part of variable declarations.

      constructor: ({parent, @method}) ->
        throw new TypeError 'function scope is not top-level and must have parent' unless parent?
        super {lexParent: parent}
        @variables.set 'arguments', {type: 'arguments'}

When `super` is called, we need to find the name of the current method we're
in, so that we know how to invoke the same method of the parent class. This
can get complicated if super is being called from an inner function.
`namedMethod` will walk up the scope tree until it either finds the first
function object that has a name filled in, or bottoms out.

      namedMethod: -> if @method.name then @method
      else @varParent.tryAsFunctionScope()?.namedMethod()

This is a variant of function scope that appears when adding statements to be
executed within class bodies. It is compiled to a regular IIFE.

    exports.ExecutableClassBodyScope = class ExecutableClassBodyScope extends FunctionScope

      constructor: ({parent, method, @class}) ->
        super {parent, method}

A scope without any IIFE wrapping, suitable for declaring imports and exports.

    exports.TopLevelScope = class TopLevelScope extends VarScope

      constructor: ({referencedVars, @block}) ->
        super {lexParent: null}

        @referencedVars = new Set referencedVars
        @utilities = new Map

In addition to tracking var-scope symbols, we also now track which symbols have
been imported and exported. This allows us to identify situations which would
otherwise produce a runtime error, as well as avoid confusion between var and
imported declarations.

        @importedSymbols = new Set
        @exportedSymbols = new Set
        @defaultExportWasSet = no

      @addNew: (set, element) => if set.has element then yes
      else
        set.add element
        no

These methods add a new symbol to the import or export tables.

      tryNewImport: (name) -> not @find(name, 'import') and
                              not @constructor.addNew(@importedSymbols, name)
      tryNewExport: (name) -> not @constructor.addNew(@exportedSymbols, name)
      tryDefaultExport: -> if @defaultExportWasSet then no else @defaultExportWasSet = yes

Mark given local variables in the root scope as parameters so they don’t
end up being declared on the root block.

      @withLocals: ({block, referencedVars, locals}) ->
        ret = new @ {block, referencedVars}
        ret.parameter name for name in locals ? []
        ret

**ControlFlowScope** is recorded separately from **VarScope** instances, and will perform
the task of `const` and `let` allocation, while also making it easier for `import`
and `export` declarations to clearly identify when they're not at the top level
(e.g. within an `if` block).

    exports.ControlFlowScope = class ControlFlowScope extends Scope

      constructor: ({parent, @controlFlowConstruct}) ->
        super {lexParent: parent}

**BlockScope** is a control flow scope associated to a specific **Block**. Some
constructs like `switch` expressions have scoping that doesn't strictly conform to
a block.

    exports.BlockScope = class BlockScope extends ControlFlowScope

      constructor: ({parent, controlFlowConstruct, @block}) ->
        super {parent, controlFlowConstruct}

Class declarations are special (both in CoffeeScript and its compile output), so
class scoping is given its own class.

    exports.ClassDeclarationScope = class ClassDeclarationScope extends Scope

      constructor: ({parent, @class}) ->
        super {lexParent: parent}
