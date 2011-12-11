What Is Tame?
============

Tame is a system for handling callbacks in event-based code.  There
were two existing implementations, one in [the sfslite library for
C++](https://github.com/maxtaco/sfslite), and another in the [tamejs
translator for JavaScript](https://github.com/maxtaco/tamejs).
This extension to CoffeeScript is a third implementation. The code
and translation techniques are derived from experience with JS, but
with some new Coffee-style flavoring. 

This document first presents a tame tutorial (adapted from the JavaScript
version), and then discusses the specifics of the CoffeeScript implementation.

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
look at the rewritten code output by the *coffee* compiler).

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
  msg = if err then "ERROR! #{err}" else "#{host} -> #{ip}"
  console.log msg
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

Slightly More Advanced Example
-----------------------------

We've shown parallel and serial work flows, what about something in between?
For instance, we might want to make progress in parallel on our DNS lookups,
but not smash the server all at once. A compromise is windowing, which can be
achieved in tamed CoffeeScript conveniently in a number of different ways.  The [2007
academic paper on tame](http://pdos.csail.mit.edu/~max/docs/tame.pdf)
suggests a technique called a *rendezvous*.  A rendezvous is implemented in
CoffeeScript as a pure CS construct (no rewriting involved), which allows a
program to continue as soon as the first deferral is fulfilled (rather than
the last):

```coffeescript
tameRequire(node) # need full library via require() for rendezvous

do_all = (lst, windowsz) ->
  rv = new tame.Rendezvous
  nsent = 0
  nrecv = 0

  while nrecv < lst.length
    if nsent - nrecv < windowsz && nsent < n
      do_one(rv.id(nsent).defer(), lst[nsent])
      nsent++
    else
      await rv.wait defer(evid)
      console.log "got back lookup nsent=#{evid}"
      nrecv++
```

This code maintains two counters: the number of requests sent, and the
number received.  It keeps looping until the last lookup is received.
Inside the loop, if there is room in the window and there are more to
send, then send; otherwise, wait and harvest.  `Rendezvous.defer`
makes a deferral much like the `defer` primitive, but it can be
labeled with an identifier.  This way, the waiter can know which
deferral has fulfilled.  In this case we use the variable `nsent` as the
defer ID --- it's the ID of this deferral in launch order.  When we
harvest the deferral, `rv.wait` fires its callback with the ID of the
deferral that's harvested.  

Note that with windowing, the arrival order might not be the same as
the issue order. In this example, a slower DNS lookup might arrive
after faster ones, even if issued before them.

Composing Serial And Parallel Patterns
--------------------------------------

In Tame, arbitrary composition of serial and parallel control flows is
possible with just normal functional decomposition.  Therefore, we
don't allow direct `await` nesting.  With inline anonymous CoffeeScript
functions, you can concisely achieve interesting patterns.  The code
below launches 10 parallel computations, each of which must complete
two serial actions before finishing:

```coffeescript
f = (n,cb) ->
  await
    for i in [0..n]
      ((cb) ->
        await setTimeout defer(), 5*Math.random()
        await setTimeout defer(), 4*Math.random()
        cb()
      )(defer())
  cb()
```

autocb
------

Most of the time, a tamed function will call its callback and return
at the same time.  To get this behavior "for free", you can simply
name this callback `autocb` and it will fire whenever your tamed function
returns.  For instance, the above example could be equivalently written as:

```coffeescript
f = (n,autocb) ->
  await
    for i in [0..n]
      ((autocb) ->
        setTimeout defer(), 5*Math.random ()
        setTimeout defer(), 4*Math.random ()
      )(defer())
```
In the first example, recall, you call `cb()` explicitly.  In this
example, because the callback is named `autocb`, it's fired
automatically when the tamed function returns.

If your callback needs to fulfill with a value, then you can pass
that value via `return`.  Consider the following function, that waits
for a random number of seconds between 0 and 4. After waiting, it
then fulfills its callback `cb` with the amount of time it waited:

```coffeescript
rand_wait = (cb) ->
  time = Math.floor (Math.random()*5);
  if time == 0
   cb(0)
   return
  await setTimeout defer(), time
  cb(time) # return here, implicitly.....
```

This function can written equivalently with `autocb` as:

```coffeescript
rand_wait = (autocb) ->
  time = Math.floor (Math.random()*5);
  return 0 if time == 0
  await setTimeout defer(), time
  return time 
```

Implicitly, `return 0;` is mapped by the CoffeeScript compiler to `autocb(0); return`.

New Keywords
------------

In sum, the tame additions to CoffeeScript consist of three new keywords:

* **await***, marking off a block or a single statement.
* **defer**, which is quite similar to a normal function call, but is compiled specially
to accommodate argument passing.
* **tameRequire**, which is used to control the "require"ing of the tame runtime.  By
default, the runtime is pasted inline, but with `tameRequire(node)`, it is loaded
via node's `require`, and with `tameRequire(none)`, it is skipped altogether.

Finally, `autocb` isn't a bona-fide keyword, but the compiler searches for it in parameters
to CoffeeScript functions, and updates the behavior of the `Code` block accordingly.
 

Translation Technique
---------------------

The CoffeeScript tame addition uses a similar continuation-passing translation
to *tamejs*, but it's been refined to generate cleaner code, and to translate
only when necessary.  Here are the general steps involved:

* **1** Run the standard CoffeeScript lexer, rewriter, and parser, with a 
few small additions (for `await` and `defer`), yielding
a standard CoffeeScript-style abstract syntax tree (AST).

* **2** Apply *tame annotations*:

   * **2.1** Find all `await` nodes in the AST.  Mark these nodes and their
   ancestors with an **A** flag.

   * **2.2** Find all `for`, `while`, or `loop` nodes marked with **A**.
   Mark them and their descendants with an **L** flag.

   * **2.3** Find all `continue` or `break` nodes marked with an **L** flag.
   Mark them and their descendants with a **P** flag.

* **3** ``Rotate'' all those nodes marked with **A** or **P**:

   * **3.1** For each `Block` node _b_ in the `AST` marked **A** or **P**:

      * **3.1.1** Find _b_'s first child _c_ marked with with **A** or **P**.

      * **3.1.2** Cut _b_'s list of expressions after _c_, and move those
      expressions on the right of the cut into a new block, called
      _d_.  This block is _c_'s continuation block and becomes _c_'s
      child in the AST.  This is the actual ``rotation.''

      * **3.1.3** Call the rotation recursively on the child block _d_.

      * **3.1.4** Add an additional code to _c_'s body, which is to call the
      continuation represented by _d_.  For `if` statements this means
      calling the continuation in both branches; for `switch`
      statements, this means calling the continuation from all
      branches; for loops, this means calling `continue` at the end of
      the loop body; for blocks, this means just calling the
      continuation as the last statement in the block.  See
      `callContinuation` in `nodes.coffee.`

* **4** Output preamble/boilerplate; for the case of JavaScript output to
browsers, inline the small class `Deferrals` needed during runtime;
for node-based server-side JavaScript, a `require` statement suffices
here.  Only do this if the source file has a `defer` statement
in it.

* **5** Compile as normal.  The effect of the above is to mutate the original
CoffeeScript AST into another valid CoffeeScript AST.  This AST is then
compiled with the normal rules.


Translation Example
------------------

For an example translation, consider the following block of code:

```coffeescript

while x1
  f1()

while x2
  if y
    f2() 
    continue
    f3()
  await 
    f4(defer())
  if z
    f5()
    break
    f6()

while x3
  f7()
```

* Here is schematic diagram for this AST:

   <img src="/maxtaco/coffee-script/raw/master/media/rotate1.png" width=650 />

* After Step 2.1, nodes in blue are marked with **A**.  Recall, Step 2.1 traces
upwards from all `await` blocks.

   <img src="/maxtaco/coffee-script/raw/master/media/rotate2.png" width=650 />

* After Step 2.2, nodes in purple are marked with **L**.  Recall, Step 2.2 floods
downwards from any any loops marked with **A**.

   <img src="/maxtaco/coffee-script/raw/master/media/rotate3.png" width=650 />

* After Step 2.3, nodes in yellow are marked with **P**.  Recall, Step 2.3 
traces upwards from any jumps marked with **L**.

   <img src="/maxtaco/coffee-script/raw/master/media/rotate4.png" width=650 />

* The green nodes are those marked with **A** or **P**.  They are "marked"
for rotations in the next step.

   <img src="/maxtaco/coffee-script/raw/master/media/rotate5.png" width=650 />

* In Step 3, rotate all marked nodes AST nodes. This rotation
introduces the new orange `block` nodes in the graph, and attaches
them to pivot nodes as _continuation_ blocks.

   <img src="/maxtaco/coffee-script/raw/master/media/post-rotate.png" width=650 />


* In translated code, the general format of a _pivot_ node is:

```javascript
(function (k) {
   // the body
   k();
})(function () {
   // the continuation block.
}
```

To see how pivots and continuations are output in our example, look
at this portion of the AST, introduced after Step 3:
   
   ![detail](/maxtaco/coffee-script/raw/master/media/detail.png)

Here is the translated output (slightly hand-edited for clarity):

```javascript
(function() {
  // await block f4()
  (function(k) {
    var __deferrals = new tame.Deferrals(k);
    f4(__deferrals.defer({}));
    __deferrals._fulfill();
  })(function() {
    // The continuation block, starting at 'if z'
    (function(k) {
      if (z) {
        f5();
        (function(k) {
          // 'break' throws away the current continuation 'k'
          // and just calls _break()
          _break();
        })(function() {
          // A continuation block, after 'break', up to 'f6()'
          // This code will never be reached
          f6();
          return k();
        });
      } else {
        return k();
      }
    })(function() {
      // end of the loop, call _continue() to start at the top
      return _continue();
    });
  });
});
```

