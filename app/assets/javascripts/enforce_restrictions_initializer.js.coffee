$ ->
  $("[data-prompt-upgrade=true]").on "click", (event) ->
    event.preventDefault()
    new UpgradeAccountModal().open()
