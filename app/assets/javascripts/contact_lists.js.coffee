$ ->
  siteID = location.pathname.match(/sites\/(\d+)/)[1]

  $("button#new-contact-list").click (e) ->
    options =
      siteID: siteID
      saveURL: "/sites/#{siteID}/contact_lists.json"
      saveMethod: "POST"
      success: (data) ->
        window.location = "/sites/#{siteID}/contact_lists/#{data.id}"

    new ContactListModal(options).open()

  $("button#edit-contact-list").click (e) ->
    id = $(e.target).data("contact-list-id")

    options =
      siteID: siteID
      loadURL: "/sites/#{siteID}/contact_lists/#{id}.json"
      saveURL: "/sites/#{siteID}/contact_lists/#{id}.json"
      saveMethod: "PUT"
      success: (data) ->
        window.location = "/sites/#{siteID}/contact_lists/#{id}"

    new ContactListModal(options).open()

  if window.location.search.match(/inflight_contact_list\=true/)
    options =
      siteID: siteID
      loadURL: "/sites/#{siteID}/contact_lists/inflight.json"
      saveMethod: "POST"
      success: (data) ->
        window.location = "/sites/#{siteID}/contact_lists/#{data.id}"

    new ContactListModal(options).open()
