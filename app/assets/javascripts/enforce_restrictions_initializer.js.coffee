$ ->
  $("[data-prompt-upgrade=true]").on "click", (event) ->
    event.preventDefault()
    new UpgradeAccountModal({site: window.site, upgradeBenefit: event.target.dataset.upgradeBenefit}).open()
