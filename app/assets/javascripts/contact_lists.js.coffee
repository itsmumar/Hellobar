$ ->
  $("button#new-contact-list").click (e) ->
    new ContactListModal($(".contact-list-modal")).open()
