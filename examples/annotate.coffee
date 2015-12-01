#`@ngInject`
3
class Hello
  say: ->
    console.log("say hello")


#following is more advanced annotations
#
#Original examples are taken from https://github.com/olov/ng-annotate
#
#x = /*@ngInject*/ function($scope) {};
#obj = {controller: /*@ngInject*/ function($scope) {}};
#obj.bar = /*@ngInject*/ function($scope) {};
#
#obj = /*@ngInject*/ {
#    controller: function($scope) {},
#    resolve: { data: function(Service) {} },
#};

#x = #`@ngInject` ($scope) ->

#obj =
#  controller: #`@ngInject`
#    ($scope)
