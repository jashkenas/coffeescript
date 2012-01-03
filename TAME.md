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

# Quick Tutorial and Examples

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

do_all process.argv[2...]
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

### Slightly More Advanced Example

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
    if nsent - nrecv < windowsz and  nsent < n
      do_one rv.id(nsent).defer(), lst[nsent]
      nsent++
    else
      await rv.wait defer evid
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

### Composing Serial And Parallel Patterns

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
        await setTimeout defer(), 5 * Math.random()
        await setTimeout defer(), 4 * Math.random()
        cb()
      )(defer())
  cb()
```

### autocb

Most of the time, a tamed function will call its callback and return
at the same time.  To get this behavior "for free", you can simply
name this callback `autocb` and it will fire whenever your tamed function
returns.  For instance, the above example could be equivalently written as:

```coffeescript
f = (n,autocb) ->
  await
    for i in [0..n]
      ((autocb) ->
        setTimeout defer(), 5 * Math.random()
        setTimeout defer(), 4 * Math.random()
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
  time = Math.floor Math.random() * 5
  if time is 0
   cb(0)
   return
  await setTimeout defer(), time
  cb(time) # return here, implicitly.....
```

This function can written equivalently with `autocb` as:

```coffeescript
rand_wait = (autocb) ->
  time = Math.floor  Math.random() * 5 
  return 0 if time is 0
  await setTimeout defer(), time
  return time 
```

Implicitly, `return 0;` is mapped by the CoffeeScript compiler to `autocb(0); return`.

## Language Design Considerations

In sum, the tame additions to CoffeeScript consist of three new keywords:

* **await**, marking off a block or a single statement.
* **defer**, which is quite similar to a normal function call, but is compiled specially
to accommodate argument passing.
* **tameRequire**, which is used to control the "require"ing of the tame runtime.  By
default, the runtime is pasted inline, but with `tameRequire(node)`, it is loaded
via node's `require`, and with `tameRequire(none)`, it is skipped altogether.

Finally, `autocb` isn't a bona-fide keyword, but the compiler searches
for it in parameters to CoffeeScript functions, and updates the
behavior of the `Code` block accordingly.

These keywords represent the potential for these tame additions to
break existing CoffeeScript code --- any preexisting use of these
keywords as regular function, variable or class names will cause
headaches.

### The Lowdown on defer

The implementation of `defer` is interesting --- it's trying to
emulate ``call by reference'' in languages like C++ or Java.  Here is an 
example that shows off the four different cases required to make this
happen:

```coffeescript
cb = defer x, obj.field, arr[i], rest...
```

And here is the output from the tamed `coffee` compiler:

```javascript
cb = __tame_deferrals.defer({
    assign_fn: (function(__slot_1, __slot_2, __slot_3) {
      return function() {
        x = arguments[0];
        __slot_1.field = arguments[1];
        __slot_2[__slot_3] = arguments[2];
        return rest = __slice.call(arguments, 3);
      };
    })(obj, arr, i)
  });
```

The `__tame_deferrals` object is an internal object of type `Deferrals`
that's collecting all calls to `defer` in the current `await` block.
The one in question should fulfill with 3 or more values.  When it does,
it will call into the innermost anonymous function to perform the 
appropriate assignments in the original scope. The four cases are:

1. **Simple assignment** --- seen in `x = arguments[0]`.  Here, the
`x` variable is in the scope of the original `defer` call.

1. **Object slot assignment** --- seen in `__slot_1.field = arguments[1]`.
Here, the reference `obj` must be captured at the time of the `defer` call,
and `obj.field` is filled in later.

1. **Array cell assignment** --- seen in `__slot_2[__slot_3] = arguments[2]`.
This of course will work on an array or an object.  Here, the reference
to the array, and the value of the index must be captured when `defer`
is called, and the cell is assigned later.

1. **Splat assignment** --- seen in `res = __slice.call(arguments,3)`.
This is much like a simple assignment, but allows a ``splat'' meaning
assignment of multiple values at once, accessed as an array.

These specifics are also detailed in the code in the `Defer` class,
file `nodes.coffee`.

### Awaits Can work as Expressions

I don't really like this feature, but people have requested it, so
here goes a trip down the rabbit hole.  It's possible to use `await`
blocks as expressions. And recursively speaking, it's possible to use
statements that contain `await` blocks as expressions.

The simple rule is that an `await` block takes on the value of the
`defer` slot named `_` after its been fulfilled.  If there
are multiple `defer` slots named `_` within the `await` block, then
the last writer wins.  In practice, there's usually only one. Thus:

```coffeescript
add = (a,b,cb) ->
  await setTimeout defer(), 10
  cb(a+b)

x = (await add 3, 4, defer _) + (await add 1, 2, defer _)
console.log "#{x} == 10"
```

Of course, things can get arbitrarily compicated and nested, so it
gets hairy.  Consider this:

```coffeescript
x = await add (await add 1, 2, defer _), (await add 3, 4, defer _), defer _
```

The rule is that all nested `await` blocks (barf!) are evaluated
sequentially in DFS order. You will get `10` in the above example
after three sequential calls to `add`.

I really don't like this feature for two reasons: (1) it's tricky to
get the implementation right, and I'm sure I haven't tested all of the
corner cases yet; (2) it's difficult to read and understand what
happens in which order.  I would suggest you save yourself the heartache,
and just write the above as this:

```coffeescript
await add 1, 2, defer l
await add 3, 4, defer r
await add l, r, defer x
```

It's just so much clearer what happens in which order, and it's easier
to parallelize or serialize as you see fit.

## Translation Technique

The CoffeeScript tame addition uses a similar continuation-passing translation
to *tamejs*, but it's been refined to generate cleaner code, and to translate
only when necessary.  Here are the general steps involved:

* **1** Run the standard CoffeeScript lexer, rewriter, and parser, with a 
few small additions (for `await` and `defer`), yielding
a standard CoffeeScript-style abstract syntax tree (AST).

* **2** Apply *tame annotations*:

   * **2.1** Find all `await` nodes in the AST.  Mark these nodes and their
   ancestors with an **A** flag.

   * **2.2** Find all `for`, `while`, `until`, or `loop` nodes marked with
   **A**.  Mark them and their descendants with an **L** flag.

   * **2.3** Find all `continue` or `break` nodes marked with an **L** flag.
   Mark them and their descendants with a **P** flag.

* **3** ``Rotate'' all those nodes marked with **A** or **P**:

   * **3.1** For each `Block` node _b_ in the `AST` marked **A** or **P**:

      * **3.1.1** Find _b_'s first child _c_ marked with **A** or **P**.

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

   <img src="/maxtaco/coffee-script/raw/tame/media/rotate1.png" width=650 />

* After Step 2.1, nodes in blue are marked with **A**.  Recall, Step 2.1 traces
upwards from all `await` blocks.

   <img src="/maxtaco/coffee-script/raw/tame/media/rotate2.png" width=650 />

* After Step 2.2, nodes in purple are marked with **L**.  Recall, Step 2.2 floods
downwards from any any loops marked with **A**.

   <img src="/maxtaco/coffee-script/raw/tame/media/rotate3.png" width=650 />

* After Step 2.3, nodes in yellow are marked with **P**.  Recall, Step 2.3 
traces upwards from any jumps marked with **L**.

   <img src="/maxtaco/coffee-script/raw/tame/media/rotate4.png" width=650 />

* The green nodes are those marked with **A** or **P**.  They are "marked"
for rotations in the next step.

   <img src="/maxtaco/coffee-script/raw/tame/media/rotate5.png" width=650 />

* In Step 3, rotate all marked nodes AST nodes. This rotation
introduces the new orange `block` nodes in the graph, and attaches
them to pivot nodes as _continuation_ blocks.

   <img src="/maxtaco/coffee-script/raw/tame/media/post-rotate.png" width=650 />


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
   
   ![detail](/maxtaco/coffee-script/raw/tame/media/detail.png)

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

## API and Library Documentation

### tame.Rendezvous

The `Rendezvous` is a not a core feature, meaning it's written as a 
straight-ahead CoffeeScript library.  It's quite useful for more advanced
control flows, so we've included it in the main runtime library.

The `Rendezvous` is similar to a blocking condition variable (or a
"Hoare sytle monitor") in threaded programming.

#### tame.Rendezvous.id(i).defer slots...

Associate a new deferral with the given Rendezvous, whose deferral ID
is `i`, and whose callbacks slots are supplied as `slots`.  Those
slots can take the two forms of `defer` return as above.  As with
standard `defer`, the return value of the `Rendezvous`'s `defer` is
fed to a function expecting a callback.  As soon as that callback
fires (and the deferral is fulfilled), the provided slots will be
filled with the arguments to that callback.

#### tame.Rendezvous.defer slots...

You don't need to explicitly assign an ID to a deferral generated from a
Rendezvous.  If you don't, one will automatically be assigned, in
ascending order starting from `0`.

#### tame.Rendezvous.wait cb

Wait until the next deferral on this rendezvous is fulfilled.  When it
is, callback `cb` with the ID of the fulfilled deferral.  If an
unclaimed deferral fulfilled before `wait` was called, then `cb` is fired
immediately.

Though `wait` would work with any hand-rolled JS function expecting
a callback, it's meant to work particularly well with *tamejs*'s
`await` function.

#### Example

Here is an example that shows off the different inputs and 
outputs of a `Rendezvous`.  It does two parallel DNS lookups,
and reports only when the first returns:

```coffeescript
hosts = [ "okcupid.com", "google.com" ];
ips = errs = []
rv = new tame.Rendezvous ();
for h,i in hosts
    dns.resolve hosts[i], rv.id(i).defer errs[i], ips[i]

await rv.wait defer which
console.log "#{hosts[which]}  -> #{ips[which]}"
```

### connectors

A *connector* is a function that takes as input
a callback, and outputs another callback.   The best example 
is a `timeout`, given here:

#### tame.timeout(cb, time, res = [])

Timeout an arbitrary async operation.

Given a callback `cb`, a time to wait `time`, and an array to output a
result `res`, return another callback.  This connector will set up a
race between the callback returned to the caller, and the timer that
fires after `time` milliseconds.  If the callback returned to the
caller fires first, then fill `res[0] = true;`.  If the timer won
(i.e., if there was a timeout), then fill `res[0] = false;`.

In the following example, we timeout a DNS lookup after 100ms:

```coffeescript
{timeout} = require 'tamelib'
info = [];
host = "pirateWarezSite.ru";
await dns.lookup host, timeout(defer(err, ip), 100, info)
if not info[0]
    console.log "#{host}: timed out!"
else if (err)
    console.log "#{host}: error: #{err}"
else
    console.log "#{host} -> #{ip}"
```

### The Pipeliner library

There's another way to do the windowed DNS lookups we saw earlier ---
you can use the control flow library called `Pipeliner`, which 
manages the common pattern of having "m calls total, with only
n of them in flight at once, where m > n."

The Pipeliner class is available in the `tamelib` library:

```coffeescript
{Pipeliner} = require 'tamelib'
pipeliner = new Pipeliner w,s 
```

Using the pipeliner, we can rewrite our earlier windowed DNS lookups
as follows:

```coffescript
do_all = (lst, windowsz) ->
  pipeliner = new Pipeliner windowsz
  for x in list
    await pipeliner.waitInQueue defer()
    do_one pipeliner.defer(), x
  await pipeliner.flush defer()
```

The API is as follows:

#### new Pipeliner w, s

Create a new Pipeliner controller, with a window of at most `w` calls
out at once, and waiting `s` seconds before launching each call.  The
default values are `w = 10` and `s = 0`.

#### Pipeliner.waitInQueue c

Wait in a queue until there's room in the window to launch a new call.
The callback `c` will be fulfilled when there is room.

#### Pipeliner.defer args...

Create a new `defer`al for this pipeline, and pass it to whatever
function is doing the actual work.  When the work completes, fulfill
this `defer`al --- that will update the accounting in the pipeliner
class, allowing queued actions to proceed.

#### Pipeliner.flush c

Wait for the pipeline to clear out.  Fulfills the callback `c`
when the last action in the pipeline is done.
