# Some helper functions

# TODO -- shallow (1 deep) flatten..
# need recursive version..
flatten: (aggList, newList) ->
  for item in newList
    aggList.push(item)
  aggList

compact: (input) ->
  compected: []
  for item in input
    if item?
      compacted.push(item)

dup: (input) ->
  output: null
  if input instaceof Array
    output: []
    for val in input
      output.push(val)
  else
    output: {}
    for key, val of input
      output.key: val
    output
  output

# The abstract base class for all CoffeeScript nodes.
# All nodes are implement a "compile_node" method, which performs the
# code generation for that node. To compile a node, call the "compile"
# method, which wraps "compile_node" in some extra smarts, to know when the
# generated code should be wrapped up in a closure. An options hash is passed
# and cloned throughout, containing messages from higher in the AST,
# information about the current scope, and indentation level.
exports.Node: -> this.values: arguments

exports.Node::TAB: '  '

# Tag this node as a statement, meaning that it can't be used directly as
# the result of an expression.
exports.Node::mark_as_statement: ->
  this.is_statement: -> true

# Tag this node as a statement that cannot be transformed into an expression.
# (break, continue, etc.) It doesn't make sense to try to transform it.
exports.Node::mark_as_statement_only: ->
  this.mark_as_statement()
  this.is_statement_only: -> true

# This node needs to know if it's being compiled as a top-level statement,
# in order to compile without special expression conversion.
exports.Node::mark_as_top_sensitive: ->
  this.is_top_sensitive: -> true

# Provide a quick implementation of a children method.
exports.Node::children: (attributes) ->
  # TODO -- are these optimal impls of flatten and compact
  # .. do better ones exist in a stdlib?
  agg: []
  for item in attributes
    agg: flatten agg, item
  compacted: compact agg
  this.children: ->
    compacted

exports.Node::write: (code) ->
  # hm.. 
  # TODO -- should print to STDOUT in "VERBOSE" how to
  # go about this.. ? jsonify 'this'?
  # use node's puts ??
  code

# This is extremely important -- we convert JS statements into expressions
# by wrapping them in a closure, only if it's possible, and we're not at
# the top level of a block (which would be unnecessary), and we haven't
# already been asked to return the result.
exports.Node::compile: (o) ->
  # TODO -- need JS dup/clone
  opts: if not o? then {} else o
  this.options: opts
  this.indent: opts.indent
  top: this.options.top
  if not this.is_top_sentitive()
    this.options.top: undefined
  closure: this.is_statement() and not this.is_statement_only() and not top and typeof(this) == "CommentNode"
  closure &&= not this.do_i_contain (n) -> n.is_statement_only()
  if closure then this.compile_closure(this.options) else compile_node(this.options)

# Statements converted into expressions share scope with their parent
# closure, to preserve JavaScript-style lexical scope.
exports.Node::compile_closure: (o) ->
  opts: if not o? then {} else o
  this.indent: opts.indent
  opts.shared_scope: o.scope
  exports.ClosureNode.wrap(this).compile(opts)

# Quick short method for the current indentation level, plus tabbing in.
exports.Node::idt: (tLvl) ->
  tabs: if tLvl? then tLvl else 0
  tabAmt: ''
  for x in [0...tabs]
    tabAmt: tabAmt + this.TAB
  this.indent + tabAmt

#Does this node, or any of it's children, contain a node of a certain kind?
exports.Node::do_i_contain: (block) ->
  for node in this.children
    return true if block(node)
    return true if node instanceof exports.Node and node.do_i_contain(block)
  false

# Default implementations of the common node methods.
exports.Node::unwrap: -> this
exports.Node::children: []
exports.Node::is_a_statement: -> false
exports.Node::is_a_statement_only: -> false
exports.Node::is_top_sensitive: -> false

# A collection of nodes, each one representing an expression.
exports.Expressions: (nodes) ->
  this.mark_as_statement()
  this.expressions: []
  this.children([this.expressions])
  for n in nodes
    this.expressions: flatten this.expressions, n
exports.Expressions extends exports.Node

exports.Expressions::TRAILING_WHITESPACE: /\s+$/

# Wrap up a node as an Expressions, unless it already is.
exports.Expressions::wrap: (nodes) ->
  return nodes[0] if nodes.length == 1 and nodes[0] instanceof exports.Expressions
  new Expressions(nodes)

# Tack an expression on to the end of this expression list.
exports.Expressions::push: (node) ->
  this.expressions.push(node)
  this

# Tack an expression on to the beginning of this expression list.
exports.Expressions::unshift: (node) ->
  this.expressions.unshift(node)
  this

# If this Expressions consists of a single node, pull it back out.
exports.Expressions::unwrap: ->
  if this.expressions.length == 1 then this.expressions[0] else this

# Is this an empty block of code?
exports.Expressions::is_empty: ->
  this.expressions.length == 0

# Is the node last in this block of expressions.
exports.Expressions::is_last: (node) ->
  arr_length: this.expressions.length
  this.last_index ||= if this.expressions[arr_length - 1] instanceof exports.CommentNode then -2 else -1
  node == this.expressions[arr_length - this.last_index]

exports.Expressions::compile: (o) ->
  opts: if o? then o else {}
  if opts.scope then super(dup(opts)) else this.compile_root(o)

# Compile each expression in the Expressions body.
exports.Expressions::compile_node: (options) ->
  opts: if options? then options else {}
  compiled: []
  for e in this.expressions
    compiled.push(this.compile_expression(e, dup(options)))
  code: ''
  for line in compiled
    code: code + line + '\n'

# If this is the top-level Expressions, wrap everything in a safety closure.
exports.Expressions::compile_root: (o) ->
  opts: if o? then o else {}
  indent: if opts.no_wrap then '' else this.TAB
  this.indent: indent
  opts.indent: indent
  opts.scope: new Scope(null, this, null)
  code: if opts.globals then compile_node(opts) else compile_with_declarations(opts)
  code.replace(this.TRAILING_WHITESPACE, '')
  this.write(if opts.no_wrap then code else "(function(){\n"+code+"\n})();")

# Compile the expressions body, with declarations of all inner variables
# at the top.
exports.Expressions::compile_with_declaractions: (o) ->
  opts: if o? : o else {}
  code: this.compile_node(opts)
  args: this.do_i_contain (n) -> n instanceof LiteralNode and n.arguments?
  argv: if args and opts.scope.arguments then '' else 'var '
  code: this.idt() + argv+"arguments = Array.prototype.slice.call(arguments, 0);\n"+code if args
  code: this.idt() + "var "+opts.scope.compiled_assignments+";\n"+code if o.scope.has_assignments(this)
  this.write(code)

    # Compiles a single expression within the expression list.
    def compile_expression(node, o)
      @indent = o[:indent]
      stmt    = node.statement?
      # We need to return the result if this is the last node in the expressions body.
      returns = o.delete(:return) && last?(node) && !node.statement_only?
      # Return the regular compile of the node, unless we need to return the result.
      return "#{stmt ? '' : idt}#{node.compile(o.merge(:top => true))}#{stmt ? '' : ';'}" unless returns
      # If it's a statement, the node knows how to return itself.
      return node.compile(o.merge(:return => true)) if node.statement?
      # If it's not part of a constructor, we can just return the value of the expression.
      return "#{idt}return #{node.compile(o)};" unless o[:scope].function && o[:scope].function.constructor?
      # It's the last line of a constructor, add a safety check.
      temp = o[:scope].free_variable
      "#{idt}#{temp} = #{node.compile(o)};\n#{idt}return #{o[:scope].function.name} === this.constructor ? this : #{temp};"
    end

  end


exports.LiteralNode : exports.Node
exports.ReturnNode : exports.Node
exports.CommentNode : exports.Node
exports.CallNode : exports.Node
exports.ExtendsNode : exports.Node
exports.ValueNode : exports.Node
exports.AccessorNode : exports.Node
exports.IndexNode : exports.Node
exports.RangeNode : exports.Node
exports.SliceNode : exports.Node
exports.AssignNode : exports.Node
exports.OpNode : exports.Node
exports.CodeNode : exports.Node
exports.SplatNode : exports.Node
exports.ObjectNode : exports.Node
exports.ArrayNode : exports.Node
exports.PushNode : exports.Node
exports.ClosureNode : exports.Node
exports.WhileNode : exports.Node
exports.ForNode : exports.Node
exports.TryNode : exports.Node
exports.ThrowNode : exports.Node
exports.ExistenceNode : exports.Node
exports.ParentheticalNode : exports.Node
exports.IfNode : exports.Node


