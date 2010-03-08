Jison
=====
* [issues](http://github.com/zaach/jison/issues)
* [discuss](mailto:jison@librelist.com)

An API for creating parsers in JavaScript
-----------------------------------------

Jison generates bottom-up parsers in JavaScript. Its API is similar to Bison's, hence the name. It supports many of Bison's major features, plus some of its own. If you are new to parser generators such as Bison, and Context-free Grammars in general, a [good introduction][1] is found in the Bison manual. If you already know Bison, Jison should be easy to pickup.

A brief warning before proceeding: **the API is ridiculously unstable** right now. The goal is to mirror Bison where it makes sense, but we're not even there yet. Also, optimization has not been a main focus as of yet.

Briefly, Jison takes a JSON encoded grammar specification and outputs a JavaScript file capable of parsing the language described by that grammar specification. You can then use the generated script to parse inputs and accept, reject, or perform actions based on the input.

Installation
------------
**Prerequisite**: To run Jison from the command line, you'll need to have [Narwhal][2] installed and available from your `PATH`.

Clone the github repository:

    git clone git://github.com/zaach/jison.git

Usage from the command line
-----------------------

Now you're ready to generate some parsers:

    cd jison
    narwhal bin/jison examples/calculator.jison examples/calculator.jisonlex

This will generate a `calculator.js` file in your current working directory. This file can be used to parse an input file, like so:

    echo "2^32 / 1024" > testcalc
    narwhal calculator.js testcalc

This will print out `4194304`.

Usage from a CommonJS module
--------------------------

You can generate parsers programatically from JavaScript as well. Assuming Jison is in your commonjs environment's load path:

    // mygenerator.js
    var Parser = require("jison").Parser;
    
    var grammar = {
        "lex": {
            "rules": [
               ["\\s+", "/* skip whitespace */"],
               ["[a-f0-9]+", "return 'HEX';"]
            ]
        },
    
        "bnf": {
            "hex_strings" :[ "hex_strings HEX",
                             "HEX" ]
        }
    };
    
    var parser = new Parser(grammar);
    
    // generate source, ready to be written to disk
    var parserSource = parser.generate();
    
    // you can also use the parser directly from memory
    
    // returns true
    parser.parse("adfe34bc e82a");
    
    // throws lexical error
    parser.parse("adfe34bc zxg");

Using the generated parser
--------------------------
So, you have generated your parser through the command line or JavaScript API and have saved it to disk. Now it can be put to use.

As demonstrated before, the parser can be used from the command line:    

    narwhal calculator.js testcalc

Though, more ideally, the parser will be a dependency of another module. You can require it from another module like so:

    // mymodule.js
    var parser = require("./calculator").parser;
    
    function exec (input) {
        return parser.parse(input);
    }

    var twenty = exec("4 * 5");
    
Or more succinctly:

    // mymodule.js
    function exec (input) {
        return require("./calculator").parse(input);
    }
    
    var twenty = exec("4 * 5");

Using the parser in a web page
----------------------------

The generated parser script may be included in a web page without any need for a CommonJS loading environment. It's as simple as pointing to it via a scipt tag:

    <script src="calc.js"></script>

When you generate the parser, you can specify the variable name it will be declared as:

    // mygenerator.js
    var parserSource = generator.generate({moduleName: "calc"});
    // then write parserSource to a file called, say, calc.js

Whatever `moduleName` you specified will be the the variable you can access the parser from in your web page:

    <!-- mypage.html -->
    ...
    <script src="calc.js"></script>
    <script>
      calc.parse("42 / 0");
    </script>
    ...

The moduleName you specify can also include a namespace, e.g:
    // mygenerator.js
    var parserSource = parser.generate({moduleName: "myCalculator.parser"});

And could be used like so:

    <!-- mypage.html -->
    ...
    <script>
      var myCalculator = {};
    </script>
    <script src="calc.js"></script>
    <script>
      myCalculator.parser.parse("42 / 0");
    </script>
    ...

Or something like that -- you get the picture.

A demo of the calculator script used in a web page is [here](http://zaach.github.com/jison/demo/calc.html) and the source of the page and the narwhal script to generate the parser are [here](http://gist.github.com/265842).

Specifying a language
---------------------
The process of parsing a language involves two phases: **lexical analysis** (tokenizing) and **parsing**, which the Lex/Yacc and Flex/Bison combinations are famous for. Jison lets you specify a parser much like you would using Bison/Flex, with separate files for tokenization rules and for the language grammar. 

For example, here is the calculator parser:

calc.jisonlex, tokenization rules

    %%
    \s+                   {/* skip whitespace */}
    [0-9]+("."[0-9]+)?\b  {return 'NUMBER';}
    "*"                   {return '*';}
    "/"                   {return '/';}
    "-"                   {return '-';}
    "+"                   {return '+';}
    "^"                   {return '^';}
    "("                   {return '(';}
    ")"                   {return ')';}
    "PI"                  {return 'PI';}
    "E"                   {return 'E';}
    <<EOF>>               {return 'EOF';}

and calc.jison, language grammar

    /* description: Grammar for a parser that parses and executes mathematical expressions. */

    %left '+' '-'
    %left '*' '/'
    %left '^'
    %left UMINUS

    %%

    S
        : e EOF
            {print($1); return $1;}
        ;

    e
        : e '+' e
            {$$ = $1+$3;}
        | e '-' e
            {$$ = $1-$3;}
        | e '*' e
            {$$ = $1*$3;}
        | e '/' e
            {$$ = $1/$3;}
        | e '^' e
            {$$ = Math.pow($1, $3);}
        | '-' e %prec UMINUS
            {$$ = -$2;}
        | '(' e ')'
            {$$ = $2;}
        | NUMBER
            {$$ = Number(yytext);}
        | E
            {$$ = Math.E;}
        | PI
            {$$ = Math.PI;}
        ;

which compiles down to this JSON:

    {
        "lex": {
            "rules": [
               ["\\s+",                    "/* skip whitespace */"],
               ["[0-9]+(?:\\.[0-9]+)?\\b", "return 'NUMBER';"],
               ["\\*",                     "return '*';"],
               ["\\/",                     "return '/';"],
               ["-",                       "return '-';"],
               ["\\+",                     "return '+';"],
               ["\\^",                     "return '^';"],
               ["\\(",                     "return '(';"],
               ["\\)",                     "return ')';"],
               ["PI\\b",                   "return 'PI';"],
               ["E\\b",                    "return 'E';"],
               ["$",                       "return 'EOF';"]
            ]
        },
    
        "operators": [
            ["left", "+", "-"],
            ["left", "*", "/"],
            ["left", "^"],
            ["left", "UMINUS"]
        ],
    
        "bnf": {
            "S" :[[ "e EOF",   "print($1); return $1;"  ]],
    
            "e" :[[ "e + e",   "$$ = $1+$3;" ],
                  [ "e - e",   "$$ = $1-$3;" ],
                  [ "e * e",   "$$ = $1*$3;" ],
                  [ "e / e",   "$$ = $1/$3;" ],
                  [ "e ^ e",   "$$ = Math.pow($1, $3);" ],
                  [ "- e",     "$$ = -$2;", {"prec": "UMINUS"} ],
                  [ "( e )",   "$$ = $2;" ],
                  [ "NUMBER",  "$$ = Number(yytext);" ],
                  [ "E",       "$$ = Math.E;" ],
                  [ "PI",      "$$ = Math.PI;" ]]
        }
    }

Jison accepts both the Bison/Flex style formats, or the raw JSON format, e.g:

    narwhal bin/jison examples/calculator.jison examples/calculator.jisonlex
or
    narwhal bin/jison examples/calculator.json

More examples can be found in the `examples/` and `tests/parser/` directories.

Sharing scope
------------

In Bison, code is expected to be lexically defined within the scope of the semantic actions. E.g., chunks of code may be included in the generated parser source, which are available from semantic actions.

Jison is more modular. Instead of pulling code into the generated module, the generated module is expected to be required and used by other modules. This means that if you want to expose functionality to the semantic actions, you can't rely on it being available through lexical scoping. Instead, the parser has a `yy` property which is exposed to actions as the `yy` free variable. Any functionality attached to this property is available in both lexical and semantic actions through the `yy` free variable.

An example from orderly.js:

    var parser = require("./orderly/parse").parser;
    
    // set parser's shared scope
    parser.yy = require("./orderly/scope");

    // returns the JSON object
    var parse = exports.parse = function (input) {
        return parser.parse(input);
    };
    ...

The `scope` module contains logic for building data structures, which is used within the semantic actions.

*TODO: More on this.*

Lexical Analysis
----------------
Jison includes a rather rudimentary lexer, though **any module that supports the basic lexer API could be used** in its place. Jison's lexer uses the `lex` key of the JSON grammar spec, where the rules for matching a token are defined along with the action to execute on a match. Usually, the action will return the token which is used by the Jison parser. A custom lexer could be used instead with it's own methods of tokenizing.

*TODO: More on this.*

Parsing algorithms
------------------
Like Bison, Jison can recognize languages described by LALR(1) grammars, though it also has modes for LR(0), SLR(1), and LR(1). It also has a special mode for generating LL(1) parse tables (requested by my professor,) and could be extended to generate a recursive descent parser for LL(k) languages in the future. But, for now, Jison is geared toward bottom-up parsing.

**LR(1) mode is currently not practical for use with anything other than toy grammars, but that is entirely a consequence of the algorithm used, and may change in the future.*

Real world examples
------------------

* [CoffeeScript](http://github.com/jashkenas/coffee-script) uses Jison in its self-compiler.
* [Orderly.js][3] uses Jison for compilation.


Contributors
------------
 - Zach Carter
 - Jarred Ligatti
 - Manuel E. Bermúdez 

License
-------

> Copyright (c) 2009 Zachary Carter
> 
>  Permission is hereby granted, free of
> charge, to any person  obtaining a
> copy of this software and associated
> documentation  files (the "Software"),
> to deal in the Software without 
> restriction, including without
> limitation the rights to use,  copy,
> modify, merge, publish, distribute,
> sublicense, and/or sell  copies of the
> Software, and to permit persons to
> whom the  Software is furnished to do
> so, subject to the following 
> conditions:
> 
>  The above copyright notice and this
> permission notice shall be  included
> in all copies or substantial portions
> of the Software.
> 
>  THE SOFTWARE IS PROVIDED "AS IS",
> WITHOUT WARRANTY OF ANY KIND,  EXPRESS
> OR IMPLIED, INCLUDING BUT NOT LIMITED
> TO THE WARRANTIES  OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND 
> NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT  HOLDERS BE
> LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY,  WHETHER IN AN ACTION OF
> CONTRACT, TORT OR OTHERWISE, ARISING 
> FROM, OUT OF OR IN CONNECTION WITH THE
> SOFTWARE OR THE USE OR  OTHER DEALINGS
> IN THE SOFTWARE.


  [1]: http://dinosaur.compilertools.net/bison/bison_4.html
  [2]: http://github.com/280north/narwhal
  [3]: http://github.com/zaach/orderly.js
