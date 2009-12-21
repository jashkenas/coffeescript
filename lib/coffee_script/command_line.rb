require 'optparse'
require 'fileutils'
require 'open3'
require File.expand_path(File.dirname(__FILE__) + '/../coffee-script')

module CoffeeScript

  # The CommandLine handles all of the functionality of the `coffee-script`
  # utility.
  class CommandLine

    BANNER = <<-EOS
coffee-script compiles CoffeeScript files into JavaScript.

Usage:
  coffee-script path/to/script.cs
    EOS

    # Seconds to pause between checks for changed source files.
    WATCH_INTERVAL = 0.5

    # Run the CommandLine off the contents of ARGV.
    def initialize
      @mtimes = {}
      parse_options
      return eval_scriptlet if @options[:eval]
      check_sources
      @sources.each {|source| compile_javascript(source) }
      watch_coffee_scripts if @options[:watch]
    end

    # The "--help" usage message.
    def usage
      puts "\n#{@option_parser}\n"
      exit
    end


    private

    # Compiles (or partially compiles) the source CoffeeScript file, returning
    # the desired JS, tokens, or lint results.
    def compile_javascript(source)
      return tokens(source) if @options[:tokens]
      contents = compile(source)
      return unless contents
      return puts(contents) if @options[:print]
      return lint(contents) if @options[:lint]
      File.open(path_for(source), 'w+') {|f| f.write(contents) }
    end

    # Spins up a watcher thread to keep track of the modification times of the
    # source files, recompiling them whenever they're saved.
    def watch_coffee_scripts
      watch_thread = Thread.start do
        loop do
          @sources.each do |source|
            mtime = File.stat(source).mtime
            @mtimes[source] ||= mtime
            if mtime > @mtimes[source]
              @mtimes[source] = mtime
              compile_javascript(source)
            end
          end
          sleep WATCH_INTERVAL
        end
      end
      Signal.trap("INT") { watch_thread.kill }
      watch_thread.join
    end

    # Ensure that all of the source files exist.
    def check_sources
      usage if @sources.empty?
      missing = @sources.detect {|s| !File.exists?(s) }
      if missing
        STDERR.puts("File not found: '#{missing}'")
        exit(1)
      end
    end

    # Pipe compiled JS through JSLint (requires a working 'jsl' command).
    def lint(js)
      stdin, stdout, stderr = Open3.popen3('jsl -nologo -stdin')
      stdin.write(js)
      stdin.close
      puts stdout.read.tr("\n", '')
      errs = stderr.read.chomp
      puts errs unless errs.empty?
      stdout.close and stderr.close
    end

    # Eval a little piece of CoffeeScript directly from the command line.
    def eval_scriptlet
      puts CoffeeScript.compile(@sources.join(' '))
    end

    # Print the tokens that the lexer generates from a source script.
    def tokens(source)
      puts Lexer.new.tokenize(File.read(source)).inspect
    end

    # Compile a single source file to JavaScript.
    def compile(source)
      begin
        CoffeeScript.compile(File.open(source))
      rescue CoffeeScript::ParseError => e
        STDERR.puts e.message(source)
        exit(1) unless @options[:watch]
        nil
      end
    end

    # Write out JavaScript alongside CoffeeScript unless an output directory
    # is specified.
    def path_for(source)
      filename = File.basename(source, File.extname(source)) + '.js'
      dir      = @options[:output] || File.dirname(source)
      File.join(dir, filename)
    end

    # Install the CoffeeScript TextMate bundle to ~/Library.
    def install_bundle
      bundle_dir = File.expand_path('~/Library/Application Support/TextMate/Bundles/')
      FileUtils.cp_r(File.dirname(__FILE__) + '/CoffeeScript.tmbundle', bundle_dir)
    end

    # Use OptionParser for all the options.
    def parse_options
      @options = {}
      @option_parser = OptionParser.new do |opts|
        opts.on('-o', '--output [DIR]', 'set the directory for compiled JavaScript') do |d|
          @options[:output] = d
          FileUtils.mkdir_p(d) unless File.exists?(d)
        end
        opts.on('-w', '--watch', 'watch scripts for changes, and recompile') do |w|
          @options[:watch] = true
        end
        opts.on('-p', '--print', 'print the compiled JavaScript to stdout') do |d|
          @options[:print] = true
        end
        opts.on('-l', '--lint', 'pipe the compiled JavaScript through JSLint') do |l|
          @options[:lint] = true
        end
        opts.on('-e', '--eval', 'eval a little scriptlet directly from the cli') do |e|
          @options[:eval] = true
        end
        opts.on('-t', '--tokens', 'print the tokens that the lexer produces') do |t|
          @options[:tokens] = true
        end
        opts.on('-v', '--verbose', 'print at every step of code generation') do |v|
          ENV['VERBOSE'] = 'true'
        end
        opts.on_tail('--install-bundle', 'install the CoffeeScript TextMate bundle') do |i|
          install_bundle
          exit
        end
        opts.on_tail('--version', 'display coffee-script version') do
          puts "coffee-script version #{CoffeeScript::VERSION}"
          exit
        end
        opts.on_tail('-h', '--help', 'display this help message') do
          usage
        end
      end
      @option_parser.banner = BANNER
      begin
        @option_parser.parse!(ARGV)
      rescue OptionParser::InvalidOption => e
        puts e.message
        exit(1)
      end
      @sources = ARGV
    end

  end

end
