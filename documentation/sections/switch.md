## Switch/When/Else

`switch` statements in JavaScript are a bit awkward. You need to remember to `break` at the end of every `case` statement to avoid accidentally falling through to the default case. CoffeeScript prevents accidental fall-through, and can convert the `switch` into a returnable, assignable expression. The format is: `switch` condition, `when` clauses, `else` the default case.

As in Ruby, `switch` statements in CoffeeScript can take multiple values for each `when` clause. If any of the values match, the clause runs.

```
codeFor('switch')
```

`switch` statements can also be used without a control expression, turning them in to a cleaner alternative to `if`/`else` chains.

```
codeFor('switch_with_no_expression')
```
