## Cake, and Cakefiles

CoffeeScript includes a (very) simple build system similar to [Make](http://www.gnu.org/software/make/) and [Rake](http://rake.rubyforge.org/). Naturally, it’s called Cake, and is used for the tasks that build and test the CoffeeScript language itself. Tasks are defined in a file named `Cakefile`, and can be invoked by running `cake [task]` from within the directory. To print a list of all the tasks and options, just type `cake`.

Task definitions are written in CoffeeScript, so you can put arbitrary code in your Cakefile. Define a task with a name, a long description, and the function to invoke when the task is run. If your task takes a command-line option, you can define the option with short and long flags, and it will be made available in the `options` object. Here’s a task that uses the Node.js API to rebuild CoffeeScript’s parser:

```
codeFor('cake_tasks')
```

If you need to invoke one task before another — for example, running `build` before `test`, you can use the `invoke` function: `invoke 'build'`. Cake tasks are a minimal way to expose your CoffeeScript functions to the command line, so [don’t expect any fanciness built-in](/v<%= majorVersion %>/annotated-source/cake.html). If you need dependencies, or async callbacks, it’s best to put them in your code itself — not the cake task.
