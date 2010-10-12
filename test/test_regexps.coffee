# Regular expression literals.
ok 'x'.match(/x/g)
ok 'x'.match /x/g
ok 'x'.match(/x/)
ok 'x'.match /x/

ok 4 / 2 / 1 is 2

y = 4
x = 2
g = 1

ok y / x/g is 2

ok /:\/[/]goog/.test 'http://google.com'

obj = {
  width:  -> 10
  height: -> 20
}
id = 2

ok (obj.width()/id - obj.height()/id) is -5

eq /\\/.source, "\\\\"


eq /^I'm\s+Heregex?\/\/\//gim + '', ///
  ^ I'm \s+ Heregex? / // # or not
///gim + ''
eq '\\\\#{}\\\\\\\"', ///
 #{
   "#{ '\\' }" # normal comment
 }
 # regex comment
 \#{}
 \\ \"
///.source
eq ///  /// + '', '/(?:)/'


# Issue #584.
regex = /[/]/
s1    = "Hello there"
s2    = "Hello / there"
ok not regex.test(s1)
ok regex.test(s2)
