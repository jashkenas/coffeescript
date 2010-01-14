(function(){
  var Account;
  Account = function Account(customer, cart) {
    var __a, __b;
    var __this = this;
    this.customer = customer;
    this.cart = cart;
    __a = $('.shopping_cart').bind('click', (function() {
      __b = function(event) {
        var __c;
        __c = this.customer.purchase(this.cart);
        return Account === this.constructor ? this : __c;
      };
      return (function() {
        return __b.apply(__this, arguments);
      });
    })());
    return Account === this.constructor ? this : __a;
  };
})();