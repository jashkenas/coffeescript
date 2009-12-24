class Parser

# Declare tokens produced by the lexer
token IF ELSE THEN UNLESS
token NUMBER STRING REGEX
token TRUE FALSE YES NO ON OFF
token IDENTIFIER PROPERTY_ACCESS
token CODE PARAM NEW RETURN
token TRY CATCH FINALLY THROW
token BREAK CONTINUE
token FOR IN WHILE
token SWITCH CASE
token SUPER
token DELETE
token NEWLINE
token COMMENT
token JS

# Declare order of operations.
prechigh
  nonassoc UMINUS NOT '!' '!!' '~' '++' '--'
  left     '*' '/' '%'
  left     '+' '-'
  left     '<<' '>>' '>>>'
  left     '&' '|' '^'
  left     '<=' '<' '>' '>='
  right    '==' '!=' IS AINT
  left     '&&' '||' AND OR
  right    '-=' '+=' '/=' '*='
  right    DELETE
  left     "."
  right    THROW FOR IN WHILE NEW
  left     UNLESS IF ELSE
  left     ":" '||:' '&&:'
  right    RETURN
preclow

# We expect 4 shift/reduce errors for optional syntax.
# There used to be 252 -- greatly improved.
expect 4

rule

  # All parsing will end in this rule, being the trunk of the AST.
  Root:
    /* nothing */                     { result = Expressions.new([]) }
  | Terminator                        { result = Expressions.new([]) }
  | Expressions                       { result = val[0] }
  ;

  # Any list of expressions or method body, seperated by line breaks or semis.
  Expressions:
    Expression                        { result = Expressions.new(val) }
  | Expressions Terminator Expression { result = val[0] << val[2] }
  | Expressions Terminator            { result = val[0] }
  | Terminator Expressions            { result = val[1] }
  ;

  # All types of expressions in our language.
  Expression:
    PureExpression
  | Statement
  ;

  # The parts that are natural JavaScript expressions.
  PureExpression:
    Literal
  | Value
  | Call
  | Code
  | Operation
  ;

  # We have to take extra care to convert these statements into expressions.
  Statement:
    Assign
  | If
  | Try
  | Throw
  | Return
  | While
  | For
  | Switch
  | Comment
  ;

  # All tokens that can terminate an expression.
  Terminator:
    "\n"
  | ";"
  ;

  # All tokens that can serve to begin the second block of a multi-part expression.
  Then:
    THEN
  | Terminator
  ;

  # All hard-coded values.
  Literal:
    NUMBER                            { result = LiteralNode.new(val[0]) }
  | STRING                            { result = LiteralNode.new(val[0]) }
  | JS                                { result = LiteralNode.new(val[0]) }
  | REGEX                             { result = LiteralNode.new(val[0]) }
  | BREAK                             { result = LiteralNode.new(val[0]) }
  | CONTINUE                          { result = LiteralNode.new(val[0]) }
  | TRUE                              { result = LiteralNode.new(true) }
  | FALSE                             { result = LiteralNode.new(false) }
  | YES                               { result = LiteralNode.new(true) }
  | NO                                { result = LiteralNode.new(false) }
  | ON                                { result = LiteralNode.new(true) }
  | OFF                               { result = LiteralNode.new(false) }
  ;

  # Assignment to a variable.
  Assign:
    Value ":" Expression              { result = AssignNode.new(val[0], val[2]) }
  ;

  # Assignment within an object literal.
  AssignObj:
    IDENTIFIER ":" Expression         { result = AssignNode.new(val[0], val[2], :object) }
  | Comment                           { result = val[0] }
  ;

  # A return statement.
  Return:
    RETURN Expression                 { result = ReturnNode.new(val[1]) }
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
  | NOT Expression                    { result = OpNode.new(val[0], val[1]) }
  | '~' Expression                    { result = OpNode.new(val[0], val[1]) }
  | '--' Expression                    { result = OpNode.new(val[0], val[1]) }
  | '++' Expression                    { result = OpNode.new(val[0], val[1]) }
  | Expression '--'                    { result = OpNode.new(val[1], val[0], nil, true) }
  | Expression '++'                    { result = OpNode.new(val[1], val[0], nil, true) }

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
  | Expression AINT Expression        { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '&&' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '||' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression AND Expression         { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression OR Expression          { result = OpNode.new(val[1], val[0], val[2]) }

  | Expression '-=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '+=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '/=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '*=' Expression        { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '||:' Expression       { result = OpNode.new(val[1], val[0], val[2]) }
  | Expression '&&:' Expression       { result = OpNode.new(val[1], val[0], val[2]) }

  | DELETE Expression                 { result = OpNode.new(val[0], val[1]) }
  ;

  # Function definition.
  Code:
    ParamList "=>" CodeBody "."       { result = CodeNode.new(val[0], val[2]) }
  | "=>" CodeBody "."                 { result = CodeNode.new([], val[1]) }
  ;

  # The body of a function.
  CodeBody:
    /* nothing */                     { result = Expressions.new([]) }
  | Expressions                       { result = val[0] }
  ;

  # The parameters to a function definition.
  ParamList:
    PARAM                             { result = val }
  | ParamList "," PARAM               { result = val[0] << val[2] }
  ;

  # Expressions that can be treated as values.
  Value:
    IDENTIFIER                        { result = ValueNode.new(val[0]) }
  | Array                             { result = ValueNode.new(val[0]) }
  | Object                            { result = ValueNode.new(val[0]) }
  | Parenthetical                     { result = ValueNode.new(val[0]) }
  | Value Accessor                    { result = val[0] << val[1] }
  | Invocation Accessor               { result = ValueNode.new(val[0], [val[1]]) }
  ;

  # Accessing into an object or array, through dot or index notation.
  Accessor:
    PROPERTY_ACCESS IDENTIFIER        { result = AccessorNode.new(val[1]) }
  | Index                             { result = val[0] }
  | Slice                             { result = val[0] }
  ;

  # Indexing into an object or array.
  Index:
    "[" Expression "]"                { result = IndexNode.new(val[1]) }
  ;

  # Array slice literal.
  Slice:
    "[" Expression "," Expression "]" { result = SliceNode.new(val[1], val[3]) }
  ;

  # An object literal.
  Object:
    "{" AssignList "}"                { result = ObjectNode.new(val[1]) }
  ;

  # Assignment within an object literal (comma or newline separated).
  AssignList:
    /* nothing */                     { result = []}
  | AssignObj                         { result = val }
  | AssignList "," AssignObj          { result = val[0] << val[2] }
  | AssignList Terminator AssignObj   { result = val[0] << val[2] }
  ;

  # All flavors of function call (instantiation, super, and regular).
  Call:
    Invocation                        { result = val[0] }
  | NEW Invocation                    { result = val[1].new_instance }
  | Super                             { result = val[0] }
  ;

  # A generic function invocation.
  Invocation:
    Value "(" ArgList ")"             { result = CallNode.new(val[0], val[2]) }
  ;

  # Calling super.
  Super:
    SUPER "(" ArgList ")"             { result = CallNode.new(:super, val[2]) }
  ;

  # The array literal.
  Array:
    "[" ArgList "]"                   { result = ArrayNode.new(val[1]) }
  ;

  # A list of arguments to a method call, or as the contents of an array.
  ArgList:
    /* nothing */                     { result = [] }
  | Expression                        { result = val }
  | ArgList "," Expression            { result = val[0] << val[2] }
  | ArgList Terminator Expression     { result = val[0] << val[2] }
  ;

  # Try/catch/finally exception handling blocks.
  Try:
    TRY Expressions Catch "."         { result = TryNode.new(val[1], val[2][0], val[2][1]) }
  | TRY Expressions Catch
    FINALLY Expressions "."           { result = TryNode.new(val[1], val[2][0], val[2][1], val[4]) }
  ;

  # A catch clause.
  Catch:
    /* nothing */                     { result = [nil, nil] }
  | CATCH IDENTIFIER Expressions      { result = [val[1], val[2]] }
  ;

  # Throw an exception.
  Throw:
    THROW Expression                  { result = ThrowNode.new(val[1]) }
  ;

  # Parenthetical expressions.
  Parenthetical:
    "(" Expressions ")"               { result = ParentheticalNode.new(val[1]) }
  ;

  # The while loop. (there is no do..while).
  While:
    WHILE Expression Then
      Expressions "."                 { result = WhileNode.new(val[1], val[3]) }
  ;

  # Array comprehensions, including guard and current index.
  For:
  Expression FOR IDENTIFIER
    IN PureExpression "."             { result = ForNode.new(val[0], val[4], val[2], nil) }
  | Expression FOR
      IDENTIFIER "," IDENTIFIER
      IN PureExpression "."           { result = ForNode.new(val[0], val[6], val[2], nil, val[4]) }
  | Expression FOR IDENTIFIER
      IN PureExpression
      IF Expression "."               { result = ForNode.new(val[0], val[4], val[2], val[6]) }
  | Expression FOR
      IDENTIFIER "," IDENTIFIER
      IN PureExpression
      IF Expression "."               { result = ForNode.new(val[0], val[6], val[2], val[8], val[4]) }
  ;

  # Switch/Case blocks.
  Switch:
    SWITCH Expression Then
      Cases "."                       { result = val[3].rewrite_condition(val[1]) }
  | SWITCH Expression Then
      Cases ELSE Expressions "."      { result = val[3].rewrite_condition(val[1]).add_else(val[5]) }
  ;

  # The inner list of cases.
  Cases:
    Case                              { result = val[0] }
  | Cases Case                        { result = val[0] << val[1] }
  ;

  # An individual case.
  Case:
    CASE Expression Then Expressions  { result = IfNode.new(val[1], val[3]) }
  ;

  # All of the following nutso if-else destructuring is to make the
  # grammar expand unambiguously.

  # An elsif portion of an if-else block.
  ElsIf:
    ELSE IF Expression
      Then Expressions                { result = IfNode.new(val[2], val[4]) }
  ;

  # Multiple elsifs can be chained together.
  ElsIfs:
    ElsIf                             { result = val[0] }
  | ElsIfs ElsIf                      { result = val[0].add_else(val[1]) }
  ;

  # Terminating else bodies are strictly optional.
  ElseBody
    "."                               { result = nil }
  | ELSE Expressions "."              { result = val[1] }
  ;

  # All the alternatives for ending an if-else block.
  IfEnd:
    ElseBody                          { result = val[0] }
  | ElsIfs ElseBody                   { result = val[0].add_else(val[1]) }
  ;

  # The full complement of if blocks, including postfix one-liner ifs and unlesses.
  If:
    IF Expression
      Then Expressions IfEnd          { result = IfNode.new(val[1], val[3], val[4]) }
  | Expression IF Expression          { result = IfNode.new(val[2], Expressions.new([val[0]]), nil, {:statement => true}) }
  | Expression UNLESS Expression      { result = IfNode.new(val[2], Expressions.new([val[0]]), nil, {:statement => true, :invert => true}) }
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