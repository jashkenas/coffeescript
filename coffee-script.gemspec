Gem::Specification.new do |s|
  s.name      = 'coffee-script'
  s.version   = '0.3.1'         # Keep version in sync with coffee-script.rb
  s.date      = '2010-1-27'

  s.homepage    = "http://jashkenas.github.com/coffee-script/"
  s.summary     = "The CoffeeScript Compiler"
  s.description = <<-EOS
    CoffeeScript is a little language that compiles into JavaScript. Think
    of it as JavaScript's less ostentatious kid brother -- the same genes,
    roughly the same height, but a different sense of style. Apart from a
    handful of bonus goodies, statements in CoffeeScript correspond
    one-to-one with their equivalent in JavaScript, it's just another
    way of saying it.
  EOS

  s.authors           = ['Jeremy Ashkenas']
  s.email             = 'jashkenas@gmail.com'
  s.rubyforge_project = 'coffee-script'
  s.has_rdoc          = false

  s.require_paths     = ['lib']
  s.executables       = ['coffee']

  s.files = Dir['bin/*', 'examples/*', 'extras/**/*', 'lib/**/*',
                'coffee-script.gemspec', 'LICENSE', 'README', 'package.json']
end