What Is Tame?
============

Tame is a system for handling callbacks in event-based code.  There
were two existing implementations, one in [the sfslite library for
C++](https://github.com/maxtaco/sfslite), and another in [tamejs
translator for JavaScript](https://github.com/maxtaco/tamejs), and
this fork of CoffeeScript attempts a third implementation. The code
and translation techniques are derived from experience with JS, but
with some new Coffee-style flavoring. Also, some of the features in
tamejs are not yet available here.

Examples
----------

Here is a simple example that prints "hello" 10 times, with 100ms
delay slots in between:

```coffeescript
# A basic serial loop
for i in [0..10]
  await setTimeout(defer(), 100)
  console.log "hello"
```

There is one new language addition here, the `await ... ` block (or
expression), and also one new primitive function, `defer`.  The two of
them work in concert.  A function must "wait" at the close of a
`await` block until all `defer`rals made in that `await` block are
fulfilled.  The function `defer` returns a callback, and a callee in
an `await` block can fulfill a deferral by simply calling the callback
it was given.  In the code above, there is only one deferral produced
in each iteration of the loop, so after it's fulfilled by `setTimer`
in 100ms, control continues past the `await` block, onto the log line,
and back to the next iteration of the loop.  The code looks and feels
like threaded code, but is still in the asynchronous idiom (if you
look at the rewritten code output by the *tamejs* compiler).

This next example does the same, while showcasing power of the
`await..` language addition.  In the example below, the two timers
are fired in parallel, and only when both have fulfilled their deferrals
(after 100ms), does progress continue...

```coffeescript
for i in [0..10]
  await 
    setTimeout defer(), 100
    setTimeout defer(), 10
  console.log ("hello");
```

Now for something more useful. Here is a parallel DNS resolver that
will exit as soon as the last of your resolutions completes:

```coffeescript
dns = require("dns");

do_one = (cb, host) ->
  await dns.resolve host, "A", defer(err, ip)
  if err
    console.log "ERROR! " + err
  else 
    console.log host + " -> " + ip
  cb()

do_all = (lst) ->
  await
    for h in lst
      do_one defer(), h

do_all process.argv.slice(2)
```

You can run this on the command line like so:

    coffee examples/tame/dns.coffee yahoo.com google.com nytimes.com okcupid.com tinyurl.com

And you will get a response:

    yahoo.com -> 72.30.2.43,98.137.149.56,209.191.122.70,67.195.160.76,69.147.125.65
    google.com -> 74.125.93.105,74.125.93.99,74.125.93.104,74.125.93.147,74.125.93.106,74.125.93.103
    nytimes.com -> 199.239.136.200
    okcupid.com -> 66.59.66.6
    tinyurl.com -> 195.66.135.140,195.66.135.139

If you want to run these DNS resolutions in serial (rather than
parallel), then the change from above is trivial: just switch the
order of the `await` and `for` statements above:

```coffeescript  
do_all = (lst) ->
  for h in lst
    await
      do_one defer(), h
```


Tranlsation Technique
---------------------

The CoffeeScript tame addition uses a simlar continuation-passing
translation to *tamejs*, but it's been refined greatly.  Here are
the general steps involved:

1. Run the standard CoffeeScript lexer, rewriter, and parser, with a 
few small additions (for `await` and `defer`), yielding
a standard CoffeeScript-style abstract syntax tree (AST).

1. Apply *tame annotations*:

   1. Find all `await` nodes in the AST.  Mark these nodes and their
     ancestors with an **A** flag.
   1. Find all `for`, `while`, or `loop` nodes marked with **A**.
     Mark them and their descendants with an **L** flag.
   1. Find all `continue` or `break` nodes marked with an **L** flag.
     Mark them and their descendants with a **P** flag.

At this point, all those nodes marked with **A** or **P** are those
that need to be "rotated" in the next step.

1. Rotate the AST

1. Output preamble/boilerplate

1. Compile as normal

