$ ->
  siteSelectorEl = $('.header-nav-wrapper')
  userSelectorEl = $('.header-user-wrapper')

  $('html').not($('a[href="/users/sign_out"]')).click (evt) ->
    siteSelectorEl.find('.dropdown-wrapper').removeClass('activated')
    userSelectorEl.find('.dropdown-wrapper').removeClass('activated')

  siteSelectorEl.click (evt) ->
    dropdown      = siteSelectorEl.find('.dropdown-wrapper')
    childElements = [@, dropdown]

    if $.inArray(evt.target, childElements)
      evt.stopPropagation()
      dropdown.toggleClass('activated')

  userSelectorEl.click (evt) ->
    dropdown      = userSelectorEl.find('.dropdown-wrapper')
    signOutLink   = $('a[href="/users/sign_out"]')[0]
    childElements = [@, dropdown]

    if evt.target != signOutLink
      if $.inArray(evt.target, childElements)
        evt.stopPropagation()
        dropdown.toggleClass('activated')