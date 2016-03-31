$ ->
  siteSelectorEl = $('.header-nav-wrapper')
  userSelectorEl = $('.header-user-wrapper .dropdown-wrapper')

  $('html').click (evt) ->
    siteSelectorEl.find('.dropdown-wrapper').removeClass('activated')
    userSelectorEl.removeClass('activated')

  siteSelectorEl.click (evt) ->
    dropdown      = siteSelectorEl.find('.dropdown-wrapper')
    childElements = [@, dropdown]

    if $.inArray(evt.target, childElements)
      evt.stopPropagation()
      dropdown.toggleClass('activated')

  userSelectorEl.click (evt) ->
    dropdown      = userSelectorEl
    childElements = [@, dropdown]

    if evt.target.getAttribute('href') != "/users/sign_out"
      if $.inArray(evt.target, childElements)
        evt.stopPropagation()
        dropdown.toggleClass('activated')