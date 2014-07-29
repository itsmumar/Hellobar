$ ->
  $("button#new-contact-list").click (e) ->
    site_id = $(e.target).data("site-id")
    create = true
    success = (data) ->
      window.location = "/sites/#{site_id}/contact_lists/#{data.id}"

    new ContactListModal({site_id, create, success}).open()

  $("button#edit-contact-list").click (e) ->
    id = $(e.target).data("contact-list-id")
    site_id = $(e.target).data("site-id")
    load = true
    success = (data) ->
      window.location = "/sites/#{site_id}/contact_lists/#{id}"

    new ContactListModal({id, site_id, load, success}).open()
