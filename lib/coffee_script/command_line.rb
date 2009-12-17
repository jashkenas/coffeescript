require 'optparse'
require 'fileutils'
require 'open3'
require File.expand_path(File.dirname(__FILE__) + '/../coffee-script')

module CoffeeScript

  class CommandLine

    BANNER = <<-EOS
coffee-script compiles CoffeeScript files into JavaScript.

Usage:
  coffee-script path/to/script.cs
    EOS

    def initialize
      parse_options
      check_sources
      compile_javascript
    end

    def usage
      puts "\n#{@option_parser}\n"
      exit
    end


    private

    def compile_javascript
      @sources.each do |source|
        contents = CoffeeScript.compile(File.open(source))
        next puts(contents) if @options[:print]
        next lint(contents) if @options[:lint]
        File.open(path_for(source), 'w+') {|f| f.write(contents) }
      end
    end

    def check_sources
      usage if @sources.empty?
      missing = @sources.detect {|s| !File.exists?(s) }
      if missing
        STDERR.puts("File not found: '#{missing}'")
        exit(1)
      end
    end

    # Pipe compiled JS through JSLint.
    def lint(js)
      stdin, stdout, stderr = Open3.popen3('jsl -nologo -stdin')
      stdin.write(js)
      stdin.close
      print stdout.read
      stdout.close and stderr.close
    end

    # Write out JavaScript alongside CoffeeScript unless an output directory
    # is specified.
    def path_for(source)
      filename = File.basename(source, File.extname(source)) + '.js'
      dir      = @options[:output] || File.dirname(source)
      File.join(dir, filename)
    end

    def parse_options
      @options = {}
      @option_parser = OptionParser.new do |opts|
        opts.on('-o', '--output [DIR]', 'set the directory for compiled javascript') do |d|
          @options[:output] = d
          FileUtils.mkdir_p(d) unless File.exists?(d)
        end
        opts.on('-p', '--print', 'print the compiled javascript to stdout') do |d|
          @options[:print] = true
        end
        opts.on('-l', '--lint', 'pipe the compiled javascript through JSLint') do |l|
          @options[:lint] = true
        end
        opts.on_tail('-v', '--version', 'display coffee-script version') do
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
