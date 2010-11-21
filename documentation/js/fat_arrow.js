var Account;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
Account = function(customer, cart) {
  this.customer = customer;
  this.cart = cart;
  return $('.shopping_cart').bind('click', __bind(function(event) {
    return this.customer.purchase(this.cart);
  }, this));
};