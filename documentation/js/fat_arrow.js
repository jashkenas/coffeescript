var Account;
var __bind = function(func, context) {
  return function() { return func.apply(context, arguments); };
};
Account = function(customer, cart) {
  this.customer = customer;
  this.cart = cart;
  return $('.shopping_cart').bind('click', __bind(function(event) {
    return this.customer.purchase(this.cart);
  }, this));
};