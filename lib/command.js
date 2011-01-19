(function() {
  var BANNER, CoffeeScript, EventEmitter, SWITCHES, compileJoin, compileOptions, compileScript, compileScripts, compileStdio, contents, exec, forkNode, fs, helpers, lint, loadRequires, optionParser, optparse, opts, parseOptions, path, printLine, printTokens, printWarn, sources, spawn, usage, version, watch, writeJs, _ref;
  fs = require('fs');
  path = require('path');
  helpers = require('./helpers');
  optparse = require('./optparse');
  CoffeeScript = require('./coffee-script');
  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;
  EventEmitter = require('events').EventEmitter;
  helpers.extend(CoffeeScript, new EventEmitter);
  printLine = function(line) {
    return process.stdout.write(line + '\n');
  };
  printWarn = function(line) {
    return process.binding('stdio').writeError(line + '\n');
  };
  BANNER = 'Usage: coffee [options] path/to/script.coffee';
  SWITCHES = [['-c', '--compile', 'compile to JavaScript and save as .js files'], ['-i', '--interactive', 'run an interactive CoffeeScript REPL'], ['-o', '--output [DIR]', 'set the directory for compiled JavaScript'], ['-j', '--join', 'concatenate the scripts before compiling'], ['-w', '--watch', 'watch scripts for changes, and recompile'], ['-p', '--print', 'print the compiled JavaScript to stdout'], ['-l', '--lint', 'pipe the compiled JavaScript through JSLint'], ['-s', '--stdio', 'listen for and compile scripts over stdio'], ['-e', '--eval', 'compile a string from the command line'], ['-r', '--require [FILE*]', 'require a library before executing your script'], ['-b', '--bare', 'compile without the top-level function wrapper'], ['-t', '--tokens', 'print the tokens that the lexer produces'], ['-n', '--nodes', 'print the parse tree that Jison produces'], ['--nodejs [ARGS]', 'pass options through to the "node" binary'], ['-v', '--version', 'display CoffeeScript version'], ['-h', '--help', 'display this help message']];
  opts = {};
  sources = [];
  contents = [];
  optionParser = null;
  exports.run = function() {
    parseOptions();
    if (opts.nodejs) {
      return forkNode();
    }
    if (opts.help) {
      return usage();
    }
    if (opts.version) {
      return version();
    }
    if (opts.require) {
      loadRequires();
    }
    if (opts.interactive) {
      return require('./repl');
    }
    if (opts.stdio) {
      return compileStdio();
    }
    if (opts.eval) {
      return compileScript(null, sources[0]);
    }
    if (!sources.length) {
      return require('./repl');
    }
    if (opts.run) {
      opts.literals = sources.splice(1).concat(opts.literals);
    }
    process.ARGV = process.argv = process.argv.slice(0, 2).concat(opts.literals);
    return compileScripts();
  };
  compileScripts = function() {
    var base, compile, source, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = sources.length; _i < _len; _i++) {
      source = sources[_i];
      base = path.join(source);
      compile = function(source, topLevel) {
        return path.exists(source, function(exists) {
          if (topLevel && !exists) {
            throw new Error("File not found: " + source);
          }
          return fs.stat(source, function(err, stats) {
            if (stats.isDirectory()) {
              return fs.readdir(source, function(err, files) {
                var file, _i, _len, _results;
                _results = [];
                for (_i = 0, _len = files.length; _i < _len; _i++) {
                  file = files[_i];
                  _results.push(compile(path.join(source, file)));
                }
                return _results;
              });
            } else if (topLevel || path.extname(source) === '.coffee') {
              fs.readFile(source, function(err, code) {
                if (opts.join) {
                  contents[sources.indexOf(source)] = code.toString();
                  if (helpers.compact(contents).length === sources.length) {
                    return compileJoin();
                  }
                } else {
                  return compileScript(source, code.toString(), base);
                }
              });
              if (opts.watch && !opts.join) {
                return watch(source, base);
              }
            }
          });
        });
      };
      _results.push(compile(source, true));
    }
    return _results;
  };
  compileScript = function(file, input, base) {
    var o, options, t, task;
    o = opts;
    options = compileOptions(file);
    try {
      t = task = {
        file: file,
        input: input,
        options: options
      };
      CoffeeScript.emit('compile', task);
      if (o.tokens) {
        return printTokens(CoffeeScript.tokens(t.input));
      } else if (o.nodes) {
        return printLine(CoffeeScript.nodes(t.input).toString().trim());
      } else if (o.run) {
        return CoffeeScript.run(t.input, t.options);
      } else {
        t.output = CoffeeScript.compile(t.input, t.options);
        CoffeeScript.emit('success', task);
        if (o.print) {
          return printLine(t.output.trim());
        } else if (o.compile) {
          return writeJs(t.file, t.output, base);
        } else if (o.lint) {
          return lint(t.file, t.output);
        }
      }
    } catch (err) {
      CoffeeScript.emit('failure', err, task);
      if (CoffeeScript.listeners('failure').length) {
        return;
      }
      if (o.watch) {
        return printLine(err.message);
      }
      printWarn(err.stack);
      return process.exit(1);
    }
  };
  compileStdio = function() {
    var code, stdin;
    code = '';
    stdin = process.openStdin();
    stdin.on('data', function(buffer) {
      if (buffer) {
        return code += buffer.toString();
      }
    });
    return stdin.on('end', function() {
      return compileScript(null, code);
    });
  };
  compileJoin = function() {
    var code;
    code = contents.join('\n');
    return compileScript("concatenation", code, "concatenation");
  };
  loadRequires = function() {
    var realFilename, req, _i, _len, _ref;
    realFilename = module.filename;
    module.filename = '.';
    _ref = opts.require;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      req = _ref[_i];
      require(req);
    }
    return module.filename = realFilename;
  };
  watch = function(source, base) {
    return fs.watchFile(source, {
      persistent: true,
      interval: 500
    }, function(curr, prev) {
      if (curr.size === prev.size && curr.mtime.getTime() === prev.mtime.getTime()) {
        return;
      }
      return fs.readFile(source, function(err, code) {
        if (err) {
          throw err;
        }
        return compileScript(source, code.toString(), base);
      });
    });
  };
  writeJs = function(source, js, base) {
    var baseDir, compile, dir, filename, jsPath, srcDir;
    filename = path.basename(source, path.extname(source)) + '.js';
    srcDir = path.dirname(source);
    baseDir = base === '.' ? srcDir : srcDir.substring(base.length);
    dir = opts.output ? path.join(opts.output, baseDir) : srcDir;
    jsPath = path.join(dir, filename);
    compile = function() {
      if (js.length <= 0) {
        js = ' ';
      }
      return fs.writeFile(jsPath, js, function(err) {
        if (err) {
          return printLine(err.message);
        } else if (opts.compile && opts.watch) {
          return console.log("" + ((new Date).toTimeString()) + " - compiled " + source);
        }
      });
    };
    return path.exists(dir, function(exists) {
      if (exists) {
        return compile();
      } else {
        return exec("mkdir -p " + dir, compile);
      }
    });
  };
  lint = function(file, js) {
    var conf, jsl, printIt;
    printIt = function(buffer) {
      return printLine(file + ':\t' + buffer.toString().trim());
    };
    conf = __dirname + '/../extras/jsl.conf';
    jsl = spawn('jsl', ['-nologo', '-stdin', '-conf', conf]);
    jsl.stdout.on('data', printIt);
    jsl.stderr.on('data', printIt);
    jsl.stdin.write(js);
    return jsl.stdin.end();
  };
  printTokens = function(tokens) {
    var strings, tag, token, value;
    strings = (function() {
      var _i, _len, _ref, _results;
      _results = [];
      for (_i = 0, _len = tokens.length; _i < _len; _i++) {
        token = tokens[_i];
        _ref = [token[0], token[1].toString().replace(/\n/, '\\n')], tag = _ref[0], value = _ref[1];
        _results.push("[" + tag + " " + value + "]");
      }
      return _results;
    })();
    return printLine(strings.join(' '));
  };
  parseOptions = function() {
    var o;
    optionParser = new optparse.OptionParser(SWITCHES, BANNER);
    o = opts = optionParser.parse(process.argv.slice(2));
    o.compile || (o.compile = !!o.output);
    o.run = !(o.compile || o.print || o.lint);
    o.print = !!(o.print || (o.eval || o.stdio && o.compile));
    return sources = o.arguments;
  };
  compileOptions = function(filename) {
    return {
      filename: filename,
      bare: opts.bare
    };
  };
  forkNode = function() {
    var args, nodeArgs;
    nodeArgs = opts.nodejs.split(/\s+/);
    args = process.argv.slice(1);
    args.splice(args.indexOf('--nodejs'), 2);
    return spawn(process.execPath, nodeArgs.concat(args), {
      cwd: process.cwd(),
      env: process.env,
      customFds: [0, 1, 2]
    });
  };
  usage = function() {
    return printLine((new optparse.OptionParser(SWITCHES, BANNER)).help());
  };
  version = function() {
    return printLine("CoffeeScript version " + CoffeeScript.VERSION);
  };
}).call(this);
