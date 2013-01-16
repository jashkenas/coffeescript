Literate CoffeeScript Test
--------------------------

comment comment

    test "basic literate CoffeeScript parsing", ->
      ok yes
      
now with a...
  
    test "broken up indentation", ->
    
... broken up ...

      do ->
      
... nested block.

        ok yes
        
Code in `backticks is not parsed` and...

    test "comments in indented blocks work", ->
      do ->
        do ->
          # Regular comment.
          
          ###
            Block comment.
          ###
          
          ok yes
          
Regular [Markdown](http://example.com/markdown) features, like links 
and unordered lists, are fine:

  * I 
  
  * Am
  
  * A
  
  * List

Tabs work too:

	test "tabbed code", ->
		ok yes
