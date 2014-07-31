$ ->
  $("button#new-contact-list").click (e) ->
    site_id = $(e.target).data("site-id")

    options =
      siteID: site_id
      saveURL: "/sites/#{site_id}/contact_lists.json"
      saveMethod: "POST"
      success: (data) ->
        window.location = "/sites/#{site_id}/contact_lists/#{data.id}"

    new ContactListModal(options).open()

  $("button#edit-contact-list").click (e) ->
    id = $(e.target).data("contact-list-id")
    site_id = $(e.target).data("site-id")

    options =
      siteID: site_id
      loadURL: "/sites/#{site_id}/contact_lists/#{id}.json"
      saveURL: "/sites/#{site_id}/contact_lists/#{id}.json"
      saveMethod: "PUT"
      success: (data) ->
        window.location = "/sites/#{site_id}/contact_lists/#{id}"

    new ContactListModal(options).open()
