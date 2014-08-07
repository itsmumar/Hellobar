$ ->
  siteID = location.pathname.match(/sites\/(\d+)/)[1]
  contactListID = (location.pathname.match(/contact_lists\/(\d+)/) || [])[1]

  baseOptions =
    id: contactListID
    siteID: siteID
    success: (data, modal) ->
      window.location = "/sites/#{siteID}/contact_lists/#{data.id}"

  $("button#new-contact-list").click (e) ->
    options =
      saveURL: "/sites/#{siteID}/contact_lists.json"
      saveMethod: "POST"

    new ContactListModal($.extend(baseOptions, options)).open()

  $("button#edit-contact-list").click (e) ->
    options =
      loadURL: "/sites/#{siteID}/contact_lists/#{contactListID}.json"
      saveURL: "/sites/#{siteID}/contact_lists/#{contactListID}.json"
      saveMethod: "PUT"

    window.foo = $.extend(baseOptions, options)

    new ContactListModal($.extend(baseOptions, options)).open()

  if window.location.search.match(/inflight_contact_list\=true/)
    if contactListID
      options =
        saveURL: "/sites/#{siteID}/contact_lists/#{contactListID}.json"
        saveMethod: "PUT"
    else
      options =
        saveURL: "/sites/#{siteID}/contact_lists.json"
        saveMethod: "POST"

    options["loadURL"] = "/sites/#{siteID}/contact_lists/inflight.json"

    new ContactListModal($.extend(baseOptions, options)).open()
