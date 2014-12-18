$ ->
  # Upgrade Account Modal
  $(".upgrade-account-modal").click (e) ->
    new UpgradeAccountModal({site: window.site}).open()

  if window.location.hash.substring(1) == "upgrade-modal"
    new UpgradeAccountModal({site: window.site}).open()
