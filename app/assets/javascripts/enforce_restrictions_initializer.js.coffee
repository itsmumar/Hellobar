$ ->
  $("[data-prompt-upgrade=true]").on "click", (event) ->
    return unless $(this).data('prompt-upgrade')
    event.preventDefault()
    new UpgradeAccountModal({site: window.site, upgradeBenefit: event.target.dataset.upgradeBenefit}).open()
