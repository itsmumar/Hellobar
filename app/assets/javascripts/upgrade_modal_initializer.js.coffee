$ ->
  # Upgrade Account Modal
  $("#upgrade-account").click (e) ->
    new UpgradeAccountModal({site: window.site}).open()
