class Parser

# Declare terminal tokens produced by the lexer.
token IF ELSE UNLESS
token NUMBER STRING REGEX
token TRUE FALSE YES NO ON OFF
token IDENTIFIER PROPERTY_ACCESS PROTOTYPE_ACCESS SOAK_ACCESS
token CODE PARAM_START PARAM PARAM_END NEW RETURN
token CALL_START CALL_END INDEX_START INDEX_END
token TRY CATCH FINALLY THROW
token BREAK CONTINUE
token FOR IN OF BY WHEN WHILE
token SWITCH LEADING_WHEN
token DELETE INSTANCEOF TYPEOF
token SUPER EXTENDS
token ARGUMENTS
token NEWLINE
token COMMENT
token JS
token INDENT OUTDENT

# Declare order of operations.
prechigh
  left     '?'
  nonassoc UMINUS UPLUS NOT '!' '!!' '~' '++' '--'
  left     '*' '/' '%'
  left     '+' '-'
  left     '<<' '>>' '>>>'
  left     '&' '|' '^'
  left     '<=' '<' '>' '>='
  right    '==' '!=' IS ISNT
  left     '&&' '||' AND OR
  right    '-=' '+=' '/=' '*=' '%='
  right    DELETE INSTANCEOF TYPEOF
  left     '.'
  right    INDENT
  left     OUTDENT
  right    WHEN LEADING_WHEN IN OF BY
  right    THROW FOR NEW SUPER
  left     EXTENDS
  left     '||=' '&&=' '?='
  right    ASSIGN RETURN
  right    '->' '=>' UNLESS IF ELSE WHILE
preclow

rule

  # All parsing will end in this rule, being the trunk of the AST.
  Root:
    /* nothing */                     { result = Expressions.new }
  | Terminator                        { result = Expressions.new }
  | Expressions                       { result = val[0] }
  | Block Terminator                  { result = val[0] }
  ;

  # Any list of expressions or method body, seperated by line breaks or semis.
  Expressions:
    Expression                        { result = Expressions.wrap(val) }
  | Expressions Terminator Expression { result = val[0] << val[2] }
  | Expressions Terminator            { result = val[0] }
  ;

  # All types of expressions in our language. The basic unit of CoffeeScript
  # is the expression.
  Expression:
    Value
  | Call
  | Code
  | Operation
  | Assign
  | If
  | Try
  | Throw
  | Return
  | While
  | For
  | Switch
  | Extends
  | Splat
  | Existence
  | Comment
  ;

  # A block of expressions. Note that the Rewriter will convert some postfix
  # forms into blocks for us, by altering the token stream.
  Block:
    INDENT Expressions OUTDENT        { result = val[1] }
  | INDENT OUTDENT                    { result = Expressions.new }
  ;

  # Tokens that can terminate an expression.
  Terminator:
    "\n"
  | ";"
  ;

  # All hard-coded values. These can be printed straight to JavaScript.
  Literal:
    NUMBER                            { result = LiteralNode.new(val[0]) }
  | STRING                            { result = LiteralNode.new(val[0]) }
  | JS                                { result = LiteralNode.new(val[0]) }
  | REGEX                             { result = LiteralNode.new(val[0]) }
  | BREAK                             { result = LiteralNode.new(val[0]) }
  | CONTINUE                          { result = LiteralNode.new(val[0]) }
  | ARGUMENTS                         { result = LiteralNode.new(val[0]) }
  | TRUE                              { result = LiteralNode.new(Value.new(true)) }
  | FALSE                             { result = LiteralNode.new(Value.new(false)) }
  | YES                               { result = LiteralNode.new(Value.new(true)) }
  | NO                                { result = LiteralNode.new(Value.new(false)) }
  | ON                                { result = LiteralNode.new(Value.new(true)) }
  | OFF                               { result = LiteralNode.new(Value.new(false)) }
  ;

  # Assignment to a variable (or index).
  Assign:
    Value ASSIGN Expression           { result = AssignNode.new(val[0], val[2]) }
  ;

  # Assignment within an object literal (can be quoted).
  AssignObj:
    IDENTIFIER ASSIGN Expression      { result = AssignNode.new(ValueNode.new(val[0]), val[2], :object) }
  | STRING ASSIGN Expression          { result = AssignNode.new(ValueNode.new(LiteralNode.new(val[0])), val[2], :object) }
  | Comment                           { result = val[0] }
  ;

  # A return statement.
  Return:
    RETURN Expression                 { result = ReturnNode.new(val[1]) }
  | RETURN                            { result = ReturnNode.new(ValueNode.new(Value.new('null'))) }
  ;

  # A comment.
  Comment:
    COMMENT                           { result = CommentNode.new(val[0]) }
  ;

  # Arithmetic and logical operators
  # For Ruby's Operator precedence, see:
  # https://www.cs.auckland.ac.nz/references/ruby/ProgrammingRuby/language.html
  Operation:
    '!' Expression                    { result = OpNode.new(val[0], val[1]) }
  | '!!' Expression                   { result = OpNode.new(val[0], val[1]) }
  | '-' Expression = UMINUS           { result = OpNode.new(val[0], val[1]) }
  | '+' Expression = UPLUS            { result = OpNode.new(val[0], val[1]) }
  | NOT Expression                    { result = OpNode.new(val[0], val[1]) }
  | '~' Expression                    { result = OpNode.new(val[0], val[1]) }
  | '--' Expression                   { result = OpNode.new(val[0], val[1]) }
  | '++' Expression                   { result = OpNode.new(val[0], val[1]) }
  | DELETE Expression                 { result = OpNode.new(val[0], val[1]) }
  | TYPEOF Expression                 { result = OpNode.new(val[0], val[1]) }
  | Expression '--'                   { result = OpNode.new(val[1], val[0], nil, true) }
  | Expression '++'                   { result = OpNode.new(val[1], val[0], nil, true) }

  | Expression '*' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '/' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '%' Expression         { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '+' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '-' Expression         { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '<<' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '>>' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '>>>' Expression       { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '&' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '|' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '^' Expression         { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '<=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '<' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '>' Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '>=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '==' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '!=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression IS Expression          { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression ISNT Expression        { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '&&' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '||' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression AND Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression OR Expression          { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '?' Expression         { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '-=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '+=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '/=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '*=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '%=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '||=' Expression       { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '&&=' Expression       { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '?=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression INSTANCEOF Expression  { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression IN Expression          { result = OpNode.new(val[1], val[0], val[2]) }
  ;

  # The existence operator.
  Existence:
    Expression '?'                    { result = ExistenceNode.new(val[0]) }
  ;

  # Function definition.
  Code:
    PARAM_START ParamList PARAM_END
      FuncGlyph Block                 { result = CodeNode.new(val[1], val[4], val[3]) }
  | FuncGlyph Block                   { result = CodeNode.new([], val[1], val[0]) }
  ;

  # The symbols to signify functions, and bound functions.
  FuncGlyph:
    '->'                              { result = :func }
  | '=>'                              { result = :boundfunc }
  ;

  # The parameters to a function definition.
  ParamList:
    Param                             { result = val }
  | ParamList "," Param               { result = val[0] << val[2] }
  ;

  # A Parameter (or ParamSplat) in a function definition.
  Param:
    PARAM
  | PARAM "." "." "."                 { result = SplatNode.new(val[0]) }
  ;

  # A regular splat.
  Splat:
    Expression "." "." "."            { result = SplatNode.new(val[0]) }
  ;

  # Expressions that can be treated as values.
  Value:
    IDENTIFIER                        { result = ValueNode.new(val[0]) }
  | Literal                           { result = ValueNode.new(val[0]) }
  | Array                             { result = ValueNode.new(val[0]) }
  | Object                            { result = ValueNode.new(val[0]) }
  | Parenthetical                     { result = ValueNode.new(val[0]) }
  | Range                             { result = ValueNode.new(val[0]) }
  | Value Accessor                    { result = val[0] << val[1] }
  | Invocation Accessor               { result = ValueNode.new(val[0], [val[1]]) }
  ;

  # Accessing into an object or array, through dot or index notation.
  Accessor:
    PROPERTY_ACCESS IDENTIFIER        { result = AccessorNode.new(val[1]) }
  | PROTOTYPE_ACCESS IDENTIFIER       { result = AccessorNode.new(val[1], :prototype) }
  | SOAK_ACCESS IDENTIFIER            { result = AccessorNode.new(val[1], :soak) }
  | Index                             { result = val[0] }
  | Slice                             { result = SliceNode.new(val[0]) }
  ;

  # Indexing into an object or array.
  Index:
    INDEX_START Expression INDEX_END  { result = IndexNode.new(val[1]) }
  ;

  # An object literal.
  Object:
    "{" AssignList "}"                { result = ObjectNode.new(val[1]) }
  ;

  # Assignment within an object literal (comma or newline separated).
  AssignList:
    /* nothing */                     { result = [] }
  | AssignObj                         { result = val }
  | AssignList "," AssignObj          { result = val[0] << val[2] }
  | AssignList Terminator AssignObj   { result = val[0] << val[2] }
  | AssignList ","
      Terminator AssignObj            { result = val[0] << val[3] }
  | INDENT AssignList OUTDENT         { result = val[1] }
  ;

  # All flavors of function call (instantiation, super, and regular).
  Call:
    Invocation                        { result = val[0] }
  | NEW Invocation                    { result = val[1].new_instance }
  | Super                             { result = val[0] }
  ;

  # Extending an object's prototype.
  Extends:
    Value EXTENDS Value               { result = ExtendsNode.new(val[0], val[2]) }
  ;

  # A generic function invocation.
  Invocation:
    Value Arguments                   { result = CallNode.new(val[0], val[1]) }
  | Invocation Arguments              { result = CallNode.new(val[0], val[1]) }
  ;

  # The list of arguments to a function invocation.
  Arguments:
    CALL_START ArgList CALL_END       { result = val[1] }
  ;

  # Calling super.
  Super:
    SUPER CALL_START ArgList CALL_END { result = CallNode.new(Value.new('super'), val[2]) }
  ;

  # The range literal.
  Range:
    "[" Expression
      "." "." Expression "]"          { result = RangeNode.new(val[1], val[4]) }
  | "[" Expression
      "." "." "." Expression "]"      { result = RangeNode.new(val[1], val[5], true) }
  ;

  # The slice literal.
  Slice:
    INDEX_START Expression "." "."
      Expression INDEX_END            { result = RangeNode.new(val[1], val[4]) }
  | INDEX_START Expression "." "." "."
      Expression INDEX_END            { result = RangeNode.new(val[1], val[5], true) }
  ;

  # The array literal.
  Array:
    "[" ArgList "]"                   { result = ArrayNode.new(val[1]) }
  ;

  # A list of arguments to a method call, or as the contents of an array.
  ArgList:
    /* nothing */                     { result = [] }
  | Expression                        { result = val }
  | INDENT Expression                 { result = [val[1]] }
  | ArgList "," Expression            { result = val[0] << val[2] }
  | ArgList Terminator Expression     { result = val[0] << val[2] }
  | ArgList "," Terminator Expression { result = val[0] << val[3] }
  | ArgList "," INDENT Expression     { result = val[0] << val[3] }
  | ArgList OUTDENT                   { result = val[0] }
  ;

  # Just simple, comma-separated, required arguments (no fancy syntax).
  SimpleArgs:
    Expression                        { result = val[0] }
  | SimpleArgs "," Expression         { result = ([val[0]] << val[2]).flatten }
  ;

  # Try/catch/finally exception handling blocks.
  Try:
    TRY Block Catch                   { result = TryNode.new(val[1], val[2][0], val[2][1]) }
  | TRY Block FINALLY Block           { result = TryNode.new(val[1], nil, nil, val[3]) }
  | TRY Block Catch
      FINALLY Block                   { result = TryNode.new(val[1], val[2][0], val[2][1], val[4]) }
  ;

  # A catch clause.
  Catch:
    CATCH IDENTIFIER Block            { result = [val[1], val[2]] }
  ;

  # Throw an exception.
  Throw:
    THROW Expression                  { result = ThrowNode.new(val[1]) }
  ;

  # Parenthetical expressions.
  Parenthetical:
    "(" Expression ")"                { result = ParentheticalNode.new(val[1], val[0].line) }
  ;

  # The while loop. (there is no do..while).
  While:
    WHILE Expression Block            { result = WhileNode.new(val[1], val[2]) }
  | WHILE Expression                  { result = WhileNode.new(val[1], nil) }
  | Expression WHILE Expression       { result = WhileNode.new(val[2], Expressions.wrap(val[0])) }
  ;

  # Array comprehensions, including guard and current index.
  # Looks a little confusing, check nodes.rb for the arguments to ForNode.
  For:
    Expression FOR
      ForVariables ForSource          { result = ForNode.new(val[0], val[3], val[2][0], val[2][1]) }
  | FOR ForVariables ForSource Block  { result = ForNode.new(val[3], val[2], val[1][0], val[1][1]) }
  ;

  # An array comprehension has variables for the current element and index.
  ForVariables:
    IDENTIFIER                        { result = val }
  | IDENTIFIER "," IDENTIFIER         { result = [val[0], val[2]] }
  ;

  # The source of the array comprehension can optionally be filtered.
  ForSource:
    IN Expression                     { result = {:source => val[1]} }
  | OF Expression                     { result = {:source => val[1], :object => true} }
  | ForSource
    WHEN Expression                   { result = val[0].merge(:filter => val[2]) }
  | ForSource
    BY Expression                     { result = val[0].merge(:step => val[2]) }
  ;

  # Switch/When blocks.
  Switch:
    SWITCH Expression INDENT
      Whens OUTDENT                   { result = val[3].rewrite_condition(val[1]) }
  | SWITCH Expression INDENT
      Whens ELSE Block OUTDENT        { result = val[3].rewrite_condition(val[1]).add_else(val[5]) }
  ;

  # The inner list of whens.
  Whens:
    When                              { result = val[0] }
  | Whens When                        { result = val[0] << val[1] }
  ;

  # An individual when.
  When:
    LEADING_WHEN SimpleArgs Block     { result = IfNode.new(val[1], val[2], nil, {:statement => true}) }
  | LEADING_WHEN SimpleArgs Block
      Terminator                      { result = IfNode.new(val[1], val[2], nil, {:statement => true}) }
  | Comment Terminator When           { result = val[2].add_comment(val[0]) }
  ;

  # The most basic form of "if".
  IfBlock:
    IF Expression Block               { result = IfNode.new(val[1], val[2]) }
  ;

  # An elsif portion of an if-else block.
  ElsIf:
    ELSE IfBlock                      { result = val[1].force_statement }
  ;

  # Multiple elsifs can be chained together.
  ElsIfs:
    ElsIf                             { result = val[0] }
  | ElsIfs ElsIf                      { result = val[0].add_else(val[1]) }
  ;

  # Terminating else bodies are strictly optional.
  ElseBody
    /* nothing */                     { result = nil }
  | ELSE Block                        { result = val[1] }
  ;

  # All the alternatives for ending an if-else block.
  IfEnd:
    ElseBody                          { result = val[0] }
  | ElsIfs ElseBody                   { result = val[0].add_else(val[1]) }
  ;

  # The full complement of if blocks, including postfix one-liner ifs and unlesses.
  If:
    IfBlock IfEnd                     { result = val[0].add_else(val[1]) }
  | Expression IF Expression          { result = IfNode.new(val[2], Expressions.wrap(val[0]), nil, {:statement => true}) }
  | Expression UNLESS Expression      { result = IfNode.new(val[2], Expressions.wrap(val[0]), nil, {:statement => true, :invert => true}) }
  ;

end

---- header
module CoffeeScript

---- inner
  # Lex and parse a CoffeeScript.
  def parse(code)
    # Uncomment the following line to enable grammar debugging, in combination
    # with the -g flag in the Rake build task.
    # @yydebug = true
    @tokens = Lexer.new.tokenize(code)
    do_parse
  end

  # Retrieve the next token from the list.
  def next_token
    @tokens.shift
  end

  # Raise a custom error class that knows about line numbers.
  def on_error(error_token_id, error_value, value_stack)
    raise ParseError.new(token_to_str(error_token_id), error_value, value_stack)
  end

---- footer
end