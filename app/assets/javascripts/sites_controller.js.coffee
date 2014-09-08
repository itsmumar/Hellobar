$ ->
  if currentUser && currentUser.status == 'temporary'
    modal = new RegistrationModal
    modal.open()

  $("tr.see-more a").click (e) ->
    $(e.target).toggleClass("seeing-more")
    $("tr.more-top-performers").toggle()
