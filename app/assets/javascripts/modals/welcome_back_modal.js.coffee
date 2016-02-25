class @WelcomeBackModal extends Modal
  modalName: "welcome-back-modal"
  template: -> $("#welcome-back-modal-template")

  constructor: (@options = {}) ->
    compiledTemplate = Handlebars.compile(@template().html())
    @$modal = $(compiledTemplate())
    @$modal.appendTo($("body"))

    super(@$modal)

  hasLoginCookie: ->
    @template().data('cookie-present')

  _bindCloseEvents: (callback) ->
    super
    @_bindNotLastLoggedInUser(callback)

  _bindNotLastLoggedInUser: (callback) ->
    @$modal.find('a.not-last-logged-in-user').on 'click', (event) =>
      callback.call(this)
      @_clearRegistrationUrl()
      @_expireLoginCookies()

  _expireLoginCookies: ->
    document.cookie = "login_email=; expires=Thu, 01 Jan 1970 00:00:00 UTC"

  _clearRegistrationUrl: ->
    $('input[name="site[url]"]').val('')
