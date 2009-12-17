Gem::Specification.new do |s|
  s.name      = 'coffee-script'
  s.version   = '0.1.0'         # Keep version in sync with coffee-script.rb
  s.date      = '2009-12-16'

  s.homepage    = "http://jashkenas.github.com/coffee-script/"
  s.summary     = "The CoffeeScript Compiler"
  s.description = <<-EOS
    ...
  EOS

  s.authors           = ['Jeremy Ashkenas']
  s.email             = 'jashkenas@gmail.com'
  s.rubyforge_project = 'coffee-script'
  s.has_rdoc          = false

  s.require_paths     = ['lib']
  s.executables       = ['coffee-script']

  s.files = Dir['bin/*', 'examples/*', 'lib/**/*', 'coffee-script.gemspec', 'LICENSE', 'README']
end