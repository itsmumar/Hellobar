$ ->
  if window.location.search.indexOf("upgrade=true") != -1
    options =
      package:
        trial: false
        monthly_amount: "15"
        payment_valid: true
        schedule: "yearly"
        type: "pro"
        yearly_amount: "149"
      site: window.site
      source: "package-selected"

    new PaymentModal(options).open()

  $("tr.see-more a").click (e) ->
    $(e.target).toggleClass("seeing-more")
    $("tr.more-top-performers").toggle()

  $('.show-payment-modal').click ->
    options =
      package: window.site.current_subscription
      site: window.site
      source: $(this).data('source')
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

  $('#hide-btn-old-user-update').click ->
    $(this).parents("#old-user-update").fadeOut()
    expireDate = new Date
    expireDate.setDate(expireDate.getDate()+7)
    document.cookie = "dismissUserUpdate= true; expires=" + expireDate.toGMTString()
