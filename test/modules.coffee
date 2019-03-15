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


# Import statements

test "backticked import statement", ->
  eqJS """
    if Meteor.isServer
      `import { foo, bar as baz } from 'lib'`""",
  """
    if (Meteor.isServer) {
      import { foo, bar as baz } from 'lib';
    }"""

test "import an entire module for side effects only, without importing any bindings", ->
  eqJS "import 'lib'",
  "import 'lib';"

test "import default member from module, adding the member to the current scope", ->
  eqJS """
    import foo from 'lib'
    foo.fooMethod()""",
  """
    import foo from 'lib';

    foo.fooMethod();"""

test "import an entire module's contents as an alias, adding the alias to the current scope", ->
  eqJS """
    import * as foo from 'lib'
    foo.fooMethod()""",
  """
    import * as foo from 'lib';

    foo.fooMethod();"""

test "import empty object", ->
  eqJS "import { } from 'lib'",
  "import {} from 'lib';"

test "import empty object", ->
  eqJS "import {} from 'lib'",
  "import {} from 'lib';"

test "import a single member of a module, adding the member to the current scope", ->
  eqJS """
    import { foo } from 'lib'
    foo.fooMethod()""",
  """
    import {
      foo
    } from 'lib';

    foo.fooMethod();"""

test "import a single member of a module as an alias, adding the alias to the current scope", ->
  eqJS """
    import { foo as bar } from 'lib'
    bar.barMethod()""",
  """
    import {
      foo as bar
    } from 'lib';

    bar.barMethod();"""

test "import multiple members of a module, adding the members to the current scope", ->
  eqJS """
    import { foo, bar } from 'lib'
    foo.fooMethod()
    bar.barMethod()""",
  """
    import {
      foo,
      bar
    } from 'lib';

    foo.fooMethod();

    bar.barMethod();"""

test "import multiple members of a module where some are aliased, adding the members or aliases to the current scope", ->
  eqJS """
    import { foo, bar as baz } from 'lib'
    foo.fooMethod()
    baz.bazMethod()""",
  """
    import {
      foo,
      bar as baz
    } from 'lib';

    foo.fooMethod();

    baz.bazMethod();"""

test "import default member and other members of a module, adding the members to the current scope", ->
  eqJS """
    import foo, { bar, baz as qux } from 'lib'
    foo.fooMethod()
    bar.barMethod()
    qux.quxMethod()""",
  """
    import foo, {
      bar,
      baz as qux
    } from 'lib';

    foo.fooMethod();

    bar.barMethod();

    qux.quxMethod();"""

test "import default member from a module as well as the entire module's contents as an alias, adding the member and alias to the current scope", ->
  eqJS """
    import foo, * as bar from 'lib'
    foo.fooMethod()
    bar.barMethod()""",
  """
    import foo, * as bar from 'lib';

    foo.fooMethod();

    bar.barMethod();"""

test "multiline simple import", ->
  eqJS """
    import {
      foo,
      bar as baz
    } from 'lib'""",
  """
    import {
      foo,
      bar as baz
    } from 'lib';"""

test "multiline complex import", ->
  eqJS """
    import foo, {
      bar,
      baz as qux
    } from 'lib'""",
  """
    import foo, {
      bar,
      baz as qux
    } from 'lib';"""

test "import with optional commas", ->
  eqJS "import { foo, bar, } from 'lib'",
  """
    import {
      foo,
      bar
    } from 'lib';"""

test "multiline import without commas", ->
  eqJS """
    import {
      foo
      bar
    } from 'lib'""",
  """
    import {
      foo,
      bar
    } from 'lib';"""

test "multiline import with optional commas", ->
  eqJS """
    import {
      foo,
      bar,
    } from 'lib'""",
  """
    import {
      foo,
      bar
    } from 'lib';"""

test "a variable can be assigned after an import", ->
  eqJS """
    import { foo } from 'lib'
    bar = 5""",
  """
    var bar;

    import {
      foo
    } from 'lib';

    bar = 5;"""

test "variables can be assigned before and after an import", ->
  eqJS """
    foo = 5
    import { bar } from 'lib'
    baz = 7""",
  """
    var baz, foo;

    foo = 5;

    import {
      bar
    } from 'lib';

    baz = 7;"""

# Export statements

test "export empty object", ->
  eqJS "export { }",
  "export {};"

test "export empty object", ->
  eqJS "export {}",
  "export {};"

test "export named members within an object", ->
  eqJS "export { foo, bar }",
  """
    export {
      foo,
      bar
    };"""

test "export named members as aliases, within an object", ->
  eqJS "export { foo as bar, baz as qux }",
  """
    export {
      foo as bar,
      baz as qux
    };"""

test "export named members within an object, with an optional comma", ->
  eqJS "export { foo, bar, }",
  """
    export {
      foo,
      bar
    };"""

test "multiline export named members within an object", ->
  eqJS """
    export {
      foo,
      bar
    }""",
  """
    export {
      foo,
      bar
    };"""

test "multiline export named members within an object, with an optional comma", ->
  eqJS """
    export {
      foo,
      bar,
    }""",
  """
    export {
      foo,
      bar
    };"""

test "export default string", ->
  eqJS "export default 'foo'",
  "export default 'foo';"

test "export default number", ->
  eqJS "export default 5",
  "export default 5;"

test "export default object", ->
  eqJS "export default { foo: 'bar', baz: 'qux' }",
  """
    export default {
      foo: 'bar',
      baz: 'qux'
    };"""

test "export default implicit object", ->
  eqJS "export default foo: 'bar', baz: 'qux'",
  """
    export default {
      foo: 'bar',
      baz: 'qux'
    };"""

test "export default multiline implicit object", ->
  eqJS """
    export default
      foo: 'bar'
      baz: 'qux'
    """,
  """
    export default {
      foo: 'bar',
      baz: 'qux'
    };"""

test "export default multiline implicit object with internal braces", ->
  eqJS """
    export default
      foo: yes
      bar: {
        baz
      }
      quz: no
    """,
  """
    export default {
      foo: true,
      bar: {baz},
      quz: false
    };"""

test "export default assignment expression", ->
  eqJS "export default foo = 'bar'",
  """
    var foo;

    export default foo = 'bar';"""

test "export assignment expression", ->
  eqJS "export foo = 'bar'",
  "export var foo = 'bar';"

test "export multiline assignment expression", ->
  eqJS """
    export foo =
    'bar'""",
    "export var foo = 'bar';"

test "export multiline indented assignment expression", ->
  eqJS """
    export foo =
      'bar'""",
      "export var foo = 'bar';"

test "export default function", ->
  eqJS "export default ->",
  "export default function() {};"

test "export default multiline function", ->
  eqJS """
    export default (foo) ->
      console.log foo""",
    """
    export default function(foo) {
      return console.log(foo);
    };"""

test "export assignment function", ->
  eqJS """
    export foo = (bar) ->
      console.log bar""",
    """
    export var foo = function(bar) {
      return console.log(bar);
    };"""

test "export assignment function which contains assignments in its body", ->
  eqJS """
    export foo = (bar) ->
      baz = '!'
      console.log bar + baz""",
    """
    export var foo = function(bar) {
      var baz;
      baz = '!';
      return console.log(bar + baz);
    };"""

test "export default predefined function", ->
  eqJS """
    foo = (bar) ->
      console.log bar
    export default foo""",
  """
    var foo;

    foo = function(bar) {
      return console.log(bar);
    };

    export default foo;"""

test "export default class", ->
  eqJS """
    export default class foo extends bar
      baz: ->
        console.log 'hello, world!'""",
      """
    var foo;

    export default foo = class foo extends bar {
      baz() {
        return console.log('hello, world!');
      }

    };"""

test "export class", ->
  eqJS """
    export class foo
      baz: ->
        console.log 'hello, world!'""",
      """
    export var foo = class foo {
      baz() {
        return console.log('hello, world!');
      }

    };"""

test "export class that extends", ->
  eqJS """
    export class foo extends bar
      baz: ->
        console.log 'hello, world!'""",
      """
    export var foo = class foo extends bar {
      baz() {
        return console.log('hello, world!');
      }

    };"""

test "export default class that extends", ->
  eqJS """
    export default class foo extends bar
      baz: ->
        console.log 'hello, world!'""",
      """
    var foo;

    export default foo = class foo extends bar {
      baz() {
        return console.log('hello, world!');
      }

    };"""

test "export default named member, within an object", ->
  eqJS "export { foo as default, bar }",
  """
    export {
      foo as default,
      bar
    };"""

# Import and export in the same statement

test "export an entire module's contents", ->
  eqJS "export * from 'lib'",
  "export * from 'lib';"

test "export members imported from another module", ->
  eqJS "export { foo, bar } from 'lib'",
  """
    export {
      foo,
      bar
    } from 'lib';"""

test "export as aliases members imported from another module", ->
  eqJS "export { foo as bar, baz as qux } from 'lib'",
  """
    export {
      foo as bar,
      baz as qux
    } from 'lib';"""

test "export list can contain CoffeeScript keywords", ->
  eqJS "export { unless, and } from 'lib'",
  """
    export {
      unless,
      and
    } from 'lib';"""

test "export list can contain CoffeeScript keywords when aliasing", ->
  eqJS "export { when as bar, baz as unless, and as foo, booze as not } from 'lib'",
  """
    export {
      when as bar,
      baz as unless,
      and as foo,
      booze as not
    } from 'lib';"""


# Edge cases

test "multiline import with comments", ->
  eqJS """
    import {
      foo, # Not as good as bar
      bar as baz # I prefer qux
    } from 'lib'""",
  """
    import {
      foo, // Not as good as bar
      bar as baz // I prefer qux
    } from 'lib';"""

test "`from` not part of an import or export statement can still be assigned", ->
  from = 5
  eq 5, from

test "a variable named `from` can be assigned after an import", ->
  eqJS """
    import { foo } from 'lib'
    from = 5""",
  """
    var from;

    import {
      foo
    } from 'lib';

    from = 5;"""

test "`from` can be assigned after a multiline import", ->
  eqJS """
    import {
      foo
    } from 'lib'
    from = 5""",
  """
    var from;

    import {
      foo
    } from 'lib';

    from = 5;"""

test "`from` can be imported as a member name", ->
  eqJS "import { from } from 'lib'",
  """
    import {
      from
    } from 'lib';"""

test "`from` can be imported as a member name and aliased", ->
  eqJS "import { from as foo } from 'lib'",
  """
    import {
      from as foo
    } from 'lib';"""

test "`from` can be used as an alias name", ->
  eqJS "import { foo as from } from 'lib'",
  """
    import {
      foo as from
    } from 'lib';"""

test "`as` can be imported as a member name", ->
  eqJS "import { as } from 'lib'",
  """
    import {
      as
    } from 'lib';"""

test "`as` can be imported as a member name and aliased", ->
  eqJS "import { as as foo } from 'lib'",
  """
    import {
      as as foo
    } from 'lib';"""

test "`as` can be used as an alias name", ->
  eqJS "import { foo as as } from 'lib'",
  """
    import {
      foo as as
    } from 'lib';"""

test "CoffeeScript keywords can be used as imported names in import lists", ->
  eqJS """
    import { unless as bar, and as computedAnd } from 'lib'
    bar.barMethod()""",
  """
    import {
      unless as bar,
      and as computedAnd
    } from 'lib';

    bar.barMethod();"""

test "`*` can be used in an expression on the same line as an export keyword", ->
  eqJS "export foo = (x) -> x * x",
  """
    export var foo = function(x) {
      return x * x;
    };"""
  eqJS "export default foo = (x) -> x * x",
  """
    var foo;

    export default foo = function(x) {
      return x * x;
    };"""

test "`*` and `from` can be used in an export default expression", ->
  eqJS """
    export default foo.extend
      bar: ->
        from = 5
        from = from * 3""",
      """
    export default foo.extend({
      bar: function() {
        var from;
        from = 5;
        return from = from * 3;
      }
    });"""

test "wrapped members can be imported multiple times if aliased", ->
  eqJS "import { foo, foo as bar } from 'lib'",
  """
    import {
      foo,
      foo as bar
    } from 'lib';"""

test "default and wrapped members can be imported multiple times if aliased", ->
  eqJS "import foo, { foo as bar } from 'lib'",
  """
    import foo, {
      foo as bar
    } from 'lib';"""

test "import a member named default", ->
  eqJS "import { default } from 'lib'",
  """
    import {
      default
    } from 'lib';"""

test "import an aliased member named default", ->
  eqJS "import { default as def } from 'lib'",
  """
    import {
      default as def
    } from 'lib';"""

test "export a member named default", ->
  eqJS "export { default }",
  """
    export {
      default
    };"""

test "export an aliased member named default", ->
  eqJS "export { def as default }",
  """
    export {
      def as default
    };"""

test "import an imported member named default", ->
  eqJS "import { default } from 'lib'",
  """
    import {
      default
    } from 'lib';"""

test "import an imported aliased member named default", ->
  eqJS "import { default as def } from 'lib'",
  """
    import {
      default as def
    } from 'lib';"""

test "export an imported member named default", ->
  eqJS "export { default } from 'lib'",
  """
    export {
      default
    } from 'lib';"""

test "export an imported aliased member named default", ->
  eqJS "export { default as def } from 'lib'",
  """
    export {
      default as def
    } from 'lib';"""

test "#4394: export shouldn't prevent variable declarations", ->
  eqJS """
    x = 1
    export { x }
  """,
  """
    var x;

    x = 1;

    export {
      x
    };
  """

test "#4451: `default` in an export statement is only treated as a keyword when it follows `export` or `as`", ->
  eqJS "export default { default: 1 }",
  """
    export default {
      default: 1
    };
  """

test "#4491: import- and export-specific lexing should stop after import/export statement", ->
  eqJS """
    import {
      foo,
      bar as baz
    } from 'lib'

    foo as
    3 * as 4
    from 'foo'
    """,
  """
    import {
      foo,
      bar as baz
    } from 'lib';

    foo(as);

    3 * as(4);

    from('foo');
    """

  eqJS """
    import { foo, bar as baz } from 'lib'

    foo as
    3 * as 4
    from 'foo'
    """,
  """
    import {
      foo,
      bar as baz
    } from 'lib';

    foo(as);

    3 * as(4);

    from('foo');
    """

  eqJS """
    import * as lib from 'lib'

    foo as
    3 * as 4
    from 'foo'
    """,
  """
    import * as lib from 'lib';

    foo(as);

    3 * as(4);

    from('foo');
    """

  eqJS """
    export {
      foo,
      bar
    }

    foo as
    3 * as 4
    from 'foo'
    """,
  """
    export {
      foo,
      bar
    };

    foo(as);

    3 * as(4);

    from('foo');
    """

  eqJS """
    export * from 'lib'

    foo as
    3 * as 4
    from 'foo'
    """,
  """
    export * from 'lib';

    foo(as);

    3 * as(4);

    from('foo');
    """

# Issue #4874: Backslash not supported in import or export statements
test "#4874: backslash `import`", ->

  eqJS """
    import foo \
        from 'lib'

    foo a
    """,
  """
    import foo from 'lib';

    foo(a);
    """

  eqJS """
    import \
                    foo \
        from \
    'lib'

    foo a
    """,
  """
    import foo from 'lib';

    foo(a);
    """

  eqJS """
    import \
          utilityBelt \
    , {
      each
    } from \
    'underscore'
    """,
  """
    import utilityBelt, {
      each
    } from 'underscore';
    """

test "#4874: backslash `export`", ->
  eqJS """
    export \
      * \
            from \
      'underscore'
    """,
  """
    export * from 'underscore';
    """

  eqJS """
    export \
        { max, min } \
              from \
      'underscore'
  """,
  """
    export {
      max,
      min
    } from 'underscore';
    """

test "#4834: dynamic import", ->
  eqJS """
    import('module').then ->
  """,
  """
    import('module').then(function() {});
  """

  eqJS """
    foo = ->
      bar = await import('bar')
  """,
  """
    var foo;

    foo = async function() {
      var bar;
      return bar = (await import('bar'));
    };
  """
