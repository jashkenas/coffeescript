The **Scope** class regulates lexical scoping within CoffeeScript. As you
generate code, you create a tree of scopes in the same shape as the nested
function bodies. Each scope knows about the variables declared within it,
and has a reference to its parent enclosing scope. In this way, we know which
variables are new and need to be declared with `var`, and which are shared
with external scopes.

    exports.Scope = class Scope

Initialize a scope with its parent, for lookups up the chain,
as well as a reference to the **Block** node it belongs to, which is
where it should declare its variables, a reference to the function that
it belongs to, and a list of variables referenced in the source code
and therefore should be avoided when generating variables. Also track comments
that should be output as part of variable declarations.

      constructor: (@parent, @expressions, @method, @referencedVars) ->
        @variables = [{name: 'arguments', type: 'arguments'}]
        @positions = {}
        @utilities = {} unless @parent

The `@root` is the top-level **Scope** object for a given file.

        @root = @parent?.root ? this

Adds a new variable or overrides an existing one.

      add: (name, type, immediate) ->
        return @parent.add name, type, immediate if @shared and not immediate
        if variable = @get name
          variable.type = type
        else
          @positions[name] = @variables.push({name, type}) - 1

When `super` is called, we need to find the name of the current method we're
in, so that we know how to invoke the same method of the parent class. This
can get complicated if super is being called from an inner function.
`namedMethod` will walk up the scope tree until it either finds the first
function object that has a name filled in, or bottoms out.

      namedMethod: ->
        return @method if @method?.name or !@parent
        @parent.namedMethod()

Look up a variable name in lexical scope, and declare it if it does not
already exist.

      find: (name, type = 'var') ->
        return yes if @check name
        @add name, type
        no

Reserve a variable name as originating from a function parameter for this
scope. No `var` required for internal references.

      parameter: (name) ->
        return if @shared and @parent.check name
        @add name, 'param', yes

Just check to see if a variable has already been declared, without reserving,
walks up to the root scope.

      check: (name) ->
        @get(name)? or @parent?.check(name)

Generate a temporary variable name at the given index.

      temporary: (name, index, single=false) ->
        if single
          startCode = name.charCodeAt(0)
          endCode = 'z'.charCodeAt(0)
          diff = endCode - startCode
          newCode = startCode + index % (diff + 1)
          letter = String.fromCharCode(newCode)
          num = index // (diff + 1)
          "#{letter}#{num or ''}"
        else
          "#{name}#{index or ''}"

Gets a variable and its associated data from this scope (not ancestors),
or `undefined` if it doesn't exist.

      get: (name) ->
        @variables[@positions[name]] if Object::hasOwnProperty.call @positions, name

Gets the type of a variable declared in this scope,
or `undefined` if it doesn't exist.

      type: (name) ->
        @get(name)?.type

If we need to store an intermediate result, find an available name for a
compiler-generated variable. `_var`, `_var2`, and so on...

      freeVariable: (name, options={}) ->
        index = 0
        loop
          temp = @temporary name, index, options.single
          break unless @check(temp) or temp in @root.referencedVars
          index++
        @add temp, 'var', yes if options.reserve ? true
        @laterVar temp if options.laterVar
        temp

Ensure that an assignment is made at the top of this scope.

      assign: (name, value) ->
        @get(name).assigned = value

Add a comment that should appear when the variable is declared
(for Flow support).

      comment: (name, comments) ->
        @get(name).comments = comments

Does this variable have a comment attached to it in this scope?

      hasComment: (name) ->
        @get(name)?.comments?

Check whether a var declaration of this variable could go later, and if so,
mark it as so.

      laterVar: (name) ->
        # Ensure variable is declared at this scope, as a regular 'var', and
        # we haven't already given it a var prefix somewhere, and it doesn't
        # have an attachment that goes with a top var declaration.
        v = @get name
        later = v?.type is 'var' and
                not (v.laterVar or v.comments?)
        v.laterVar = yes if later
        later

Does this scope have any declared variables?

      hasDeclarations: ->
        return true for v in @variables when v.type is 'var' and not v.laterVar

Return a list of names of variables declared in this scope.
Optionally restrict to assigned or unassigned variables.

      declaredVariables: (assigned) ->
        (v.name for v in @variables when v.type is 'var' and not v.laterVar and
          switch assigned
            when true then v.assigned?
            when false then not v.assigned?
            else true
        ).sort()

Extract all variables from `start` onward.

      spliceVariables: (start) ->
        delete @positions[@variables[i]] for i in [start...@variables.length]
        @variables.splice start

Add variables to this scope, e.g. as returned from `spliceVariables`.

      addVariables: (vars) ->
        @positions[v.name] = @variables.push(v) - 1 for v in vars
