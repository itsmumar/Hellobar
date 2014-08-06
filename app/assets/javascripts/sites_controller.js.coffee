$ ->
  if currentUser && currentUser.status == 'temporary'
    modal = new RegistrationModal
    modal.open()
