# `cake` is a simplified version of [Make](http://www.gnu.org/software/make/)
# ([Rake](http://rake.rubyforge.org/), [Jake](http://github.com/280north/jake))
# for CoffeeScript. You define tasks with names and descriptions in a Cakefile,
# and can call them from the command line, or invoke them from other tasks.
#
# Running `cake` with no arguments will print out a list of all the tasks in the
# current directory's Cakefile.

# External dependencies.
fs           = require 'fs'
path         = require 'path'
helpers      = require './helpers'
optparse     = require './optparse'
CoffeeScript = require './coffee-script'

# Keep track of the list of defined tasks, the accepted options, and so on.
tasks     = {}
options   = {}
switches  = []
oparse    = null

# Mixin the top-level Cake functions for Cakefiles to use directly.
helpers.extend global,

  # Define a Cake task with a short name, an optional sentence description,
  # and the function to run as the action itself.
  task: (name, description, action) ->
    [action, description] = [description, action] unless action
    tasks[name] = {name, description, action}

  # Define an option that the Cakefile accepts. The parsed options hash,
  # containing all of the command-line options passed, will be made available
  # as the first argument to the action.
  option: (letter, flag, description) ->
    switches.push [letter, flag, description]

  # Invoke another task in the current Cakefile.
  invoke: (name) ->
    missingTask name unless tasks[name]
    tasks[name].action options


# Run `cake`. Executes all of the tasks you pass, in order. Note that Node's
# asynchrony may cause tasks to execute in a different order than you'd expect.
# If no tasks are passed, print the help screen.
exports.run = ->
  path.exists 'Cakefile', (exists) ->
    throw new Error("Cakefile not found in #{process.cwd()}") unless exists
    args = process.argv.slice 2
    CoffeeScript.run fs.readFileSync('Cakefile').toString(), fileName: 'Cakefile'
    oparse = new optparse.OptionParser switches
    return printTasks() unless args.length
    options = oparse.parse(args)
    invoke arg for arg in options.arguments

# Display the list of Cake tasks in a format similar to `rake -T`
printTasks = ->
  puts ''
  for all name, task of tasks
    spaces = 20 - name.length
    spaces = if spaces > 0 then Array(spaces + 1).join(' ') else ''
    desc   = if task.description then "# #{task.description}" else ''
    puts "cake #{name}#{spaces} #{desc}"
  puts oparse.help() if switches.length

# Print an error and exit when attempting to all an undefined task.
missingTask = (task) ->
  puts "No such task: \"#{task}\""
  process.exit 1
