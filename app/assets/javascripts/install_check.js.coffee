$ ->
  checkInstalled = (siteId, isInstalled) ->
    $.ajax
      type: 'GET'
      url: "/sites/#{siteId}"
      dataType: "json"
      success: (data, status, xhr) ->
        wasInstalled = isInstalled
        if data.has_script_installed && wasInstalled == false
          window.location.replace("/sites/#{siteId}?installed=true")
        else if data.has_script_installed == false
          isInstalled = data.has_script_installed
          callback = -> checkInstalled siteId, isInstalled
          setTimeout callback, 5000;

  if $("#install_page").length
    siteId = $("#install_page").data("site-id")
    checkInstalled(siteId, null)

    $("form").on("submit", (e) ->
      if not e.target.checkValidity()
        e.preventDefault() # explicitly prevent invalid form submission for Safari browser
    )
