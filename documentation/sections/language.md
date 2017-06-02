## Language Reference

_This reference is structured so that it can be read from top to bottom, if you like. Later sections use ideas and syntax previously introduced. Familiarity with JavaScript is assumed. In all of the following examples, the source CoffeeScript is provided on the left, and the direct compilation into JavaScript is on the right._

_Many of the examples can be run (where it makes sense) by pressing the_ <small>▶</small> _button on the right. The CoffeeScript on the left is editable, and the JavaScript will update as you edit._

First, the basics: CoffeeScript uses significant whitespace to delimit blocks of code. You don’t need to use semicolons `;` to terminate expressions, ending the line will do just as well (although semicolons can still be used to fit multiple expressions onto a single line). Instead of using curly braces `{ }` to surround blocks of code in [functions](#literals), [if-statements](#conditionals), [switch](#switch), and [try/catch](#try), use indentation.

You don’t need to use parentheses to invoke a function if you’re passing arguments. The implicit call wraps forward to the end of the line or block expression.<br>
`console.log sys.inspect object` → `console.log(sys.inspect(object));`
