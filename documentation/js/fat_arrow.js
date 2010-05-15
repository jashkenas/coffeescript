(function(){
  var Account;
  var __slice = Array.prototype.slice, __bind = function(func, obj, args) {
    return function() {
      return func.apply(obj || {}, args ? args.concat(__slice.call(arguments, 0)) : arguments);
    };
  };
  Account = function(customer, cart) {
    this.customer = customer;
    this.cart = cart;
    return $('.shopping_cart').bind('click', __bind(function(event) {
        return this.customer.purchase(this.cart);
      }, this));
  };
})();
