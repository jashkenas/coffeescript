desc "Recompile the Racc parser (pass -v and -g for verbose debugging)"
task :build, :extra_args do |t, args|
  sh "racc #{args[:extra_args]} -o lib/coffee_script/parser.rb lib/coffee_script/grammar.y"
end

namespace :gem do

  desc 'Build and install the coffee-script gem'
  task :install do
    sh "gem build coffee-script.gemspec"
    sh "sudo gem install #{Dir['*.gem'].join(' ')} --local --no-ri --no-rdoc"
  end

  desc 'Uninstall the coffee-script gem'
  task :uninstall do
    sh "sudo gem uninstall -x coffee-script"
  end

end