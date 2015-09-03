<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
  <title>CoffeeScript</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <link rel="canonical" href="http://coffeescript.org" />
  <link rel="stylesheet" type="text/css" href="documentation/css/docs.css" />
  <link rel="stylesheet" type="text/css" href="documentation/css/tomorrow.css" />
  <link rel="shortcut icon" href="documentation/images/favicon.ico" />
</head>
<body>

  <div id="fadeout"></div>

  <div id="flybar">
    <a id="logo" href="#top"><img src="documentation/images/logo.png" width="225" height="39" alt="CoffeeScript" /></a>
    <div class="navigation toc">
      <div class="button">
        Table of Contents
      </div>
      <div class="contents menu">
        <a href="#overview">Overview</a>
        <a href="#installation">Installation</a>
        <a href="#usage">Usage</a>
        <a href="#literate">Literate CoffeeScript</a>
        <a href="#language">Language Reference</a>
        <a href="#literals">Literals: Functions, Objects and Arrays</a>
        <a href="#lexical-scope">Lexical Scoping and Variable Safety</a>
        <a href="#conditionals">If, Else, Unless, and Conditional Assignment</a>
        <a href="#splats">Splats...</a>
        <a href="#loops">Loops and Comprehensions</a>
        <a href="#slices">Array Slicing and Splicing</a>
        <a href="#expressions">Everything is an Expression</a>
        <a href="#operators">Operators and Aliases</a>
        <a href="#classes">Classes, Inheritance, and Super</a>
        <a href="#destructuring">Destructuring Assignment</a>
        <a href="#fat-arrow">Bound and Generator Functions</a>
        <a href="#embedded">Embedded JavaScript</a>
        <a href="#switch">Switch and Try/Catch</a>
        <a href="#comparisons">Chained Comparisons</a>
        <a href="#strings">String Interpolation, Block Strings, and Block Comments</a>
        <a href="#regexes">Block Regular Expressions</a>
        <a href="#cake">Cake, and Cakefiles</a>
        <a href="#source-maps">Source Maps</a>
        <a href="#scripts">"text/coffeescript" Script Tags</a>
        <a href="#resources">Books, Screencasts, Examples and Resources</a>
        <a href="#changelog">Change Log</a>
      </div>
    </div>
    <div class="navigation try">
      <div class="button">
        Try CoffeeScript
        <div class="repl_bridge"></div>
      </div>
      <div class="contents repl_wrapper">
        <div class="code">
          <div class="screenshadow tl"></div>
          <div class="screenshadow tr"></div>
          <div class="screenshadow bl"></div>
          <div class="screenshadow br"></div>
          <div id="repl_source_wrap">
            <textarea id="repl_source" rows="100" spellcheck="false">alert "Hello CoffeeScript!"</textarea>
          </div>
          <div id="repl_results_wrap"><pre id="repl_results"></pre></div>
          <div class="minibutton dark run" title="Ctrl-Enter">Run</div>
          <a class="minibutton permalink" id="repl_permalink">Link</a>
          <br class="clear" />
        </div>
      </div>
    </div>
    <div class="navigation annotated">
      <div class="button">
        Annotated Source
      </div>
      <div class="contents menu">
        <a href="documentation/docs/grammar.html">Grammar Rules &mdash; src/grammar</a>
        <a href="documentation/docs/lexer.html">Lexing Tokens &mdash; src/lexer</a>
        <a href="documentation/docs/rewriter.html">The Rewriter &mdash; src/rewriter</a>
        <a href="documentation/docs/nodes.html">The Syntax Tree &mdash; src/nodes</a>
        <a href="documentation/docs/scope.html">Lexical Scope &mdash; src/scope</a>
        <a href="documentation/docs/helpers.html">Helpers &amp; Utility Functions &mdash; src/helpers</a>
        <a href="documentation/docs/coffee-script.html">The CoffeeScript Module &mdash; src/coffee-script</a>
        <a href="documentation/docs/cake.html">Cake &amp; Cakefiles &mdash; src/cake</a>
        <a href="documentation/docs/command.html">"coffee" Command-Line Utility &mdash; src/command</a>
        <a href="documentation/docs/optparse.html">Option Parsing &mdash; src/optparse</a>
        <a href="documentation/docs/repl.html">Interactive REPL &mdash; src/repl</a>
        <a href="documentation/docs/sourcemap.html">Source Maps &mdash; src/sourcemap</a>
      </div>
    </div>
  </div>

  <div class="container">
    <span class="bookmark" id="top"></span>

    <p>
      <b>CoffeeScript is a little language that compiles into JavaScript.</b>
      Underneath that awkward Java-esque patina, JavaScript has always had
      a gorgeous heart. CoffeeScript is an attempt to expose
      the good parts of JavaScript in a simple way.
    </p>

    <p>
      The golden rule of CoffeeScript is: <i>"It's just JavaScript"</i>. The code
      compiles one-to-one into the equivalent JS, and there is
      no interpretation at runtime. You can use any existing JavaScript library
      seamlessly from CoffeeScript (and vice-versa). The compiled output is
      readable and pretty-printed, will work in every JavaScript runtime, and tends
      to run as fast or faster than the equivalent handwritten JavaScript.
    </p>

    <p>
      <b>Latest Version:</b>
      <a href="http://github.com/jashkenas/coffeescript/tarball/1.10.0">1.10.0</a>
    </p>

    <pre>npm install -g coffee-script</pre>

    <h2>
      <span id="overview" class="bookmark"></span>
      Overview
    </h2>

    <p><i>CoffeeScript on the left, compiled JavaScript output on the right.</i></p>

    <%= codeFor('overview', 'cubes', false) %>

    <h2>
      <span id="installation" class="bookmark"></span>
      Installation
    </h2>

    <p>
      The CoffeeScript compiler is itself
      <a href="documentation/docs/grammar.html">written in CoffeeScript</a>,
      using the <a href="http://jison.org">Jison parser generator</a>. The
      command-line version of <code>coffee</code> is available as a
      <a href="http://nodejs.org/">Node.js</a> utility. The
      <a href="extras/coffee-script.js">core compiler</a> however, does not
      depend on Node, and can be run in any JavaScript environment, or in the
      browser (see "Try CoffeeScript", above).
    </p>

    <p>
      To install, first make sure you have a working copy of the latest stable version of
      <a href="http://nodejs.org/">Node.js</a>. You can then install CoffeeScript globally
      with <a href="http://npmjs.org">npm</a>:
    </p>

    <pre>
npm install -g coffee-script</pre>

    <p>
      When you need CoffeeScript as a dependency, install it locally:
    </p>

    <pre>
npm install --save coffee-script</pre>

    <p>
      If you'd prefer to install the latest <b>master</b> version of CoffeeScript, you
      can clone the CoffeeScript
      <a href="http://github.com/jashkenas/coffeescript">source repository</a>
      from GitHub, or download
      <a href="http://github.com/jashkenas/coffeescript/tarball/master">the source</a> directly.
      To install the latest master CoffeeScript compiler with npm:
    </p>

<pre>
npm install -g jashkenas/coffeescript</pre>

    <p>
      Or, if you want to install to <code>/usr/local</code>, and don't want to use
      npm to manage it, open the <code>coffee-script</code> directory and run:
    </p>

  <pre>
sudo bin/cake install</pre>

    <h2>
      <span id="usage" class="bookmark"></span>
      Usage
    </h2>

    <p>
      Once installed, you should have access to the <code>coffee</code> command,
      which can execute scripts, compile <code>.coffee</code> files into <code>.js</code>,
      and provide an interactive REPL. The <code>coffee</code> command takes the
      following options:
    </p>

    <table>
      <tr>
        <td><code>-c, --compile</code></td>
        <td>
          Compile a <code>.coffee</code> script into a <code>.js</code> JavaScript file
          of the same name.
        </td>
      </tr>
      <tr>
        <td><code>-m, --map</code></td>
        <td>
          Generate source maps alongside the compiled JavaScript files. Adds
          <code>sourceMappingURL</code> directives to the JavaScript as well.
        </td>
      </tr>
      <tr>
        <td width="25%"><code>-i, --interactive</code></td>
        <td>
          Launch an interactive CoffeeScript session to try short snippets.
          Identical to calling <code>coffee</code> with no arguments.
        </td>
      </tr>
      <tr>
        <td><code>-o, --output [DIR]</code></td>
        <td>
          Write out all compiled JavaScript files into the specified directory.
          Use in conjunction with <code>--compile</code> or <code>--watch</code>.
        </td>
      </tr>
      <tr>
        <td><code>-j, --join [FILE]</code></td>
        <td>
          Before compiling, concatenate all scripts together in the order they
          were passed, and write them into the specified file.
          Useful for building large projects.
        </td>
      </tr>
      <tr>
        <td><code>-w, --watch</code></td>
        <td>
          Watch files for changes, rerunning the specified command when any
          file is updated.
        </td>
      </tr>
      <tr>
        <td><code>-p, --print</code></td>
        <td>
          Instead of writing out the JavaScript as a file, print it
          directly to <b>stdout</b>.
        </td>
      </tr>
      <tr>
        <td><code>-s, --stdio</code></td>
        <td>
          Pipe in CoffeeScript to STDIN and get back JavaScript over STDOUT.
          Good for use with processes written in other languages. An example:<br />
          <code>cat src/cake.coffee | coffee -sc</code>
        </td>
      </tr>
      <tr>
        <td><code>-l, --literate</code></td>
        <td>
          Parses the code as Literate CoffeeScript. You only need to specify
          this when passing in code directly over <b>stdio</b>, or using some sort
          of extension-less file name.
        </td>
      </tr>
      <tr>
        <td><code>-e, --eval</code></td>
        <td>
          Compile and print a little snippet of CoffeeScript directly from the
          command line. For example:<br /><code>coffee -e "console.log num for num in [10..1]"</code>
        </td>
      </tr>
      <tr>
        <td><code>-b, --bare</code></td>
        <td>
          Compile the JavaScript without the
          <a href="#lexical-scope">top-level function safety wrapper</a>.
        </td>
      </tr>
      <tr>
        <td><code>-t, --tokens</code></td>
        <td>
          Instead of parsing the CoffeeScript, just lex it, and print out the
          token stream: <code>[IDENTIFIER square] [ASSIGN =] [PARAM_START (]</code> ...
        </td>
      </tr>
      <tr>
        <td><code>-n, --nodes</code></td>
        <td>
          Instead of compiling the CoffeeScript, just lex and parse it, and print
          out the parse tree:
<pre class="no_bar">
Expressions
  Assign
    Value "square"
    Code "x"
      Op *
        Value "x"
        Value "x"</pre>
        </td>
      </tr>
      <tr>
        <td><code>--nodejs</code></td>
        <td>
          The <code>node</code> executable has some useful options you can set,
          such as<br /> <code>--debug</code>, <code>--debug-brk</code>, <code>--max-stack-size</code>,
          and <code>--expose-gc</code>. Use this flag to forward options directly to Node.js.
          To pass multiple flags, use <code>--nodejs</code> multiple times.
        </td>
      </tr>
    </table>

    <p>
      <b>Examples:</b>
    </p>

    <ul>
      <li>
        Compile a directory tree of <code>.coffee</code> files in <code>src</code> into a parallel
        tree of <code>.js</code> files in <code>lib</code>:<br />
        <code>coffee --compile --output lib/ src/</code>
      </li>
      <li>
        Watch a file for changes, and recompile it every time the file is saved:<br />
        <code>coffee --watch --compile experimental.coffee</code>
      </li>
      <li>
        Concatenate a list of files into a single script:<br />
        <code>coffee --join project.js --compile src/*.coffee</code>
      </li>
      <li>
        Print out the compiled JS from a one-liner:<br />
        <code>coffee -bpe "alert i for i in [0..10]"</code>
      </li>
      <li>
        All together now, watch and recompile an entire project as you work on it:<br />
        <code>coffee -o lib/ -cw src/</code>
      </li>
      <li>
        Start the CoffeeScript REPL (<code>Ctrl-D</code> to exit, <code>Ctrl-V</code>for multi-line):<br />
        <code>coffee</code>
      </li>
    </ul>

    <h2>
      <span id="literate" class="bookmark"></span>
      Literate CoffeeScript
    </h2>

    <p>
      Besides being used as an ordinary programming language, CoffeeScript may
      also be written in "literate" mode. If you name your file with a
      <code>.litcoffee</code> extension, you can write it as a Markdown document &mdash;
      a document that also happens to be executable CoffeeScript code. The compiler
      will treat any indented blocks (Markdown's way of indicating source code)
      as code, and ignore the rest as comments.
    </p>

    <p>
      Just for kicks, a little bit of the compiler is currently implemented in this fashion:
      See it
      <a href="https://gist.github.com/jashkenas/3fc3c1a8b1009c00d9df">as a document</a>,
      <a href="https://raw.github.com/jashkenas/coffeescript/master/src/scope.litcoffee">raw</a>,
      and <a href="http://cl.ly/LxEu">properly highlighted in a text editor</a>.
    </p>

    <p>
      I'm fairly excited about this direction for the language, and am looking
      forward to writing (and more importantly, reading) more programs in this style.
      More information about Literate CoffeeScript, including an
      <a href="https://github.com/jashkenas/journo">example program</a>,
      are <a href="http://ashkenas.com/literate-coffeescript">available in this blog post</a>.
    </p>

    <h2>
      <span id="language" class="bookmark"></span>
      Language Reference
    </h2>

    <p>
      <i>
        This reference is structured so that it can be read from top to bottom,
        if you like. Later sections use ideas and syntax previously introduced.
        Familiarity with JavaScript is assumed.
        In all of the following examples, the source CoffeeScript is provided on
        the left, and the direct compilation into JavaScript is on the right.
      </i>
    </p>

    <p>
      <i>
        Many of the examples can be run (where it makes sense) by pressing the <b>run</b>
        button on the right, and can be loaded into the "Try CoffeeScript"
        console by pressing the <b>load</b> button on the left.
      </i>
    <p>
      First, the basics: CoffeeScript uses significant whitespace to delimit blocks of code.
      You don't need to use semicolons <code>;</code> to terminate expressions,
      ending the line will do just as well (although semicolons can still
      be used to fit multiple expressions onto a single line).
      Instead of using curly braces
      <code>{ }</code> to surround blocks of code in <a href="#literals">functions</a>,
      <a href="#conditionals">if-statements</a>,
      <a href="#switch">switch</a>, and <a href="#try">try/catch</a>,
      use indentation.
    </p>

    <p>
      You don't need to use parentheses to invoke a function if you're passing
      arguments. The implicit call wraps forward to the end of the line or block expression.<br />
      <code>console.log sys.inspect object</code> &rarr; <code>console.log(sys.inspect(object));</code>
    </p>

    <p>
      <span id="literals" class="bookmark"></span>
      <b class="header">Functions</b>
      Functions are defined by an optional list of parameters in parentheses,
      an arrow, and the function body. The empty function looks like this:
      <code>-></code>
    </p>
    <%= codeFor('functions', 'cube(5)') %>
    <p>
      Functions may also have default values for arguments, which will be used
      if the incoming argument is missing (<code>null</code> or <code>undefined</code>).
    </p>
    <%= codeFor('default_args', 'fill("cup")') %>

    <p>
      <span id="objects_and_arrays" class="bookmark"></span>
      <b class="header">Objects and Arrays</b>
      The CoffeeScript literals for objects and arrays look very similar to
      their JavaScript cousins. When each property is listed on its own line,
      the commas are optional. Objects may be created using indentation instead
      of explicit braces, similar to <a href="http://yaml.org">YAML</a>.
    </p>
    <%= codeFor('objects_and_arrays', 'song.join(" ... ")') %>
    <p>
      In JavaScript, you can't use reserved words, like <code>class</code>, as properties
      of an object, without quoting them as strings. CoffeeScript notices reserved words
      used as keys in objects and quotes them for you, so you don't have to worry
      about it (say, when using jQuery).
    </p>
    <%= codeFor('objects_reserved') %>

    <p>
      <span id="lexical-scope" class="bookmark"></span>
      <b class="header">Lexical Scoping and Variable Safety</b>
      The CoffeeScript compiler takes care to make sure that all of your variables
      are properly declared within lexical scope &mdash; you never need to write
      <code>var</code> yourself.
    </p>
    <%= codeFor('scope', 'inner') %>
    <p>
      Notice how all of the variable declarations have been pushed up to
      the top of the closest scope, the first time they appear.
      <b>outer</b> is not redeclared within the inner function, because it's
      already in scope; <b>inner</b> within the function, on the other hand,
      should not be able to change the value of the external variable of the same name, and
      therefore has a declaration of its own.
    </p>
    <p>
      This behavior is effectively identical to Ruby's scope for local variables.
      Because you don't have direct access to the <code>var</code> keyword,
      it's impossible to shadow an outer variable on purpose, you may only refer
      to it. So be careful that you're not reusing the name of an external
      variable accidentally, if you're writing a deeply nested function.
    </p>
    <p>
      Although suppressed within this documentation for clarity, all
      CoffeeScript output is wrapped in an anonymous function:
      <code>(function(){ ... })();</code> This safety wrapper, combined with the
      automatic generation of the <code>var</code> keyword, make it exceedingly difficult
      to pollute the global namespace by accident.
    </p>
    <p>
      If you'd like to create top-level variables for other scripts to use,
      attach them as properties on <b>window</b>, or on the <b>exports</b>
      object in CommonJS. The <b>existential operator</b> (covered below), gives you a
      reliable way to figure out where to add them; if you're targeting both
      CommonJS and the browser: <code>exports ? this</code>
    </p>

    <p>
      <span id="conditionals" class="bookmark"></span>
      <b class="header">If, Else, Unless, and Conditional Assignment</b>
      <b>If/else</b> statements can be written without the use of parentheses and
      curly brackets. As with functions and other block expressions,
      multi-line conditionals are delimited by indentation. There's also a handy
      postfix form, with the <code>if</code> or <code>unless</code> at the end.
    </p>
    <p>
      CoffeeScript can compile <b>if</b> statements into JavaScript expressions,
      using the ternary operator when possible, and closure wrapping otherwise. There
      is no explicit ternary statement in CoffeeScript &mdash; you simply use
      a regular <b>if</b> statement on a single line.
    </p>
    <%= codeFor('conditionals') %>

    <p>
      <span id="splats" class="bookmark"></span>
      <b class="header">Splats...</b>
      The JavaScript <b>arguments object</b> is a useful way to work with
      functions that accept variable numbers of arguments. CoffeeScript provides
      splats <code>...</code>, both for function definition as well as invocation,
      making variable numbers of arguments a little bit more palatable.
    </p>
    <%= codeFor('splats', true) %>

    <p>
      <span id="loops" class="bookmark"></span>
      <b class="header">Loops and Comprehensions</b>
      Most of the loops you'll write in CoffeeScript will be <b>comprehensions</b>
      over arrays, objects, and ranges. Comprehensions replace (and compile into)
      <b>for</b> loops, with optional guard clauses and the value of the current array index.
      Unlike for loops, array comprehensions are expressions, and can be returned
      and assigned.
    </p>
    <%= codeFor('array_comprehensions') %>
    <p>
      Comprehensions should be able to handle most places where you otherwise
      would use a loop, <b>each</b>/<b>forEach</b>, <b>map</b>, or <b>select</b>/<b>filter</b>, for example:
      <code>shortNames = (name for name in list when name.length &lt; 5)</code><br />
      If you know the start and end of your loop, or would like to step through
      in fixed-size increments, you can use a range to specify the start and
      end of your comprehension.
    </p>
    <%= codeFor('range_comprehensions', 'countdown') %>
    <p>
      Note how because we are assigning the value of the comprehensions to a
      variable in the example above, CoffeeScript is collecting the result of
      each iteration into an array. Sometimes functions end with loops that are
      intended to run only for their side-effects. Be careful that you're not
      accidentally returning the results of the comprehension in these cases,
      by adding a meaningful return value &mdash; like <code>true</code> &mdash; or <code>null</code>,
      to the bottom of your function.
    </p>
    <p>
      To step through a range comprehension in fixed-size chunks,
      use <code>by</code>, for example:<br />
      <code>evens = (x for x in [0..10] by 2)</code>
    </p>
    <p>
      If you don't need the current iteration value you may omit it:<br />
      <code>browser.closeCurrentTab() for [0...count]</code>
    </p>
    <p>
      Comprehensions can also be used to iterate over the keys and values in
      an object. Use <code>of</code> to signal comprehension over the properties of
      an object instead of the values in an array.
    </p>
    <%= codeFor('object_comprehensions', 'ages.join(", ")') %>
    <p>
      If you would like to iterate over just the keys that are defined on the
      object itself, by adding a <code>hasOwnProperty</code>
      check to avoid properties that may be inherited from the prototype, use<br />
      <code>for own key, value of object</code>
    </p>
    <p>
      The only low-level loop that CoffeeScript provides is the <b>while</b> loop. The
      main difference from JavaScript is that the <b>while</b> loop can be used
      as an expression, returning an array containing the result of each iteration
      through the loop.
    </p>
    <%= codeFor('while', 'lyrics.join("\n")') %>
    <p>
      For readability, the <b>until</b> keyword is equivalent to <code>while not</code>,
      and the <b>loop</b> keyword is equivalent to <code>while true</code>.
    </p>
    <p>
      When using a JavaScript loop to generate functions, it's common to insert
      a closure wrapper in order to ensure that loop variables are closed over,
      and all the generated functions don't just share the final values. CoffeeScript
      provides the <code>do</code> keyword, which immediately invokes a passed function,
      forwarding any arguments.
    </p>
    <%= codeFor('do') %>

    <p>
      <span id="slices" class="bookmark"></span>
      <b class="header">Array Slicing and Splicing with Ranges</b>
      Ranges can also be used to extract slices of arrays.
      With two dots (<code>3..6</code>), the range is inclusive (<code>3, 4, 5, 6</code>);
      with three dots (<code>3...6</code>), the range excludes the end (<code>3, 4, 5</code>).
      Slices indices have useful defaults. An omitted first index defaults to
      zero and an omitted second index defaults to the size of the array.
    </p>
    <%= codeFor('slices', 'middle') %>
    <p>
      The same syntax can be used with assignment to replace a segment of an array
      with new values, splicing it.
    </p>
    <%= codeFor('splices', 'numbers') %>
    <p>
      Note that JavaScript strings are immutable, and can't be spliced.
    </p>
    <p>
      <span id="expressions" class="bookmark"></span>
      <b class="header">Everything is an Expression (at least, as much as possible)</b>
      You might have noticed how even though we don't add return statements
      to CoffeeScript functions, they nonetheless return their final value.
      The CoffeeScript compiler tries to make sure that all statements in the
      language can be used as expressions. Watch how the <code>return</code> gets
      pushed down into each possible branch of execution in the function
      below.
    </p>
    <%= codeFor('expressions', 'eldest') %>
    <p>
      Even though functions will always return their final value, it's both possible
      and encouraged to return early from a function body writing out the explicit
      return (<code>return value</code>), when you know that you're done.
    </p>
    <p>
      Because variable declarations occur at the top of scope, assignment can
      be used within expressions, even for variables that haven't been seen before:
    </p>
    <%= codeFor('expressions_assignment', 'six') %>
    <p>
      Things that would otherwise be statements in JavaScript, when used
      as part of an expression in CoffeeScript, are converted into expressions
      by wrapping them in a closure. This lets you do useful things, like assign
      the result of a comprehension to a variable:
    </p>
    <%= codeFor('expressions_comprehension', 'globals') %>
    <p>
      As well as silly things, like passing a <b>try/catch</b> statement directly
      into a function call:
    </p>
    <%= codeFor('expressions_try', true) %>
    <p>
      There are a handful of statements in JavaScript that can't be meaningfully
      converted into expressions, namely <code>break</code>, <code>continue</code>,
      and <code>return</code>. If you make use of them within a block of code,
      CoffeeScript won't try to perform the conversion.
    </p>

    <p>
      <span id="operators" class="bookmark"></span>
      <b class="header">Operators and Aliases</b>
      Because the <code>==</code> operator frequently causes undesirable coercion,
      is intransitive, and has a different meaning than in other languages,
      CoffeeScript compiles <code>==</code> into <code>===</code>, and <code>!=</code> into
      <code>!==</code>.
      In addition, <code>is</code> compiles into <code>===</code>,
      and <code>isnt</code> into <code>!==</code>.
    </p>
    <p>
      You can use <code>not</code> as an alias for <code>!</code>.
    </p>
    <p>
      For logic, <code>and</code> compiles to <code>&amp;&amp;</code>, and <code>or</code>
      into <code>||</code>.
    </p>
    <p>
      Instead of a newline or semicolon, <code>then</code> can be used to separate
      conditions from expressions, in <b>while</b>,
      <b>if</b>/<b>else</b>, and <b>switch</b>/<b>when</b> statements.
    </p>
    <p>
      As in <a href="http://yaml.org/">YAML</a>, <code>on</code> and <code>yes</code>
      are the same as boolean <code>true</code>, while <code>off</code> and <code>no</code> are boolean <code>false</code>.
    </p>
    <p>
      <code>unless</code> can be used as the inverse of <code>if</code>.
    </p>
    <p>
      As a shortcut for <code>this.property</code>, you can use <code>@property</code>.
    </p>
    <p>
      You can use <code>in</code> to test for array presence, and <code>of</code> to
      test for JavaScript object-key presence.
    </p>
    <p>
      To simplify math expressions, <code>**</code> can be used for exponentiation
      and <code>//</code> performs integer division. <code>%</code> works just like in
      JavaScript, while <code>%%</code> provides
      <a href="http://en.wikipedia.org/wiki/Modulo_operation">“dividend dependent modulo”</a>:
    </p>
    <%= codeFor('modulo') %>
    <p>
      All together now:
    </p>

    <table class="definitions">
      <tr><th>CoffeeScript</th><th>JavaScript</th></tr>
      <tr><td><code>is</code></td><td><code>===</code></td></tr>
      <tr><td><code>isnt</code></td><td><code>!==</code></td></tr>
      <tr><td><code>not</code></td><td><code>!</code></td></tr>
      <tr><td><code>and</code></td><td><code>&amp;&amp;</code></td></tr>
      <tr><td><code>or</code></td><td><code>||</code></td></tr>
      <tr><td><code>true</code>, <code>yes</code>, <code>on</code></td><td><code>true</code></td></tr>
      <tr><td><code>false</code>, <code>no</code>, <code>off</code></td><td><code>false</code></td></tr>
      <tr><td><code>@</code>, <code>this</code></td><td><code>this</code></td></tr>
      <tr><td><code>of</code></td><td><code>in</code></td></tr>
      <tr><td><code>in</code></td><td><i><small>no JS equivalent</small></i></td></tr>
      <tr><td><code>a ** b</code></td><td><code>Math.pow(a, b)</code></td></tr>
      <tr><td><code>a // b</code></td><td><code>Math.floor(a / b)</code></td></tr>
      <tr><td><code>a %% b</code></td><td><code>(a % b + b) % b</code></td></tr>
    </table>

    <%= codeFor('aliases') %>

    <p>
      <b class="header">The Existential Operator</b>
      It's a little difficult to check for the existence of a variable in
      JavaScript. <code>if (variable) ...</code> comes close, but fails for zero,
      the empty string, and false. CoffeeScript's existential operator <code>?</code> returns true unless
      a variable is <b>null</b> or <b>undefined</b>, which makes it analogous
      to Ruby's <code>nil?</code>
    </p>
    <p>
      It can also be used for safer conditional assignment than <code>||=</code>
      provides, for cases where you may be handling numbers or strings.
    </p>
    <%= codeFor('existence', 'footprints') %>
    <p>
      The accessor variant of the existential operator <code>?.</code> can be used to soak
      up null references in a chain of properties. Use it instead
      of the dot accessor <code>.</code> in cases where the base value may be <b>null</b>
      or <b>undefined</b>. If all of the properties exist then you'll get the expected
      result, if the chain is broken, <b>undefined</b> is returned instead of
      the <b>TypeError</b> that would be raised otherwise.
    </p>
    <%= codeFor('soaks') %>
    <p>
      Soaking up nulls is similar to Ruby's
      <a href="https://rubygems.org/gems/andand">andand gem</a>, and to the
      <a href="http://groovy.codehaus.org/Operators#Operators-SafeNavigationOperator%28%3F.%29">safe navigation operator</a>
      in Groovy.
    </p>

    <p>
      <span id="classes" class="bookmark"></span>
      <b class="header">Classes, Inheritance, and Super</b>
      JavaScript's prototypal inheritance has always been a bit of a
      brain-bender, with a whole family tree of libraries that provide a cleaner
      syntax for classical inheritance on top of JavaScript's prototypes:
      <a href="http://code.google.com/p/base2/">Base2</a>,
      <a href="http://prototypejs.org/">Prototype.js</a>,
      <a href="http://jsclass.jcoglan.com/">JS.Class</a>, etc.
      The libraries provide syntactic sugar, but the built-in inheritance would
      be completely usable if it weren't for a couple of small exceptions:
      it's awkward to call <b>super</b> (the prototype object's
      implementation of the current function), and it's awkward to correctly
      set the prototype chain.
    </p>
    <p>
      Instead of repetitively attaching functions to a prototype, CoffeeScript
      provides a basic <code>class</code> structure that allows you to name your class,
      set the superclass, assign prototypal properties, and define the constructor,
      in a single assignable expression.
    </p>
    <p>
      Constructor functions are named, to better support helpful stack traces.
      In the first class in the example below, <code>this.constructor.name is "Animal"</code>.
    </p>
    <%= codeFor('classes', true) %>
    <p>
      If structuring your prototypes classically isn't your cup of tea, CoffeeScript
      provides a couple of lower-level conveniences. The <code>extends</code> operator
      helps with proper prototype setup, and can be used to create an inheritance
      chain between any pair of constructor functions; <code>::</code> gives you
      quick access to an object's prototype; and <code>super()</code>
      is converted into a call against the immediate ancestor's method of the same name.
    </p>
    <%= codeFor('prototypes', '"one_two".dasherize()') %>
    <p>
      Finally, class definitions are blocks of executable code, which make for interesting
      metaprogramming possibilities. Because in the context of a class definition,
      <code>this</code> is the class object itself (the constructor function), you
      can assign static properties by using <br /><code>@property: value</code>, and call
      functions defined in parent classes: <code>@attr 'title', type: 'text'</code>
    </p>

    <p>
      <span id="destructuring" class="bookmark"></span>
      <b class="header">Destructuring Assignment</b>
      Just like JavaScript (since ES2015), CoffeeScript has destructuring assignment
      syntax. When you assign an array or object literal to a value, CoffeeScript
      breaks up and matches both sides against each other, assigning the values
      on the right to the variables on the left. In the simplest case, it can be
      used for parallel assignment:
    </p>
    <%= codeFor('parallel_assignment', 'theBait') %>
    <p>
      But it's also helpful for dealing with functions that return multiple
      values.
    </p>
    <%= codeFor('multiple_return_values', 'forecast') %>
    <p>
      Destructuring assignment can be used with any depth of array and object nesting,
      to help pull out deeply nested properties.
    </p>
    <%= codeFor('object_extraction', 'name + "-" + street') %>
    <p>
      Destructuring assignment can even be combined with splats.
    </p>
    <%= codeFor('patterns_and_splats', 'contents.join("")') %>
    <p>
      Expansion can be used to retrieve elements from the end of an array without having to assign the rest of its values. It works in function parameter lists as well.
    </p>
    <%= codeFor('expansion', 'first + " " + last') %>
    <p>
      Destructuring assignment is also useful when combined with class constructors
      to assign properties to your instance from an options object passed to the constructor.
    </p>
    <%= codeFor('constructor_destructuring', 'tim.age + " " + tim.height') %>
    <p>
      The above example also demonstrates that if properties are missing in the
      destructured object or array, you can, just like in JavaScript, provide
      defaults. The difference with JavaScript is that CoffeeScript, as always,
      treats both null and undefined the same.
    </p>

    <p>
      <span id="fat-arrow" class="bookmark"></span>
      <b class="header">Bound Functions, Generator Functions</b>
      In JavaScript, the <code>this</code> keyword is dynamically scoped to mean the
      object that the current function is attached to. If you pass a function as
      a callback or attach it to a different object, the original value of <code>this</code>
      will be lost. If you're not familiar with this behavior,
      <a href="http://www.digital-web.com/articles/scope_in_javascript/">this Digital Web article</a>
      gives a good overview of the quirks.
    </p>
    <p>
      The fat arrow <code>=&gt;</code> can be used to both define a function, and to bind
      it to the current value of <code>this</code>, right on the spot. This is helpful
      when using callback-based libraries like Prototype or jQuery, for creating
      iterator functions to pass to <code>each</code>, or event-handler functions
      to use with <code>on</code>. Functions created with the fat arrow are able to access
      properties of the <code>this</code> where they're defined.
    </p>
    <%= codeFor('fat_arrow') %>
    <p>
      If we had used <code>-&gt;</code> in the callback above, <code>@customer</code> would
      have referred to the undefined "customer" property of the DOM element,
      and trying to call <code>purchase()</code> on it would have raised an exception.
    </p>
    <p>
      When used in a class definition, methods declared with the fat arrow will
      be automatically bound to each instance of the class when the instance is
      constructed.
    </p>
    <p>
      CoffeeScript functions also support
      <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/function*">ES6 generator functions</a>
      through the <code>yield</code> keyword. There's no <code>function*(){}</code>
      nonsense &mdash; a generator in CoffeeScript is simply a function that yields.
    </p>
    <%= codeFor('generators', 'ps.next().value') %>
    <p>
      <code>yield*</code> is called <code>yield from</code>, and <code>yield return</code>
      may be used if you need to force a generator that doesn't yield.
    </p>

    <p>
      <span id="embedded" class="bookmark"></span>
      <b class="header">Embedded JavaScript</b>
      Hopefully, you'll never need to use it, but if you ever need to intersperse
      snippets of JavaScript within your CoffeeScript, you can
      use backticks to pass it straight through.
    </p>
    <%= codeFor('embedded', 'hi()') %>

    <p>
      <span id="switch" class="bookmark"></span>
      <b class="header">Switch/When/Else</b>
      <b>Switch</b> statements in JavaScript are a bit awkward. You need to
      remember to <b>break</b> at the end of every <b>case</b> statement to
      avoid accidentally falling through to the default case.
      CoffeeScript prevents accidental fall-through, and can convert the <code>switch</code>
      into a returnable, assignable expression. The format is: <code>switch</code> condition,
      <code>when</code> clauses, <code>else</code> the default case.
    </p>
    <p>
      As in Ruby, <b>switch</b> statements in CoffeeScript can take multiple
      values for each <b>when</b> clause. If any of the values match, the clause
      runs.
    </p>
    <%= codeFor('switch') %>

    <p>
      Switch statements can also be used without a control expression, turning them in to a cleaner alternative to if/else chains.
    </p>
    <%= codeFor('switch_with_no_expression') %>

    <p>
      <span id="try" class="bookmark"></span>
      <b class="header">Try/Catch/Finally</b>
      Try-expressions have the same semantics as try-statements in JavaScript,
      though in CoffeeScript, you may omit <em>both</em> the catch and finally
      parts. The catch part may also omit the error parameter if it is not needed.
    </p>
    <%= codeFor('try') %>

    <p>
      <span id="comparisons" class="bookmark"></span>
      <b class="header">Chained Comparisons</b>
      CoffeeScript borrows
      <a href="http://docs.python.org/reference/expressions.html#notin">chained comparisons</a>
      from Python &mdash; making it easy to test if a value falls within a
      certain range.
    </p>
    <%= codeFor('comparisons', 'healthy') %>

    <p>
      <span id="strings" class="bookmark"></span>
      <b class="header">String Interpolation, Block Strings, and Block Comments</b>
      Ruby-style string interpolation is included in CoffeeScript. Double-quoted
      strings allow for interpolated values, using <code>#{ ... }</code>,
      and single-quoted strings are literal. You may even use interpolation in
      object keys.
    </p>
    <%= codeFor('interpolation', 'sentence') %>
    <p>
      Multiline strings are allowed in CoffeeScript. Lines are joined by a single space unless they end with a backslash. Indentation is ignored.
    </p>
    <%= codeFor('strings', 'mobyDick') %>
    <p>
      Block strings can be used to hold formatted or indentation-sensitive text
      (or, if you just don't feel like escaping quotes and apostrophes). The
      indentation level that begins the block is maintained throughout, so
      you can keep it all aligned with the body of your code.
    </p>
    <%= codeFor('heredocs', 'html') %>
    <p>
      Double-quoted block strings, like other double-quoted strings, allow interpolation.
    </p>
    <p>
      Sometimes you'd like to pass a block comment through to the generated
      JavaScript. For example, when you need to embed a licensing header at
      the top of a file. Block comments, which mirror the syntax for block strings,
      are preserved in the generated code.
    </p>
    <%= codeFor('block_comment') %>

    <p>
      <span id="regexes" class="bookmark"></span>
      <b class="header">Block Regular Expressions</b>
      Similar to block strings and comments, CoffeeScript supports block regexes &mdash;
      extended regular expressions that ignore internal whitespace and can contain
      comments and interpolation. Modeled after Perl's <code>/x</code> modifier, CoffeeScript's
      block regexes are delimited by <code>///</code> and go a long way towards making complex
      regular expressions readable. To quote from the CoffeeScript source:
    </p>
    <%= codeFor('heregexes') %>


    <h2>
      <span id="cake" class="bookmark"></span>
      Cake, and Cakefiles
    </h2>

    <p>
      CoffeeScript includes a (very) simple build system similar to
      <a href="http://www.gnu.org/software/make/">Make</a> and
      <a href="http://rake.rubyforge.org/">Rake</a>. Naturally,
      it's called Cake, and is used for the tasks that build and test the CoffeeScript
      language itself. Tasks are defined in a file named <code>Cakefile</code>, and
      can be invoked by running <code>cake [task]</code> from within the directory.
      To print a list of all the tasks and options, just type <code>cake</code>.
    </p>

    <p>
      Task definitions are written in CoffeeScript, so you can put arbitrary code
      in your Cakefile. Define a task with a name, a long description, and the
      function to invoke when the task is run. If your task takes a command-line
      option, you can define the option with short and long flags, and it will
      be made available in the <code>options</code> object. Here's a task that uses
      the Node.js API to rebuild CoffeeScript's parser:
    </p>
    <%= codeFor('cake_tasks') %>
    <p>
      If you need to invoke one task before another &mdash; for example, running
      <code>build</code> before <code>test</code>, you can use the <code>invoke</code> function:
      <code>invoke 'build'</code>. Cake tasks are a minimal way to expose your
      CoffeeScript functions to the command line, so
      <a href="documentation/docs/cake.html">don't expect any fanciness built-in</a>.
      If you need dependencies, or async callbacks, it's best to put them in your
      code itself &mdash; not the cake task.
    </p>

    <h2>
      <span id="source-maps" class="bookmark"></span>
      Source Maps
    </h2>

    <p>
      CoffeeScript 1.6.1 and above include support for generating source maps,
      a way to tell your JavaScript engine what part of your CoffeeScript
      program matches up with the code being evaluated. Browsers that support it
      can automatically use source maps to show your original source code
      in the debugger. To generate source maps alongside your JavaScript files,
      pass the <code>--map</code> or <code>-m</code> flag to the compiler.
    </p>

    <p>
      For a full introduction to source maps, how they work, and how to hook
      them up in your browser, read the
      <a href="http://www.html5rocks.com/en/tutorials/developertools/sourcemaps/">HTML5 Tutorial</a>.
    </p>

    <h2>
      <span id="scripts" class="bookmark"></span>
      "text/coffeescript" Script Tags
    </h2>

    <p>
      While it's not recommended for serious use, CoffeeScripts may be included
      directly within the browser using <code>&lt;script type="text/coffeescript"&gt;</code>
      tags. The source includes a compressed and minified version of the compiler
      (<a href="extras/coffee-script.js">Download current version here, 39k when gzipped</a>)
      as <code>extras/coffee-script.js</code>. Include this file on a page with
      inline CoffeeScript tags, and it will compile and evaluate them in order.
    </p>

    <p>
      In fact, the little bit of glue script that runs "Try CoffeeScript" above,
      as well as the jQuery for the menu, is implemented in just this way.
      View source and look at the bottom of the page to see the example.
      Including the script also gives you access to <code>CoffeeScript.compile()</code>
      so you can pop open Firebug and try compiling some strings.
    </p>

    <p>
      The usual caveats about CoffeeScript apply &mdash; your inline scripts will
      run within a closure wrapper, so if you want to expose global variables or
      functions, attach them to the <code>window</code> object.
    </p>

    <h2>
      <span id="resources" class="bookmark"></span>
      Books
    </h2>

    <p>
      There are a number of excellent resources to help you get
      started with CoffeeScript, some of which are freely available online.
    </p>

    <ul>
      <li>
        <a href="http://arcturo.github.com/library/coffeescript/">The Little Book on CoffeeScript</a>
        is a brief 5-chapter introduction to CoffeeScript, written with great
        clarity and precision by
        <a href="http://alexmaccaw.co.uk/">Alex MacCaw</a>.
      </li>
      <li>
        <a href="http://autotelicum.github.com/Smooth-CoffeeScript/">Smooth CoffeeScript</a>
        is a reimagination of the excellent book
        <a href="http://eloquentjavascript.net/">Eloquent JavaScript</a>, as if
        it had been written in CoffeeScript instead. Covers language features
        as well as the functional and object oriented programming styles. By
        <a href="https://github.com/autotelicum">E. Hoigaard</a>.
      </li>
      <li>
        <a href="http://pragprog.com/book/tbcoffee/coffeescript">CoffeeScript: Accelerated JavaScript Development</a>
        is <a href="http://trevorburnham.com/">Trevor Burnham</a>'s thorough
        introduction to the language. By the end of the book, you'll have built
        a fast-paced multiplayer word game, writing both the client-side and Node.js
        portions in CoffeeScript.
      </li>
      <li>
        <a href="http://www.packtpub.com/coffeescript-programming-with-jquery-rails-nodejs/book">CoffeeScript Programming with jQuery, Rails, and Node.js</a>
        is a new book by Michael Erasmus that covers CoffeeScript with an eye
        towards real-world usage both in the browser (jQuery) and on the server
        size (Rails, Node).
      </li>
      <li>
        <a href="https://leanpub.com/coffeescript-ristretto/read">CoffeeScript Ristretto</a>
        is a deep dive into CoffeeScript's semantics from simple functions up through
        closures, higher-order functions, objects, classes, combinators, and decorators.
        By <a href="http://braythwayt.com/">Reg Braithwaite</a>.
      </li>
      <li>
        <a href="https://efendibooks.com/minibooks/testing-with-coffeescript">Testing with CoffeeScript</a>
        is a succinct and freely downloadable guide to building testable
        applications with CoffeeScript and Jasmine.
      </li>
      <li>
        <a href="http://www.packtpub.com/coffeescript-application-development/book">CoffeeScript Application Development</a>
        from Packt, introduces CoffeeScript while
        walking through the process of building a demonstration web application.
        A <a href="https://www.packtpub.com/web-development/coffeescript-application-development-cookbook">CoffeeScript Application Development Coookbook</a>
        with over 90 "recipes" is also available.
      </li>
      <li>
        <a href="http://www.manning.com/lee/">CoffeeScript in Action</a>
        from Manning Publications, covers CoffeeScript syntax, composition techniques
        and application development.
      </li>
      <li>
        <a href="http://www.dpunkt.de/buecher/4021/coffeescript.html">CoffeeScript: Die Alternative zu JavaScript</a>
        from dpunkt.verlag, is the first CoffeeScript book in Deutsch.
      </li>
    </ul>

    <h2>
      Screencasts
    </h2>

    <ul>
      <li>
        <a href="http://coffeescript.codeschool.com">A Sip of CoffeeScript</a> is a <a href="http://www.codeschool.com">Code School Course</a>
        which combines 6 screencasts with in-browser coding to make learning fun.  The first level is free to try out.
      </li>
      <li>
        <a href="http://peepcode.com/products/coffeescript">Meet CoffeeScript</a>
        is a 75-minute long screencast by <a href="http://peepcode.com/">PeepCode</a>.
        Highly memorable for its animations which demonstrate transforming CoffeeScript
        into the equivalent JS.
      </li>
      <li>
        If you're looking for less of a time commitment, RailsCasts'
        <a href="http://railscasts.com/episodes/267-coffeescript-basics">CoffeeScript Basics</a>
        should have you covered, hitting all of the important notes about CoffeeScript
        in 11 minutes.
      </li>
    </ul>

    <h2>
      Examples
    </h2>

    <p>
      The <a href="https://github.com/trending?l=coffeescript&amp;since=monthly">best list of
      open-source CoffeeScript examples</a> can be found on GitHub. But just
      to throw out few more:
    </p>

    <ul>
      <li>
        <b>github</b>'s <a href="http://hubot.github.com/">Hubot</a>,
        a friendly IRC robot that can perform any number of useful and useless tasks.
      </li>
      <li>
        <b>sstephenson</b>'s <a href="http://pow.cx/">Pow</a>,
        a zero-configuration Rack server, with comprehensive annotated source.
      </li>
      <li>
        <b>technoweenie</b>'s <a href="https://github.com/technoweenie/coffee-resque">Coffee-Resque</a>,
        a port of <a href="https://github.com/defunkt/resque">Resque</a> for Node.js.
      </li>
      <li>
        <b>assaf</b>'s <a href="http://zombie.labnotes.org/">Zombie.js</a>,
        a headless, full-stack, faux-browser testing library for Node.js.
      </li>
      <li>
        <b>jashkenas</b>' <a href="documentation/docs/underscore.html">Underscore.coffee</a>, a port
        of the <a href="http://documentcloud.github.com/underscore/">Underscore.js</a>
        library of helper functions.
      </li>
      <li>
        <b>stephank</b>'s <a href="https://github.com/stephank/orona">Orona</a>, a remake of
        the Bolo tank game for modern browsers.
      </li>
      <li>
        <b>github</b>'s <a href="https://atom.io/">Atom</a>,
        a hackable text editor built on web technologies.
      </li>
    </ul>

    <h2>
      Resources
    </h2>

    <ul>
      <li>
        <a href="http://github.com/jashkenas/coffeescript/">Source Code</a><br />
        Use <code>bin/coffee</code> to test your changes,<br />
        <code>bin/cake test</code> to run the test suite,<br />
        <code>bin/cake build</code> to rebuild the CoffeeScript compiler, and <br />
        <code>bin/cake build:parser</code> to regenerate the Jison parser if you're
        working on the grammar. <br /><br />
        <code>git checkout lib &amp;&amp; bin/cake build:full</code> is a good command to run when you're working
        on the core language. It'll refresh the lib directory
        (in case you broke something), build your altered compiler, use that to
        rebuild itself (a good sanity test) and then run all of the tests. If
        they pass, there's a good chance you've made a successful change.
      </li>
      <li>
        <a href="http://github.com/jashkenas/coffeescript/issues">CoffeeScript Issues</a><br />
        Bug reports, feature proposals, and ideas for changes to the language belong here.
      </li>
      <li>
        <a href="https://groups.google.com/forum/#!forum/coffeescript">CoffeeScript Google Group</a><br />
        If you'd like to ask a question, the mailing list is a good place to get help.
      </li>
      <li>
        <a href="http://github.com/jashkenas/coffeescript/wiki">The CoffeeScript Wiki</a><br />
        If you've ever learned a neat CoffeeScript tip or trick, or ran into a gotcha &mdash; share it on the wiki.
        The wiki also serves as a directory of handy
        <a href="http://github.com/jashkenas/coffeescript/wiki/Text-editor-plugins">text editor extensions</a>,
        <a href="http://github.com/jashkenas/coffeescript/wiki/Web-framework-plugins">web framework plugins</a>,
        and general <a href="http://github.com/jashkenas/coffeescript/wiki/Build-tools">CoffeeScript build tools</a>.
      </li>
      <li>
        <a href="http://github.com/jashkenas/coffeescript/wiki/FAQ">The FAQ</a><br />
        Perhaps your CoffeeScript-related question has been asked before. Check the FAQ first.
      </li>
      <li>
        <a href="http://js2coffee.org">JS2Coffee</a><br />
        Is a very well done reverse JavaScript-to-CoffeeScript compiler. It's
        not going to be perfect (infer what your JavaScript classes are, when
        you need bound functions, and so on...) &mdash; but it's a great starting
        point for converting simple scripts.
      </li>
      <li>
        <a href="https://github.com/jashkenas/coffeescript/downloads">High-Rez Logo</a><br />
        The CoffeeScript logo is available in Illustrator, EPS and PSD formats, for use
        in presentations.
      </li>
    </ul>

    <h2>
      <span id="webchat" class="bookmark"></span>
      Web Chat (IRC)
    </h2>

    <p>
      Quick help and advice can usually be found in the CoffeeScript IRC room.
      Join <code>#coffeescript</code> on <code>irc.freenode.net</code>, or click the
      button below to open a webchat session on this page.
    </p>

    <p>
      <button id="open_webchat">click to open #coffeescript</button>
    </p>

    <h2>
      <span id="changelog" class="bookmark"></span>
      Change Log
    </h2>

    <p>
      <%= releaseHeader('2015-09-04', '1.10.0', '1.9.3') %>
      <ul>
        <li>
          CoffeeScript now supports ES6-style destructuring defaults.
        </li>
        <li>
          <code>(offsetHeight: height) -&gt;</code> no longer compiles. That
          syntax was accidental and partly broken. Use <code>({offsetHeight:
          height}) -&gt;</code> instead. Object destructuring always requires
          braces.
        </li>
        <li>
          <p>Several minor bug fixes, including:</p>
          <ul>
            <li>
              A bug where the REPL would sometimes report valid code as invalid,
              based on what you had typed earlier.
            </li>
            <li>
              A problem with multiple JS contexts in the jest test framework.
            </li>
            <li>
              An error in io.js where strict mode is set on internal modules.
            </li>
            <li>
              A variable name clash for the caught error in <code>catch</code>
              blocks.
            </li>
          </ul>
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2015-05-27', '1.9.3', '1.9.2') %>
      <ul>
        <li>
          Bugfix for interpolation in the first key of an object literal in an
          implicit call.
        </li>
        <li>
          Fixed broken error messages in the REPL, as well as a few minor bugs
          with the REPL.
        </li>
        <li>
          Fixed source mappings for tokens at the beginning of lines when
          compiling with the <code>--bare</code> option. This has the nice side
          effect of generating smaller source maps.
        </li>
        <li>
          Slight formatting improvement of compiled block comments.
        </li>
        <li>
          Better error messages for <code>on</code>, <code>off</code>, <code>yes</code> and
          <code>no</code>.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2015-04-15', '1.9.2', '1.9.1') %>
      <ul>
        <li>
          Fixed a <b>watch</b> mode error introduced in 1.9.1 when compiling
          multiple files with the same filename.
        </li>
        <li>
          Bugfix for <code>yield</code> around expressions containing
          <code>this</code>.
        </li>
        <li>
          Added a Ruby-style <code>-r</code> option to the REPL, which allows
          requiring a module before execution with <code>--eval</code> or
          <code>--interactive</code>.
        </li>
        <li>
          In <code>&lt;script type="text/coffeescript"&gt;</code> tags, to avoid
          possible duplicate browser requests for .coffee files, 
          you can now use the <code>data-src</code> attribute instead of <code>src</code>.
        </li>
        <li>
          Minor bug fixes for IE8, strict ES5 regular expressions and Browserify.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2015-02-18', '1.9.1', '1.9.0') %>
      <ul>
        <li>
          Interpolation now works in object literal keys (again). You can use this to
          dynamically name properties.
        </li>
        <li>
          Internal compiler variable names no longer start with underscores. This makes
          the generated JavaScript a bit prettier, and also fixes an issue with
          the completely broken and ungodly way that AngularJS "parses" function
          arguments.
        </li>
        <li>
          Fixed a few <code>yield</code>-related edge cases with <code>yield return</code>
          and <code>yield throw</code>.
        </li>
        <li>
          Minor bug fixes and various improvements to compiler error messages.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2015-01-29', '1.9.0', '1.8.0') %>
      <ul>
        <li>
          CoffeeScript now supports ES6 generators. A generator is simply a function
          that <code>yield</code>s.
        </li>
        <li>
          More robust parsing and improved error messages for strings and regexes —
          especially with respect to interpolation.
        </li>
        <li>
          Changed strategy for the generation of internal compiler variable names.
          Note that this means that <code>@example</code> function parameters are no longer
          available as naked <code>example</code> variables within the function body.
        </li>
        <li>
          Fixed REPL compatibility with latest versions of Node and Io.js.
        </li>
        <li>
          Various minor bug fixes.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2014-08-26', '1.8.0', '1.7.1') %>
      <ul>
        <li>
          The <code>--join</code> option of the CLI is now deprecated.
        </li>
        <li>
          Source maps now use <code>.js.map</code> as file extension, instead of just <code>.map</code>.
        </li>
        <li>
          The CLI now exits with the exit code 1 when it fails to write a file to disk.
        </li>
        <li>
          The compiler no longer crashes on unterminated, single-quoted strings.
        </li>
        <li>
          Fixed location data for string interpolations, which made source maps out of sync.
        </li>
        <li>
          The error marker in error messages is now correctly positioned if the code is indented with tabs.
        </li>
        <li>
          Fixed a slight formatting error in CoffeeScript’s source map-patched stack traces.
        </li>
        <li>
          The <code>%%</code> operator now coerces its right operand only once.
        </li>
        <li>
          It is now possible to require CoffeeScript files from Cakefiles without having to register the compiler first.
        </li>
        <li>
          The CoffeeScript REPL is now exported and can be required using <code>require 'coffee-script/repl'</code>.
        </li>
        <li>
          Fixes for the REPL in Node 0.11.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2014-01-29', '1.7.1', '1.7.0') %>
      <ul>
        <li>
          Fixed a typo that broke node module lookup when running a script directly with the <code>coffee</code> binary.
        </li>
      </ul>
    </p>
    <p>
      <%= releaseHeader('2014-01-28', '1.7.0', '1.6.3') %>
      <ul>
        <li>
          When requiring CoffeeScript files in Node you must now explicitly register the compiler. This can be done with <code>require 'coffee-script/register'</code> or <code>CoffeeScript.register()</code>. Also for configuration such as Mocha's, use <b>coffee-script/register</b>.
        </li>
        <li>
          Improved error messages, source maps and stack traces. Source maps now use the updated <code>//#</code> syntax.
        </li>
        <li>
          Leading <code>.</code> now closes all open calls, allowing for simpler chaining syntax.
        </li>
      </ul>
      <%= codeFor('chaining') %>
      <ul>
        <li>
          Added <code>**</code>, <code>//</code> and <code>%%</code> operators and <code>...</code> expansion in parameter lists and destructuring expressions.
        </li>
        <li>
          Multiline strings are now joined by a single space and ignore all indentation. A backslash at the end of a line can denote the amount of whitespace between lines, in both strings and heredocs. Backslashes correctly escape whitespace in block regexes.
        </li>
        <li>
          Closing brackets can now be indented and therefore no longer cause unexpected error.
        </li>
        <li>
          Several breaking compilation fixes. Non-callable literals (strings, numbers etc.) don't compile in a call now and multiple postfix conditionals compile properly. Postfix conditionals and loops always bind object literals. Conditional assignment compiles properly in subexpressions. <code>super</code> is disallowed outside of methods and works correctly inside <code>for</code> loops.
        </li>
        <li>
          Formatting of compiled block comments has been improved.
        </li>
        <li>
          No more <code>-p</code> folders on Windows.
        </li>
        <li>
          The <code>options</code> object passed to CoffeeScript is no longer mutated.
        </li>
      </ul>
    </p>
    <p>
      <%= releaseHeader('2013-06-02', '1.6.3', '1.6.2') %>
      <ul>
        <li>
          The CoffeeScript REPL now remembers your history between sessions.
          Just like a proper REPL should.
        </li>
        <li>
          You can now use <code>require</code> in Node to load <code>.coffee.md</code>
          Literate CoffeeScript files. In the browser,
          <code>text/literate-coffeescript</code> script tags.
        </li>
        <li>
          The old <code>coffee --lint</code> command has been removed. It was useful
          while originally working on the compiler, but has been surpassed by
          JSHint. You may now use <code>-l</code> to pass literate files in over
          <b>stdio</b>.
        </li>
        <li>
          Bugfixes for Windows path separators, <code>catch</code> without naming
          the error, and executable-class-bodies-with-
          prototypal-property-attachment.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2013-03-18', '1.6.2', '1.6.1') %>
      <ul>
        <li>
          Source maps have been used to provide automatic line-mapping when
          running CoffeeScript directly via the <code>coffee</code> command, and
          for automatic line-mapping when running CoffeeScript directly in the
          browser. Also, to provide better error messages for semantic errors
          thrown by the compiler &mdash;
          <a href="http://cl.ly/NdOA">with colors, even</a>.
        </li>
        <li>
          Improved support for mixed literate/vanilla-style CoffeeScript projects,
          and generating source maps for both at the same time.
        </li>
        <li>
          Fixes for <b>1.6.x</b> regressions with overriding inherited bound
          functions, and for Windows file path management.
        </li>
        <li>
          The <code>coffee</code> command can now correctly <code>fork()</code>
          both <code>.coffee</code> and <code>.js</code> files. (Requires Node.js 0.9+)
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2013-03-05', '1.6.1', '1.5.0') %>
      <ul>
        <li>
          First release of <a href="#source-maps">source maps</a>. Pass the
          <code>--map</code> flag to the compiler, and off you go. Direct all your
          thanks over to <a href="http://github.com/jwalton">Jason Walton</a>.
        </li>
        <li>
          Fixed a 1.5.0 regression with multiple implicit calls against an
          indented implicit object. Combinations of implicit function calls
          and implicit objects should generally be parsed better now &mdash;
          but it still isn't good <i>style</i> to nest them too heavily.
        </li>
        <li>
          <code>.coffee.md</code> is now also supported as a Literate CoffeeScript
          file extension, for existing tooling.
          <code>.litcoffee</code> remains the canonical one.
        </li>
        <li>
          Several minor fixes surrounding member properties, bound methods and
          <code>super</code> in class declarations.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2013-02-25', '1.5.0', '1.4.0') %>
      <ul>
        <li>
          First release of <a href="#literate">Literate CoffeeScript</a>.
        </li>
        <li>
          The CoffeeScript REPL is now based on the Node.js REPL, and should work
          better and more familiarly.
        </li>
        <li>
          Returning explicit values from constructors is now forbidden. If you want
          to return an arbitrary value, use a function, not a constructor.
        </li>
        <li>
          You can now loop over an array backwards, without having to manually
          deal with the indexes: <code>for item in list by -1</code>
        </li>
        <li>
          Source locations are now preserved in the CoffeeScript AST, although
          source maps are not yet being emitted.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2012-10-23', '1.4.0', '1.3.3') %>
      <ul>
        <li>
          The CoffeeScript compiler now strips Microsoft's UTF-8 BOM if it
          exists, allowing you to compile BOM-borked source files.
        </li>
        <li>
          Fix Node/compiler deprecation warnings by removing <code>registerExtension</code>,
          and moving from <code>path.exists</code> to <code>fs.exists</code>.
        </li>
        <li>
          Small tweaks to splat compilation, backticks, slicing, and the
          error for duplicate keys in object literals.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2012-05-15', '1.3.3', '1.3.1') %>
      <ul>
        <li>
          Due to the new semantics of JavaScript's strict mode, CoffeeScript no
          longer guarantees that constructor functions have names in all runtimes.
          See <a href="https://github.com/jashkenas/coffeescript/issues/2052">#2052</a>
          for discussion.
        </li>
        <li>
          Inside of a nested function inside of an instance method, it's now possible
          to call <code>super</code> more reliably (walks recursively up).
        </li>
        <li>
          Named loop variables no longer have different scoping heuristics than
          other local variables. (Reverts #643)
        </li>
        <li>
          Fix for splats nested within the LHS of destructuring assignment.
        </li>
        <li>
          Corrections to our compile time strict mode forbidding of octal literals.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2012-04-10', '1.3.1', '1.2.0') %>
      <ul>
        <li>
          CoffeeScript now enforces all of JavaScript's <b>Strict Mode</b> early syntax
          errors at compile time. This includes old-style octal literals,
          duplicate property names in object literals, duplicate parameters in
          a function definition, deleting naked variables, setting the value of
          <code>eval</code> or <code>arguments</code>, and more.
          See a full discussion at
          <a href="https://github.com/jashkenas/coffeescript/issues/1547">#1547</a>.
        </li>
        <li>
          The REPL now has a handy new multi-line mode for entering large
          blocks of code. It's useful when copy-and-pasting examples into the
          REPL. Enter multi-line mode with <code>Ctrl-V</code>. You may also now
          pipe input directly into the REPL.
        </li>
        <li>
          CoffeeScript now prints a <code>Generated by CoffeeScript VERSION</code>
          header at the top of each compiled file.
        </li>
        <li>
          Conditional assignment of previously undefined variables
          <code>a or= b</code> is now considered a syntax error.
        </li>
        <li>
          A tweak to the semantics of <code>do</code>, which can now be used to
          more easily simulate a namespace: <code>do (x = 1, y = 2) -> ...</code>
        </li>
        <li>
          Loop indices are now mutable within a loop iteration, and immutable
          between them.
        </li>
        <li>
          Both endpoints of a slice are now allowed to be omitted for consistency,
          effectively creating a shallow copy of the list.
        </li>
        <li>
          Additional tweaks and improvements to <code>coffee --watch</code> under
          Node's "new" file watching API. Watch will now beep by default
          if you introduce a syntax error into a watched script. We also now
          ignore hidden directories by default when watching recursively.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2011-12-18', '1.2.0', '1.1.3') %>
      <ul>
        <li>
          Multiple improvements to <code>coffee --watch</code> and <code>--join</code>.
          You may now use both together, as well as add and remove
          files and directories within a <code>--watch</code>'d folder.
        </li>
        <li>
          The <code>throw</code> statement can now be used as part of an expression.
        </li>
        <li>
          Block comments at the top of the file will now appear outside of the
          safety closure wrapper.
        </li>
        <li>
          Fixed a number of minor 1.1.3 regressions having to do with trailing
          operators and unfinished lines, and a more major 1.1.3 regression that
          caused bound functions <i>within</i> bound class functions to have the incorrect
          <code>this</code>.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2011-11-08', '1.1.3', '1.1.2') %>
      <ul>
        <li>
          Ahh, whitespace. CoffeeScript's compiled JS now tries to space things
          out and keep it readable, as you can see in the examples on this page.
        </li>
        <li>
          You can now call <code>super</code> in class level methods in class bodies,
          and bound class methods now preserve their correct context.
        </li>
        <li>
          JavaScript has always supported octal numbers <code>010 is 8</code>,
          and hexadecimal numbers <code>0xf is 15</code>, but CoffeeScript now
          also supports binary numbers: <code>0b10 is 2</code>.
        </li>
        <li>
          The CoffeeScript module has been nested under a subdirectory to make
          it easier to <code>require</code> individual components separately, without
          having to use <b>npm</b>. For example, after adding the CoffeeScript
          folder to your path: <code>require('coffee-script/lexer')</code>
        </li>
        <li>
          There's a new "link" feature in Try CoffeeScript on this webpage. Use
          it to get a shareable permalink for your example script.
        </li>
        <li>
          The <code>coffee --watch</code> feature now only works on Node.js 0.6.0
          and higher, but now also works properly on Windows.
        </li>
        <li>
          Lots of small bug fixes from
          <b><a href="https://github.com/michaelficarra">@michaelficarra</a></b>,
          <b><a href="https://github.com/geraldalewis">@geraldalewis</a></b>,
          <b><a href="https://github.com/satyr">@satyr</a></b>, and
          <b><a href="https://github.com/trevorburnham">@trevorburnham</a></b>.
        </li>
      </ul>
    </p>

    <p>
      <%= releaseHeader('2011-08-04', '1.1.2', '1.1.1') %>
      Fixes for block comment formatting, <code>?=</code> compilation, implicit calls
      against control structures, implicit invocation of a try/catch block,
      variadic arguments leaking from local scope, line numbers in syntax errors
      following heregexes, property access on parenthesized number literals,
      bound class methods and super with reserved names, a REPL overhaul,
      consecutive compiled semicolons, block comments in implicitly called objects,
      and a Chrome bug.
    </p>

    <p>
      <%= releaseHeader('2011-05-10', '1.1.1', '1.1.0') %>
      Bugfix release for classes with external constructor functions, see
      issue #1182.
    </p>

    <p>
      <%= releaseHeader('2011-05-01', '1.1.0', '1.0.1') %>
      When running via the <code>coffee</code> executable, <code>process.argv</code> and
      friends now report <code>coffee</code> instead of <code>node</code>.
      Better compatibility with <b>Node.js 0.4.x</b> module lookup changes.
      The output in the REPL is now colorized, like Node's is.
      Giving your concatenated CoffeeScripts a name when using <code>--join</code> is now mandatory.
      Fix for lexing compound division <code>/=</code> as a regex accidentally.
      All <code>text/coffeescript</code> tags should now execute in the order they're included.
      Fixed an issue with extended subclasses using external constructor functions.
      Fixed an edge-case infinite loop in <code>addImplicitParentheses</code>.
      Fixed exponential slowdown with long chains of function calls.
      Globals no longer leak into the CoffeeScript REPL.
      Splatted parameters are declared local to the function.
    </p>

    <p>
      <%= releaseHeader('2011-01-31', '1.0.1', '1.0.0') %>
      Fixed a lexer bug with Unicode identifiers. Updated REPL for compatibility
      with Node.js 0.3.7. Fixed requiring relative paths in the REPL. Trailing
      <code>return</code> and <code>return undefined</code> are now optimized away.
      Stopped requiring the core Node.js <code>"util"</code> module for
      back-compatibility with Node.js 0.2.5. Fixed a case where a
      conditional <code>return</code> would cause fallthrough in a <code>switch</code>
      statement. Optimized empty objects in destructuring assignment.
    </p>

    <p>
      <%= releaseHeader('2010-12-24', '1.0.0', '0.9.6') %>
      CoffeeScript loops no longer try to preserve block scope when functions
      are being generated within the loop body. Instead, you can use the
      <code>do</code> keyword to create a convenient closure wrapper.
      Added a <code>--nodejs</code> flag for passing through options directly
      to the <code>node</code> executable.
      Better behavior around the use of pure statements within expressions.
      Fixed inclusive slicing through <code>-1</code>, for all browsers, and splicing
      with arbitrary expressions as endpoints.
    </p>

    <p>
      <%= releaseHeader('2010-12-06', '0.9.6', '0.9.5') %>
      The REPL now properly formats stacktraces, and stays alive through
      asynchronous exceptions. Using <code>--watch</code> now prints timestamps as
      files are compiled. Fixed some accidentally-leaking variables within
      plucked closure-loops. Constructors now maintain their declaration
      location within a class body. Dynamic object keys were removed.
      Nested classes are now supported. Fixes execution context for naked
      splatted functions. Bugfix for inversion of chained comparisons.
      Chained class instantiation now works properly with splats.
    </p>

    <p>
      <%= releaseHeader('2010-11-21', '0.9.5', '0.9.4') %>
      0.9.5 should be considered the first release candidate for CoffeeScript 1.0.
      There have been a large number of internal changes since the previous release,
      many contributed from <b>satyr</b>'s <a href="http://github.com/satyr/coco">Coco</a>
      dialect of CoffeeScript. Heregexes (extended regexes) were added. Functions
      can now have default arguments. Class bodies are now executable code.
      Improved syntax errors for invalid CoffeeScript. <code>undefined</code> now
      works like <code>null</code>, and cannot be assigned a new value.
      There was a precedence change with respect to single-line comprehensions:
      <code>result = i for i in list</code><br /> used to parse as <code>result = (i for i in list)</code>
      by default ... it now parses as <br /><code>(result = i) for i in list</code>.
    </p>

    <p>
      <%= releaseHeader('2010-09-21', '0.9.4', '0.9.3') %>
      CoffeeScript now uses appropriately-named temporary variables, and recycles
      their references after use. Added <code>require.extensions</code> support for
      <b>Node.js 0.3</b>. Loading CoffeeScript in the browser now adds just a
      single <code>CoffeeScript</code> object to global scope.
      Fixes for implicit object and block comment edge cases.
    </p>

    <p>
      <%= releaseHeader('2010-09-16', '0.9.3', '0.9.2') %>
      CoffeeScript <code>switch</code> statements now compile into JS <code>switch</code>
      statements &mdash; they previously compiled into <code>if/else</code> chains
      for JavaScript 1.3 compatibility.
      Soaking a function invocation is now supported. Users of the RubyMine
      editor should now be able to use <code>--watch</code> mode.
    </p>

    <p>
      <%= releaseHeader('2010-08-23', '0.9.2', '0.9.1') %>
      Specifying the start and end of a range literal is now optional, eg. <code>array[3..]</code>.
      You can now say <code>a not instanceof b</code>.
      Fixed important bugs with nested significant and non-significant indentation (Issue #637).
      Added a <code>--require</code> flag that allows you to hook into the <code>coffee</code> command.
      Added a custom <code>jsl.conf</code> file for our preferred JavaScriptLint setup.
      Sped up Jison grammar compilation time by flattening rules for operations.
      Block comments can now be used with JavaScript-minifier-friendly syntax.
      Added JavaScript's compound assignment bitwise operators. Bugfixes to
      implicit object literals with leading number and string keys, as the subject
      of implicit calls, and as part of compound assignment.
    </p>

    <p>
      <%= releaseHeader('2010-08-11', '0.9.1', '0.9.0') %>
      Bugfix release for <b>0.9.1</b>. Greatly improves the handling of mixed
      implicit objects, implicit function calls, and implicit indentation.
      String and regex interpolation is now strictly <code>#{ ... }</code> (Ruby style).
      The compiler now takes a <code>--require</code> flag, which specifies scripts
      to run before compilation.
    </p>

    <p>
      <%= releaseHeader('2010-08-04', '0.9.0', '0.7.2') %>
      The CoffeeScript <b>0.9</b> series is considered to be a release candidate
      for <b>1.0</b>; let's give her a shakedown cruise. <b>0.9.0</b> introduces a massive
      backwards-incompatible change: Assignment now uses <code>=</code>, and object
      literals use <code>:</code>, as in JavaScript. This allows us to have implicit
      object literals, and YAML-style object definitions. Half assignments are
      removed, in favor of <code>+=</code>, <code>or=</code>, and friends.
      Interpolation now uses a hash mark <code>#</code> instead of the dollar sign
      <code>$</code> &mdash; because dollar signs may be part of a valid JS identifier.
      Downwards range comprehensions are now safe again, and are optimized to
      straight for loops when created with integer endpoints.
      A fast, unguarded form of object comprehension was added:
      <code>for all key, value of object</code>. Mentioning the <code>super</code> keyword
      with no arguments now forwards all arguments passed to the function,
      as in Ruby. If you extend class <code>B</code> from parent class <code>A</code>, if
      <code>A</code> has an <code>extended</code> method defined, it will be called, passing in <code>B</code> &mdash;
      this enables static inheritance, among other things. Cleaner output for
      functions bound with the fat arrow. <code>@variables</code> can now be used
      in parameter lists, with the parameter being automatically set as a property
      on the object &mdash; useful in constructors and setter functions.
      Constructor functions can now take splats.
    </p>

    <p>
      <%= releaseHeader('2010-07-12', '0.7.2', '0.7.1') %>
      Quick bugfix (right after 0.7.1) for a problem that prevented <code>coffee</code>
      command-line options from being parsed in some circumstances.
    </p>

    <p>
      <%= releaseHeader('2010-07-11', '0.7.1', '0.7.0') %>
      Block-style comments are now passed through and printed as JavaScript block
      comments -- making them useful for licenses and copyright headers. Better
      support for running coffee scripts standalone via hashbangs.
      Improved syntax errors for tokens that are not in the grammar.
    </p>

    <p>
      <%= releaseHeader('2010-06-28', '0.7.0', '0.6.2') %>
      Official CoffeeScript variable style is now camelCase, as in JavaScript.
      Reserved words are now allowed as object keys, and will be quoted for you.
      Range comprehensions now generate cleaner code, but you have to specify <code>by -1</code>
      if you'd like to iterate downward. Reporting of syntax errors is greatly
      improved from the previous release. Running <code>coffee</code> with no arguments
      now launches the REPL, with Readline support. The <code>&lt;-</code> bind operator
      has been removed from CoffeeScript. The <code>loop</code> keyword was added,
      which is equivalent to a <code>while true</code> loop. Comprehensions that contain
      closures will now close over their variables, like the semantics of a <code>forEach</code>.
      You can now use bound function in class definitions (bound to the instance).
      For consistency, <code>a in b</code> is now an array presence check, and <code>a of b</code>
      is an object-key check. Comments are no longer passed through to the generated
      JavaScript.
    </p>

    <p>
      <%= releaseHeader('2010-05-15', '0.6.2', '0.6.1') %>
      The <code>coffee</code> command will now preserve directory structure when
      compiling a directory full of scripts. Fixed two omissions that were preventing
      the CoffeeScript compiler from running live within Internet Explorer.
      There's now a syntax for block comments, similar in spirit to CoffeeScript's heredocs.
      ECMA Harmony DRY-style pattern matching is now supported, where the name
      of the property is the same as the name of the value: <code>{name, length}: func</code>.
      Pattern matching is now allowed within comprehension variables. <code>unless</code>
      is now allowed in block form. <code>until</code> loops were added, as the inverse
      of <code>while</code> loops. <code>switch</code> statements are now allowed without
      switch object clauses. Compatible
      with Node.js <b>v0.1.95</b>.
    </p>

    <p>
      <%= releaseHeader('2010-04-12', '0.6.1', '0.6.0') %>
      Upgraded CoffeeScript for compatibility with the new Node.js <b>v0.1.90</b>
      series.
    </p>

    <p>
      <%= releaseHeader('2010-04-03', '0.6.0', '0.5.6') %>
      Trailing commas are now allowed, a-la Python. Static
      properties may be assigned directly within class definitions,
      using <code>@property</code> notation.
    </p>

    <p>
      <%= releaseHeader('2010-03-23', '0.5.6', '0.5.5') %>
      Interpolation can now be used within regular expressions and heredocs, as well as
      strings. Added the <code>&lt;-</code> bind operator.
      Allowing assignment to half-expressions instead of special <code>||=</code>-style
      operators. The arguments object is no longer automatically converted into
      an array. After requiring <code>coffee-script</code>, Node.js can now directly
      load <code>.coffee</code> files, thanks to <b>registerExtension</b>. Multiple
      splats can now be used in function calls, arrays, and pattern matching.
    </p>

    <p>
      <%= releaseHeader('2010-03-08', '0.5.5', '0.5.4') %>
      String interpolation, contributed by
      <a href="http://github.com/StanAngeloff">Stan Angeloff</a>.
      Since <code>--run</code> has been the default since <b>0.5.3</b>, updating
      <code>--stdio</code> and <code>--eval</code> to run by default, pass <code>--compile</code>
      as well if you'd like to print the result.
    </p>

    <p>
      <%= releaseHeader('2010-03-03', '0.5.4', '0.5.3') %>
      Bugfix that corrects the Node.js global constants <code>__filename</code> and
      <code>__dirname</code>. Tweaks for more flexible parsing of nested function
      literals and improperly-indented comments. Updates for the latest Node.js API.
    </p>

    <p>
      <%= releaseHeader('2010-02-27', '0.5.3', '0.5.2') %>
      CoffeeScript now has a syntax for defining classes. Many of the core
      components (Nodes, Lexer, Rewriter, Scope, Optparse) are using them.
      Cakefiles can use <code>optparse.coffee</code> to define options for tasks.
      <code>--run</code> is now the default flag for the <code>coffee</code> command,
      use <code>--compile</code> to save JavaScripts. Bugfix for an ambiguity between
      RegExp literals and chained divisions.
    </p>

    <p>
      <%= releaseHeader('2010-02-25', '0.5.2', '0.5.1') %>
      Added a compressed version of the compiler for inclusion in web pages as
      <br  /><code>extras/coffee-script.js</code>. It'll automatically run any script tags
      with type <code>text/coffeescript</code> for you. Added a <code>--stdio</code> option
      to the <code>coffee</code> command, for piped-in compiles.
    </p>


    <p>
      <%= releaseHeader('2010-02-24', '0.5.1', '0.5.0') %>
      Improvements to null soaking with the existential operator, including
      soaks on indexed properties. Added conditions to <code>while</code> loops,
      so you can use them as filters with <code>when</code>, in the same manner as
      comprehensions.
    </p>

    <p>
      <%= releaseHeader('2010-02-21', '0.5.0', '0.3.2') %>
      CoffeeScript 0.5.0 is a major release, While there are no language changes,
      the Ruby compiler has been removed in favor of a self-hosting
      compiler written in pure CoffeeScript.
    </p>

    <p>
      <%= releaseHeader('2010-02-08', '0.3.2', '0.3.0') %>
      <code>@property</code> is now a shorthand for <code>this.property</code>.<br />
      Switched the default JavaScript engine from Narwhal to Node.js. Pass
      the <code>--narwhal</code> flag if you'd like to continue using it.
    </p>

    <p>
      <%= releaseHeader('2010-01-26', '0.3.0', '0.2.6') %>
      CoffeeScript 0.3 includes major syntax changes:
      <br />
      The function symbol was changed to
      <code>-></code>, and the bound function symbol is now <code>=></code>.
      <br />
      Parameter lists in function definitions must now be wrapped in parentheses.
      <br />
      Added property soaking, with the <code>?.</code> operator.
      <br />
      Made parentheses optional, when invoking functions with arguments.
      <br />
      Removed the obsolete block literal syntax.
    </p>

    <p>
      <%= releaseHeader('2010-01-17', '0.2.6', '0.2.5') %>
      Added Python-style chained comparisons, the conditional existence
      operator <code>?=</code>, and some examples from <i>Beautiful Code</i>.
      Bugfixes relating to statement-to-expression conversion, arguments-to-array
      conversion, and the TextMate syntax highlighter.
    </p>

    <p>
      <%= releaseHeader('2010-01-13', '0.2.5', '0.2.4') %>
      The conditions in switch statements can now take multiple values at once &mdash;
      If any of them are true, the case will run. Added the long arrow <code>==></code>,
      which defines and immediately binds a function to <code>this</code>. While loops can
      now be used as expressions, in the same way that comprehensions can. Splats
      can be used within pattern matches to soak up the rest of an array.
    </p>

    <p>
      <%= releaseHeader('2010-01-12', '0.2.4', '0.2.3') %>
      Added ECMAScript Harmony style destructuring assignment, for dealing with
      extracting values from nested arrays and objects. Added indentation-sensitive
      heredocs for nicely formatted strings or chunks of code.
    </p>

    <p>
      <%= releaseHeader('2010-01-11', '0.2.3', '0.2.2') %>
      Axed the unsatisfactory <code>ino</code> keyword, replacing it with <code>of</code> for
      object comprehensions. They now look like: <code>for prop, value of object</code>.
    </p>

    <p>
      <%= releaseHeader('2010-01-10', '0.2.2', '0.2.1') %>
      When performing a comprehension over an object, use <code>ino</code>, instead
      of <code>in</code>, which helps us generate smaller, more efficient code at
      compile time.
      <br />
      Added <code>::</code> as a shorthand for saying <code>.prototype.</code>
      <br />
      The "splat" symbol has been changed from a prefix asterisk <code>*</code>, to
      a postfix ellipsis <code>...</code>
      <br />
      Added JavaScript's <code>in</code> operator,
      empty <code>return</code> statements, and empty <code>while</code> loops.
      <br />
      Constructor functions that start with capital letters now include a
      safety check to make sure that the new instance of the object is returned.
      <br />
      The <code>extends</code> keyword now functions identically to <code>goog.inherits</code>
      in Google's Closure Library.
    </p>

    <p>
      <%= releaseHeader('2010-01-05', '0.2.1', '0.2.0') %>
      Arguments objects are now converted into real arrays when referenced.
    </p>

    <p>
      <%= releaseHeader('2010-01-05', '0.2.0', '0.1.6') %>
      Major release. Significant whitespace. Better statement-to-expression
      conversion. Splats. Splice literals. Object comprehensions. Blocks.
      The existential operator. Many thanks to all the folks who posted issues,
      with special thanks to
      <a href="http://github.com/liamoc">Liam O'Connor-Davis</a> for whitespace
      and expression help.
    </p>

    <p>
      <%= releaseHeader('2009-12-27', '0.1.6', '0.1.5') %>
      Bugfix for running <code>coffee --interactive</code> and <code>--run</code>
      from outside of the CoffeeScript directory. Bugfix for nested
      function/if-statements.
    </p>

    <p>
      <%= releaseHeader('2009-12-26', '0.1.5', '0.1.4') %>
      Array slice literals and array comprehensions can now both take Ruby-style
      ranges to specify the start and end. JavaScript variable declaration is
      now pushed up to the top of the scope, making all assignment statements into
      expressions. You can use <code>\</code> to escape newlines.
      The <code>coffee-script</code> command is now called <code>coffee</code>.
    </p>

    <p>
      <%= releaseHeader('2009-12-25', '0.1.4', '0.1.3') %>
      The official CoffeeScript extension is now <code>.coffee</code> instead of
      <code>.cs</code>, which properly belongs to
      <a href="http://en.wikipedia.org/wiki/C_Sharp_(programming_language)">C#</a>.
      Due to popular demand, you can now also use <code>=</code> to assign. Unlike
      JavaScript, <code>=</code> can also be used within object literals, interchangeably
      with <code>:</code>. Made a grammatical fix for chained function calls
      like <code>func(1)(2)(3)(4)</code>. Inheritance and super no longer use
      <code>__proto__</code>, so they should be IE-compatible now.
    </p>

    <p>
      <%= releaseHeader('2009-12-25', '0.1.3', '0.1.2') %>
      The <code>coffee</code> command now includes <code>--interactive</code>,
      which launches an interactive CoffeeScript session, and <code>--run</code>,
      which directly compiles and executes a script. Both options depend on a
      working installation of Narwhal.
      The <code>aint</code> keyword has been replaced by <code>isnt</code>, which goes
      together a little smoother with <code>is</code>.
      Quoted strings are now allowed as identifiers within object literals: eg.
      <code>{"5+5": 10}</code>.
      All assignment operators now use a colon: <code>+:</code>, <code>-:</code>,
      <code>*:</code>, etc.
    </p>

    <p>
      <%= releaseHeader('2009-12-24', '0.1.2', '0.1.1') %>
      Fixed a bug with calling <code>super()</code> through more than one level of
      inheritance, with the re-addition of the <code>extends</code> keyword.
      Added experimental <a href="http://narwhaljs.org/">Narwhal</a>
      support (as a Tusk package), contributed by
      <a href="http://tlrobinson.net/">Tom Robinson</a>, including
      <b>bin/cs</b> as a CoffeeScript REPL and interpreter.
      New <code>--no-wrap</code> option to suppress the safety function
      wrapper.
    </p>

    <p>
      <%= releaseHeader('2009-12-24', '0.1.1', '0.1.0') %>
      Added <code>instanceof</code> and <code>typeof</code> as operators.
    </p>

    <p>
      <%= releaseHeader('2009-12-24', '0.1.0') %>
      Initial CoffeeScript release.
    </p>

  </div>

  <script type="text/coffeescript">
    sourceFragment = "try:"

    # Set up the compilation function, to run when you stop typing.
    compileSource = ->
      source = $('#repl_source').val()
      results = $('#repl_results')
      window.compiledJS = ''
      try
        window.compiledJS = CoffeeScript.compile source, bare: on
        el = results[0]
        if el.innerText
          el.innerText = window.compiledJS
        else
          results.text(window.compiledJS)
        results.removeClass 'error'
        $('.minibutton.run').removeClass 'error'
      catch {location, message}
        if location?
          message = "Error on line #{location.first_line + 1}: #{message}"
        results.text(message).addClass 'error'
        $('.minibutton.run').addClass 'error'

      # Update permalink
      $('#repl_permalink').attr 'href', "##{sourceFragment}#{encodeURIComponent source}"

    # Listen for keypresses and recompile.
    $('#repl_source').keyup -> compileSource()

    # Eval the compiled js.
    evalJS = ->
      try
        eval window.compiledJS
      catch error then alert error

    # Load the console with a string of CoffeeScript.
    window.loadConsole = (coffee) ->
      $('#repl_source').val coffee
      compileSource()
      $('.navigation.try').addClass('active')
      false

    # Helper to hide the menus.
    closeMenus = ->
      $('.navigation.active').removeClass 'active'

    $('.minibutton.run').click -> evalJS()

    # Bind navigation buttons to open the menus.
    $('.navigation').click (e) ->
      return if e.target.tagName.toLowerCase() is 'a'
      return false if $(e.target).closest('.repl_wrapper').length
      if $(this).hasClass('active')
        closeMenus()
      else
        closeMenus()
        $(this).addClass 'active'
      false

    # Dismiss console if Escape pressed or click falls outside console
    # Trigger Run button on Ctrl-Enter
    $(document.body)
      .keydown (e) ->
        closeMenus() if e.which == 27
        evalJS() if e.which == 13 and (e.metaKey or e.ctrlKey) and $('.minibutton.run:visible').length
      .click (e) ->
        return false if $(e.target).hasClass('minibutton')
        closeMenus()

    $('#open_webchat').click ->
      $(this).replaceWith $('<iframe src="http://webchat.freenode.net/?channels=coffeescript" width="625" height="400"></iframe>')

    $("#repl_permalink").click (e) ->
        window.location = $(this).attr("href")
        false

    # If source code is included in location.hash, display it.
    hash = decodeURIComponent location.hash.replace(/^#/, '')
    if hash.indexOf(sourceFragment) == 0
        src = hash.substr sourceFragment.length
        loadConsole src

    compileSource()

  </script>

  <script src="documentation/vendor/jquery-1.6.4.js"></script>
  <script src="extras/coffee-script.js"></script>

</body>
</html>
