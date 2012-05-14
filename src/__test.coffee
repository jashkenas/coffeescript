LOG = console.log

class EmptyClass

class Parent
  LOG 'executed on class body'
  @classVar1:   "parent - classVar1"
  @classMethod1: ->
    super
    return      "parent - classMethod1"
  var1:         "parent - var1"
  method1: ->
    super
    return      "parent - emthod1"
  @classVar2:   "parent - classVar2"
  @classMethod2: ->
    return      "parent - classMethod2"
  var2:         "parent - var2"
  method2: ->
    return      "parent - emthod2"
  

class Child extends Parent
  LOG 'executed on class body'
  @classVar1:   "child - classVar1"
  @classMethod1: ->
    return      "child - classMethod1"
  var1:         "child - var1"
  method1: ->
    return      "child - emthod1"
  @classVar2:   "child - classVar2"
  @classMethod2: ->
    return      "child - classMethod2"
  var2:         "child - var2"
  method2: ->
    return      "child - emthod2"
    
