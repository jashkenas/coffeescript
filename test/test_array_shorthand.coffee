util=require 'util'

objectLiteral=
  """
  root:
    * a: 1
    * b: 2
    * c:
      * ca: 1
      * cb: 2
  """
  
referenceObjectLiteral=
  """
  root: [
    {a: 1}
    {b: 2}
    {c: [
      {ca: 1}
      {cb: 2}    
      ]}
    ]
  """
ok CoffeeScript.compile(objectLiteral) is CoffeeScript.compile(referenceObjectLiteral)

syntaxError=
  """
  root:
    * a: 1
    b: 2 # syntax error: no * in array shorthand
    * c:
      * ca: 1
      * cb: 2  
  """
try ok not CoffeeScript.nodes syntaxError
catch e then eq e.message, ' no * in array shorthand on line 3'

notASyntaxError=
  """
  root:
    * a: 1
    * b: 2
    * c: # not a syntax error, c is just an object
      ca: 1
      cb: 2  
  """

ok CoffeeScript.nodes notASyntaxError

# using the array shorthand syntax in an assignment

assignment=
  """
  root=
    * a: 1
    * b: 2
    * c:
      * ca: 1
      * cb: 2  
  """

referenceAssignment=
  """
  root=[
    {a: 1}
    {b: 2}
    {c: [
      {ca: 1}
      {cb: 2}
      ]}
    ]
  """

ok CoffeeScript.compile(assignment) is CoffeeScript.compile(referenceAssignment)

# using the array shorthand syntax for returning values from a function

root=->
  * a: 1
  * b: 2
  * c:
    * ca: 1
    * cb: 2
value=root()



root=->
  [{a: 1}
  {b: 2}
  {c: [
    {ca: 1}
    {cb: 2}
    ]}
  ]
referenceValue=root()

ok util.inspect(value) is util.inspect(referenceValue)