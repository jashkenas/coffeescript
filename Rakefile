desc "Recompile the Racc parser (pass -v and -g for verbose debugging)"
task :build, :extra_args do |t, args|
  sh "racc #{args[:extra_args]} -o lib/coffee_script/parser.rb lib/coffee_script/grammar.y"
end


# # Pipe compiled JS through JSLint.
# puts "\n\n"
# require 'open3'
# stdin, stdout, stderr = Open3.popen3('jsl -nologo -stdin')
# stdin.write(js)
# stdin.close
# puts stdout.read
# stdout.close
# stderr.close