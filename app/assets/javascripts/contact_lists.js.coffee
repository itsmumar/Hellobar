$ ->

  $('.contacts-table').tablesorter() if $('.contacts-table tbody tr').length > 1

  siteID = (location.pathname.match(/sites\/(\d+)/) || [])[1]
  contactListID = (location.pathname.match(/contact_lists\/(\d+)/) || [])[1]

  baseOptions = ->
    id: contactListID
    siteID: siteID
    success: (data, modal) ->
      window.location = "/sites/#{siteID}/contact_lists/#{data.id}"
    destroyed: (modal) ->
      window.location = "/sites/#{siteID}/contact_lists"

  $("#new-contact-list").click (e) ->
    options =
      saveURL: "/sites/#{siteID}/contact_lists.json"
      saveMethod: "POST"

    new ContactListModal($.extend(baseOptions(), options)).open()

  $("#edit-contact-list").click (e) ->
    options =
      loadURL: "/sites/#{siteID}/contact_lists/#{contactListID}.json"
      saveURL: "/sites/#{siteID}/contact_lists/#{contactListID}.json"
      saveMethod: "PUT"

    new ContactListModal($.extend(baseOptions(), options)).open()

  if localStorage["stashedContactList"]
    contactList = JSON.parse(localStorage["stashedContactList"])
    localStorage.removeItem("stashedContactList")

    if contactList.id
      options =
        saveURL: "/sites/#{siteID}/contact_lists/#{contactList.id}.json"
        saveMethod: "PUT"
    else
      options =
        saveURL: "/sites/#{siteID}/contact_lists.json"
        saveMethod: "POST"

    options["contactList"] = contactList

    new ContactListModal($.extend(baseOptions(), options)).open()
