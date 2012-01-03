if vm = require? 'vm'

  test "CoffeeScript.eval runs in the global context by default", ->
    global.punctuation = '!'
    code = '''
    global.fhqwhgads = "global superpower#{global.punctuation}"
    '''
    result = CoffeeScript.eval code
    eq result, 'global superpower!'
    eq fhqwhgads, 'global superpower!'

  test "CoffeeScript.eval can run in, and modify, a Script context sandbox", ->
    sandbox = vm.Script.createContext()
    sandbox.foo = 'bar'
    code = '''
    global.foo = 'not bar!'
    '''
    result = CoffeeScript.eval code, {sandbox}
    eq result, 'not bar!'
    eq sandbox.foo, 'not bar!'

  test "CoffeeScript.eval can run in, but cannot modify, an ordinary object sandbox", ->
    sandbox = {foo: 'bar'}
    code = '''
    global.foo = 'not bar!'
    '''
    result = CoffeeScript.eval code, {sandbox}
    eq result, 'not bar!'
    eq sandbox.foo, 'bar'
