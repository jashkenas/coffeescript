class Account
  constructor: (@customer, @cart) ->
    $('.shopping_cart').bind 'click', (event) =>
      @customer.purchase @cart