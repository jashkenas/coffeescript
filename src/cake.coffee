# `cake` is a simplified version of Make (Rake, Jake) for CoffeeScript.
# You define tasks with names and descriptions in a Cakefile, and can call them
# from the command line, or invoke them from other tasks.

fs:       require 'fs'
path:     require 'path'
coffee:   require 'coffee-script'

tasks: {}

# Mixin the top-level Cake functions for Cakefiles to use.
process.mixin {

  # Define a task with a name, a description, and the action itself.
  task: (name, description, action) ->
    tasks[name]: {name: name, description: description, action: action}

  # Invoke another task in the Cakefile.
  invoke: (name) ->
    no_such_task name unless tasks[name]
    tasks[name].action()
}

# Running `cake` runs the tasks you pass asynchronously (node-style), or
# prints them out, with no arguments.
exports.run: ->
  path.exists 'Cakefile', (exists) ->
    throw new Error('Cakefile not found in ' + process.cwd()) unless exists
    args: process.ARGV[2...process.ARGV.length]
    fs.readFile 'Cakefile', (err, source) ->
      eval coffee.compile source
      return print_tasks() unless args.length
      invoke arg for arg in args

# Display the list of Cake tasks.
print_tasks: ->
  for name, task of tasks
    spaces: 20 - name.length
    spaces: if spaces > 0 then (' ' for i in [0..spaces]).join('') else ''
    puts "cake " + name + spaces + ' # ' + task.description

# Print an error and exit when attempting to all an undefined task.
no_such_task: (task) ->
  process.stdio.writeError('No such task: "' + task + '"\n')
  process.exit(1)
