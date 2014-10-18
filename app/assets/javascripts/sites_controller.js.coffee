$ ->
  $("tr.see-more a").click (e) ->
    $(e.target).toggleClass("seeing-more")
    $("tr.more-top-performers").toggle()

  $('a.show-payment-modal').click ->
    options =
      package: window.site.current_subscription
      site: window.site
    new PaymentModal(options).open()

  $('a.show-upgrade-modal').click ->
    options =
      site: window.site
    new UpgradeAccountModal(options).open()
