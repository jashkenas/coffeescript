## Operators and Aliases

Because the `==` operator frequently causes undesirable coercion, is intransitive, and has a different meaning than in other languages, CoffeeScript compiles `==` into `===`, and `!=` into `!==`. In addition, `is` compiles into `===`, and `isnt` into `!==`.

You can use `not` as an alias for `!`.

For logic, `and` compiles to `&&`, and `or` into `||`.

Instead of a newline or semicolon, `then` can be used to separate conditions from expressions, in **while**, **if**/**else**, and **switch**/**when** statements.

As in [YAML](http://yaml.org/), `on` and `yes` are the same as boolean `true`, while `off` and `no` are boolean `false`.

`unless` can be used as the inverse of `if`.

As a shortcut for `this.property`, you can use `@property`.

You can use `in` to test for array presence, and `of` to test for JavaScript object-key presence.

To simplify math expressions, `**` can be used for exponentiation and `//` performs integer division. `%` works just like in JavaScript, while `%%` provides [“dividend dependent modulo”](http://en.wikipedia.org/wiki/Modulo_operation):

```
codeFor('modulo')
```

All together now:

<table class="definitions">

<tbody>

<tr>

<th>CoffeeScript</th>

<th>JavaScript</th>

</tr>

<tr>

<td>`is`</td>

<td>`===`</td>

</tr>

<tr>

<td>`isnt`</td>

<td>`!==`</td>

</tr>

<tr>

<td>`not`</td>

<td>`!`</td>

</tr>

<tr>

<td>`and`</td>

<td>`&&`</td>

</tr>

<tr>

<td>`or`</td>

<td>`||`</td>

</tr>

<tr>

<td>`true`, `yes`, `on`</td>

<td>`true`</td>

</tr>

<tr>

<td>`false`, `no`, `off`</td>

<td>`false`</td>

</tr>

<tr>

<td>`@`, `this`</td>

<td>`this`</td>

</tr>

<tr>

<td>`of`</td>

<td>`in`</td>

</tr>

<tr>

<td>`in`</td>

<td>_<small>no JS equivalent</small>_</td>

</tr>

<tr>

<td>`a ** b`</td>

<td>`Math.pow(a, b)`</td>

</tr>

<tr>

<td>`a // b`</td>

<td>`Math.floor(a / b)`</td>

</tr>

<tr>

<td>`a %% b`</td>

<td>`(a % b + b) % b`</td>

</tr>

</tbody>

</table>

```
codeFor('aliases')
```
