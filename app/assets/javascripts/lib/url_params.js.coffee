class @UrlParams

  @queryString: ->
    window.location.search.substring(1)

  @fetch: (keyword) ->
    params = @queryString().split("&")

    for param in params
      [key, value] = param.split('=')

      return value if key == keyword

  # https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Manipulating_the_browser_history
  @set: (url) ->
    history.pushState('', '', url)

  @updateParam: (param, newValue) ->
    oldUrl = window.location.href
    paramValue = @fetch(param)

    newUrl = ''

    if @queryString() == '' # there are no params
      newUrl = "#{oldUrl}?#{param}=#{newValue}"
    else if oldUrl.match("#{param}=#{paramValue}") # if the key exists
      newUrl = oldUrl.replace("#{param}=#{paramValue}", "#{param}=#{newValue}")
    else # the key does not exist but params exist
      newUrl = "#{oldUrl}&#{param}=#{newValue}"

    @set(newUrl)
