$ ->
  siteSelectorEl = $('.header-nav-wrapper')
  userSelectorEl = $('.header-user-wrapper')

  $('html').click (evt) ->
    siteSelectorEl.find('.dropdown-wrapper').removeClass('activated')
    userSelectorEl.find('.dropdown-wrapper').removeClass('activated')

  siteSelectorEl.click (evt) ->
    dropdown      = siteSelectorEl.find('.dropdown-wrapper')
    childElements = [@, dropdown]

    if $.inArray(evt.target, childElements)
      evt.stopPropagation()
      userSelectorEl.find('.dropdown-wrapper').removeClass('activated')
      dropdown.toggleClass('activated')

  userSelectorEl.click (evt) ->
    dropdown      = userSelectorEl.find('.dropdown-wrapper')
    childElements = [@, dropdown]

    if (evt.target.getAttribute('href') != "/users/sign_out") && (evt.target.getAttribute('href') != "/admin/users/unimpersonate")
      if $.inArray(evt.target, childElements)
        siteSelectorEl.find('.dropdown-wrapper').removeClass('activated')
        evt.stopPropagation()
        dropdown.toggleClass('activated')
