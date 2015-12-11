$ ->
  $("tr.see-more a").click (e) ->
    $(e.target).toggleClass("seeing-more")
    $("tr.more-top-performers").toggle()

  $('.show-payment-modal').click ->
    options =
      package: window.site.current_subscription
      site: window.site
    new PaymentModal(options).open()

  $('.show-upgrade-modal').click ->
    options =
      site: window.site
      source: $(this).data('source')
    new UpgradeAccountModal(options).open()

  $('.show-downgrade-modal').click ->
    options =
      site: window.site
    new DowngradeSiteModal(options).open()
