exports.PatternSet = class PatternSet
  constructor: (patternStrings = [], {@negated = no} = {}) ->
    @matchers = (new RegExp p for p in patternStrings when p isnt '')

  isEmpty: -> @matchers.length is 0

  iterMatchers: -> @matchers[Symbol.iterator]()

  test_: (arg) -> @iterMatchers().some (m) -> m.exec arg

  allows: (arg) ->
    return yes if @isEmpty()
    if @negated
      not @test_ arg
    else
      @test_ arg

  @empty: ({negated = no} = {}) => new @ [], {negated}
