$ ->
  # for first time installs, check every 5 seconds for script
  if $('#sites-install').length
    unless window.site.script_installed_at
      $.ajax
        url: "/sites/#{window.site.id}/install"
        dataType: "json"
        success: (data, status, xhr) ->
          setTimeout ( ->
            window.location = data.redirect_path
          ), 5000

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
