$ ->
  $("button#new-contact-list").click (e) ->
    new ContactListModal().open()

  $("button.edit-contact-list").click (e) ->
    id = $(e.target).data("contact-list-id")
    site_id = $(e.target).data("site-id")
    load = true

    new ContactListModal({id, site_id, load}).open()
