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

flatten: (aggList, newList) ->
  for item in newList
    aggList.push(item)
  aggList

compact: (input) ->
  compected: []
  for item in input
    if item?
      compacted.push(item)

# Provide a quick implementation of a children method.
exports.Node::children: (attributes) ->
  # TODO -- are these optimal impls of flatten and compact
  # .. do better ones exist in a stdlib?
  agg = []
  for item in attributes
    agg: flatten agg, item
  compacted: compact agg
  this.children: ->
    compacted

exports.Node::write: (code) ->
  # hm.. 
  # TODO -- should print to STDOUT in "VERBOSE" how to
  # go about this.. ? jsonify 'this'?
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

exports.Node::is_a_node: ->
  true

#Does this node, or any of it's children, contain a node of a certain kind?
exports.Node::do_i_contain: (block) ->
  for node in this.children
    return true if block(node)
    return true if node.is_a_node() and node.do_i_contain(block)
  false

# Default implementations of the common node methods.
exports.Node::unwrap: -> this
exports.Node::children: []
exports.Node::is_a_statement: -> false
exports.Node::is_a_statement_only: -> false
exports.Node::is_top_sensitive: -> false

exports.Expressions : exports.Node
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


