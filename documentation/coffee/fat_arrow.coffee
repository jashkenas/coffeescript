Account: (customer, cart) ->
  @customer: customer
  @cart: cart

  $('.shoppingCart').bind 'click', (event) =>
    @customer.purchase @cart