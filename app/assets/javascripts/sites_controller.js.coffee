$ ->
  $("tr.see-more a").click (e) ->
    $(e.target).toggleClass("seeing-more")
    $("tr.more-top-performers").toggle()

  # allow users to edit/update their payment information
  $('a#update-cc-details, a#change-billing-cycle').click ->
    options =
      type: window.currentSubscription.values.name.toLowerCase(),
      cycle: window.currentSubscription.values.schedule
      currentPaymentDetails: window.currentPaymentDetails.data
      userPaymentMethods: window.userPaymentMethods
    new PaymentModal(options).open()
