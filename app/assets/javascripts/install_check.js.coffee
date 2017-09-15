$ ->
  checkInstalled = (siteId, isInstalled) ->
    $.ajax
      type: 'POST'
      url: "/sites/#{ siteId }/install_check"
      dataType: "json"
      success: (data, status, xhr) ->
        wasInstalled = isInstalled
        if data.script_installed && wasInstalled == false
          window.location.replace("/sites/#{ siteId }?installed=true")
        else if data.script_installed == false
          isInstalled = data.script_installed
          callback = -> checkInstalled siteId, isInstalled
          setTimeout callback, 10000

  if $("#install_page").length
    siteId = $("#install_page").data("site-id")
    checkInstalled(siteId, null)
