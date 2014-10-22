$ ->
  # Upgrade Account Modal
  $(".upgrade-account-modal").click (e) ->
    new UpgradeAccountModal({site: window.site}).open()
