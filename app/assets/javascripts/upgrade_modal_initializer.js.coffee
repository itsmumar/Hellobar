$ ->

  if window.location.hash.substring(1) == "upgrade-modal"
    new UpgradeAccountModal({site: window.site}).open()
