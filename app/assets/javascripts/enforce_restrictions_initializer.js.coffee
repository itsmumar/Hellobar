$ ->
  $("[data-prompt-upgrade=true]").on "click", (event) ->
    event.preventDefault()
    options =
      site: window.site
      successCallback: ->
        window.location.reload(true)

    new UpgradeAccountModal(options).open()
