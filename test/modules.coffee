# Modules, a.k.a. ES2015 import/export
# ------------------------------------
#
# Remember, we’re not *resolving* modules, just outputting valid ES2015 syntax.


# This is the CoffeeScript import and export syntax, closely modeled after the ES2015 syntax
# https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/import
# https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/export

# import "module-name"
# import defaultMember from "module-name"
# import * as name from "module-name"
# import { } from "module-name"
# import { member } from "module-name"
# import { member as alias } from "module-name"
# import { member1, member2 as alias2, … } from "module-name"
# import defaultMember, * as name from "module-name"
# import defaultMember, { … } from "module-name"

# export default expression
# export class name
# export { }
# export { name }
# export { name as exportedName }
# export { name as default }
# export { name1, name2 as exportedName2, name3 as default, … }
#
# export * from "module-name"
# export { … } from "module-name"
#
# As a subsitute for `export var name = …` and `export function name {}`,
# CoffeeScript also supports:
# export name = …

# CoffeeScript also supports optional commas within `{ … }`.


# Helper function
toJS = (str) ->
  CoffeeScript.compile str, bare: yes
  .replace /^\s+|\s+$/g, '' # Trim leading/trailing whitespace


# Import statements

test "backticked import statement", ->
  input = """
    if Meteor.isServer
      `import { foo, bar as baz } from 'lib'`"""
  output = """
    if (Meteor.isServer) {
      import { foo, bar as baz } from 'lib';
    }"""
  eq toJS(input), output

test "import an entire module for side effects only, without importing any bindings", ->
  input = "import 'lib'"
  output = "import 'lib';"
  eq toJS(input), output

test "import default member from module, adding the member to the current scope", ->
  input = """
    import foo from 'lib'
    foo.fooMethod()"""
  output = """
    import foo from 'lib';

    foo.fooMethod();"""
  eq toJS(input), output

test "import an entire module's contents as an alias, adding the alias to the current scope", ->
  input = """
    import * as foo from 'lib'
    foo.fooMethod()"""
  output = """
    import * as foo from 'lib';

    foo.fooMethod();"""
  eq toJS(input), output

test "import empty object", ->
  input = "import { } from 'lib'"
  output = "import {} from 'lib';"
  eq toJS(input), output

test "import empty object", ->
  input = "import {} from 'lib'"
  output = "import {} from 'lib';"
  eq toJS(input), output

test "import a single member of a module, adding the member to the current scope", ->
  input = """
    import { foo } from 'lib'
    foo.fooMethod()"""
  output = """
    import {
      foo
    } from 'lib';

    foo.fooMethod();"""
  eq toJS(input), output

test "import a single member of a module as an alias, adding the alias to the current scope", ->
  input = """
    import { foo as bar } from 'lib'
    bar.barMethod()"""
  output = """
    import {
      foo as bar
    } from 'lib';

    bar.barMethod();"""
  eq toJS(input), output

test "import multiple members of a module, adding the members to the current scope", ->
  input = """
    import { foo, bar } from 'lib'
    foo.fooMethod()
    bar.barMethod()"""
  output = """
    import {
      foo,
      bar
    } from 'lib';

    foo.fooMethod();

    bar.barMethod();"""
  eq toJS(input), output

test "import multiple members of a module where some are aliased, adding the members or aliases to the current scope", ->
  input = """
    import { foo, bar as baz } from 'lib'
    foo.fooMethod()
    baz.bazMethod()"""
  output = """
    import {
      foo,
      bar as baz
    } from 'lib';

    foo.fooMethod();

    baz.bazMethod();"""
  eq toJS(input), output

test "import default member and other members of a module, adding the members to the current scope", ->
  input = """
    import foo, { bar, baz as qux } from 'lib'
    foo.fooMethod()
    bar.barMethod()
    qux.quxMethod()"""
  output = """
    import foo, {
      bar,
      baz as qux
    } from 'lib';

    foo.fooMethod();

    bar.barMethod();

    qux.quxMethod();"""
  eq toJS(input), output

test "import default member from a module as well as the entire module's contents as an alias, adding the member and alias to the current scope", ->
  input = """
    import foo, * as bar from 'lib'
    foo.fooMethod()
    bar.barMethod()"""
  output = """
    import foo, * as bar from 'lib';

    foo.fooMethod();

    bar.barMethod();"""
  eq toJS(input), output

test "multiline simple import", ->
  input = """
    import {
      foo,
      bar as baz
    } from 'lib'"""
  output = """
    import {
      foo,
      bar as baz
    } from 'lib';"""
  eq toJS(input), output

test "multiline complex import", ->
  input = """
    import foo, {
      bar,
      baz as qux
    } from 'lib'"""
  output = """
    import foo, {
      bar,
      baz as qux
    } from 'lib';"""
  eq toJS(input), output

test "import with optional commas", ->
  input = "import { foo, bar, } from 'lib'"
  output = """
    import {
      foo,
      bar
    } from 'lib';"""
  eq toJS(input), output

test "multiline import without commas", ->
  input = """
    import {
      foo
      bar
    } from 'lib'"""
  output = """
    import {
      foo,
      bar
    } from 'lib';"""
  eq toJS(input), output

test "multiline import with optional commas", ->
  input = """
    import {
      foo,
      bar,
    } from 'lib'"""
  output = """
    import {
      foo,
      bar
    } from 'lib';"""
  eq toJS(input), output

test "a variable can be assigned after an import", ->
  input = """
    import { foo } from 'lib'
    bar = 5"""
  output = """
    var bar;

    import {
      foo
    } from 'lib';

    bar = 5;"""
  eq toJS(input), output

test "variables can be assigned before and after an import", ->
  input = """
    foo = 5
    import { bar } from 'lib'
    baz = 7"""
  output = """
    var baz, foo;

    foo = 5;

    import {
      bar
    } from 'lib';

    baz = 7;"""
  eq toJS(input), output

# Export statements

test "export empty object", ->
  input = "export { }"
  output = "export {};"
  eq toJS(input), output

test "export empty object", ->
  input = "export {}"
  output = "export {};"
  eq toJS(input), output

test "export named members within an object", ->
  input = "export { foo, bar }"
  output = """
    export {
      foo,
      bar
    };"""
  eq toJS(input), output

test "export named members as aliases, within an object", ->
  input = "export { foo as bar, baz as qux }"
  output = """
    export {
      foo as bar,
      baz as qux
    };"""
  eq toJS(input), output

test "export named members within an object, with an optional comma", ->
  input = "export { foo, bar, }"
  output = """
    export {
      foo,
      bar
    };"""
  eq toJS(input), output

test "multiline export named members within an object", ->
  input = """
    export {
      foo,
      bar
    }"""
  output = """
    export {
      foo,
      bar
    };"""
  eq toJS(input), output

test "multiline export named members within an object, with an optional comma", ->
  input = """
    export {
      foo,
      bar,
    }"""
  output = """
    export {
      foo,
      bar
    };"""
  eq toJS(input), output

test "export default string", ->
  input = "export default 'foo'"
  output = "export default 'foo';"
  eq toJS(input), output

test "export default number", ->
  input = "export default 5"
  output = "export default 5;"
  eq toJS(input), output

test "export default object", ->
  input = "export default { foo: 'bar', baz: 'qux' }"
  output = """
    export default {
      foo: 'bar',
      baz: 'qux'
    };"""
  eq toJS(input), output

test "export default assignment expression", ->
  input = "export default foo = 'bar'"
  output = """
    var foo;

    export default foo = 'bar';"""
  eq toJS(input), output

test "export assignment expression", ->
  input = "export foo = 'bar'"
  output = "export var foo = 'bar';"
  eq toJS(input), output

test "export multiline assignment expression", ->
  input = """
    export foo =
    'bar'"""
  output = "export var foo = 'bar';"
  eq toJS(input), output

test "export multiline indented assignment expression", ->
  input = """
    export foo =
      'bar'"""
  output = "export var foo = 'bar';"
  eq toJS(input), output

test "export default function", ->
  input = "export default ->"
  output = "export default function() {};"
  eq toJS(input), output

test "export default multiline function", ->
  input = """
    export default (foo) ->
      console.log foo"""
  output = """
    export default function(foo) {
      return console.log(foo);
    };"""
  eq toJS(input), output

test "export assignment function", ->
  input = """
    export foo = (bar) ->
      console.log bar"""
  output = """
    export var foo = function(bar) {
      return console.log(bar);
    };"""
  eq toJS(input), output

test "export assignment function which contains assignments in its body", ->
  input = """
    export foo = (bar) ->
      baz = '!'
      console.log bar + baz"""
  output = """
    export var foo = function(bar) {
      var baz;
      baz = '!';
      return console.log(bar + baz);
    };"""
  eq toJS(input), output

test "export default predefined function", ->
  input = """
    foo = (bar) ->
      console.log bar
    export default foo"""
  output = """
    var foo;

    foo = function(bar) {
      return console.log(bar);
    };

    export default foo;"""
  eq toJS(input), output

# Uncomment this test once ES2015+ `class` support is added

# test "export default class", ->
#   input = """
#     export default class foo extends bar
#       baz: ->
#         console.log 'hello, world!'"""
#   output = """
#     export default class foo extends bar {
#       baz: function {
#         return console.log('hello, world!');
#       }
#     }"""
#   eq toJS(input), output

# Very limited tests for now, testing that `export class foo` either compiles
# identically (ES2015+) or at least into some function, leaving the specifics
# vague in case the CoffeeScript `class` interpretation changes
test "export class", ->
  input = """
    export class foo
      baz: ->
        console.log 'hello, world!'"""
  output = toJS input
  ok /^export (class foo|var foo = \(function)/.test toJS input

test "export class that extends", ->
  input = """
    export class foo extends bar
      baz: ->
        console.log 'hello, world!'"""
  output = toJS input
  ok /export (class foo|var foo = \(function)/.test(output) and \
    not /var foo(;|,)/.test output

test "export default class that extends", ->
  input = """
    export default class foo extends bar
      baz: ->
        console.log 'hello, world!'"""
  ok /export default (class foo|foo = \(function)/.test toJS input

test "export default named member, within an object", ->
  input = "export { foo as default, bar }"
  output = """
    export {
      foo as default,
      bar
    };"""
  eq toJS(input), output


# Import and export in the same statement

test "export an entire module's contents", ->
  input = "export * from 'lib'"
  output = "export * from 'lib';"
  eq toJS(input), output

test "export members imported from another module", ->
  input = "export { foo, bar } from 'lib'"
  output = """
    export {
      foo,
      bar
    } from 'lib';"""
  eq toJS(input), output

test "export as aliases members imported from another module", ->
  input = "export { foo as bar, baz as qux } from 'lib'"
  output = """
    export {
      foo as bar,
      baz as qux
    } from 'lib';"""
  eq toJS(input), output

test "export list can contain CoffeeScript keywords", ->
  input = "export { unless } from 'lib'"
  output = """
    export {
      unless
    } from 'lib';"""
  eq toJS(input), output

test "export list can contain CoffeeScript keywords when aliasing", ->
  input = "export { when as bar, baz as unless } from 'lib'"
  output = """
    export {
      when as bar,
      baz as unless
    } from 'lib';"""
  eq toJS(input), output


# Edge cases

test "multiline import with comments", ->
  input = """
    import {
      foo, # Not as good as bar
      bar as baz # I prefer qux
    } from 'lib'"""
  output = """
    import {
      foo,
      bar as baz
    } from 'lib';"""
  eq toJS(input), output

test "`from` not part of an import or export statement can still be assigned", ->
  from = 5
  eq 5, from

test "a variable named `from` can be assigned after an import", ->
  input = """
    import { foo } from 'lib'
    from = 5"""
  output = """
    var from;

    import {
      foo
    } from 'lib';

    from = 5;"""
  eq toJS(input), output

test "`from` can be assigned after a multiline import", ->
  input = """
    import {
      foo
    } from 'lib'
    from = 5"""
  output = """
    var from;

    import {
      foo
    } from 'lib';

    from = 5;"""
  eq toJS(input), output

test "`from` can be imported as a member name", ->
  input = "import { from } from 'lib'"
  output = """
    import {
      from
    } from 'lib';"""
  eq toJS(input), output

test "`from` can be imported as a member name and aliased", ->
  input = "import { from as foo } from 'lib'"
  output = """
    import {
      from as foo
    } from 'lib';"""
  eq toJS(input), output

test "`from` can be used as an alias name", ->
  input = "import { foo as from } from 'lib'"
  output = """
    import {
      foo as from
    } from 'lib';"""
  eq toJS(input), output

test "`as` can be imported as a member name", ->
  input = "import { as } from 'lib'"
  output = """
    import {
      as
    } from 'lib';"""
  eq toJS(input), output

test "`as` can be imported as a member name and aliased", ->
  input = "import { as as foo } from 'lib'"
  output = """
    import {
      as as foo
    } from 'lib';"""
  eq toJS(input), output

test "`as` can be used as an alias name", ->
  input = "import { foo as as } from 'lib'"
  output = """
    import {
      foo as as
    } from 'lib';"""
  eq toJS(input), output

test "CoffeeScript keywords can be used as imported names in import lists", ->
  input = """
    import { unless as bar } from 'lib'
    bar.barMethod()"""
  output = """
    import {
      unless as bar
    } from 'lib';

    bar.barMethod();"""
  eq toJS(input), output

test "`*` can be used in an expression on the same line as an export keyword", ->
  input = "export foo = (x) -> x * x"
  output = """
    export var foo = function(x) {
      return x * x;
    };"""
  eq toJS(input), output
  input = "export default foo = (x) -> x * x"
  output = """
    var foo;

    export default foo = function(x) {
      return x * x;
    };"""
  eq toJS(input), output

test "`*` and `from` can be used in an export default expression", ->
  input = """
    export default foo.extend
      bar: ->
        from = 5
        from = from * 3"""
  output = """
    export default foo.extend({
      bar: function() {
        var from;
        from = 5;
        return from = from * 3;
      }
    });"""
  eq toJS(input), output

test "wrapped members can be imported multiple times if aliased", ->
  input = "import { foo, foo as bar } from 'lib'"
  output = """
    import {
      foo,
      foo as bar
    } from 'lib';"""
  eq toJS(input), output

test "default and wrapped members can be imported multiple times if aliased", ->
  input = "import foo, { foo as bar } from 'lib'"
  output = """
    import foo, {
      foo as bar
    } from 'lib';"""
  eq toJS(input), output

test "import a member named default", ->
  input = "import { default } from 'lib'"
  output = """
    import {
      default
    } from 'lib';"""
  eq toJS(input), output

test "import an aliased member named default", ->
  input = "import { default as def } from 'lib'"
  output = """
    import {
      default as def
    } from 'lib';"""
  eq toJS(input), output

test "export a member named default", ->
  input = "export { default }"
  output = """
    export {
      default
    };"""
  eq toJS(input), output

test "export an aliased member named default", ->
  input = "export { def as default }"
  output = """
    export {
      def as default
    };"""
  eq toJS(input), output

test "export an imported member named default", ->
  input = "import { default } from 'lib'"
  output = """
    import {
      default
    } from 'lib';"""
  eq toJS(input), output

test "export an imported aliased member named default", ->
  input = "import { default as def } from 'lib'"
  output = """
    import {
      default as def
    } from 'lib';"""
  eq toJS(input), output

test "#4394: export shouldn't prevent variable declarations", ->
  input = """
    x = 1
    export { x }
  """
  output = """
    var x;

    x = 1;

    export {
      x
    };
  """
  eq toJS(input), output
