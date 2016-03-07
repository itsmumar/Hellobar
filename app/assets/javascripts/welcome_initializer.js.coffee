$ ->
  if $('main#welcome-index').length
    welcome_modal = new WelcomeBackModal()
    welcome_modal.open() if welcome_modal.hasLoginCookie()
