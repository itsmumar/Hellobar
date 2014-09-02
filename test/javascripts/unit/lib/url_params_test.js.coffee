#= require lib/url_params

test '.set', ->
  UrlParams.set('/newurl')

  equal window.location.pathname, '/newurl', 'sets the pathname correctly'

test '.fetch', ->
  UrlParams.set('?hello=bar')

  equal UrlParams.fetch('hello'), 'bar', 'it grabs the correct parameter'
  equal UrlParams.fetch('nope'), undefined, 'it returns null from keys that dont exist'

test '.updateParam with no params', ->
  UrlParams.set('/no_params')

  UrlParams.updateParam('new', 'thing')

  equal UrlParams.fetch('new'), 'thing', 'it adds the key and value when no params were present'

test '.updateParam with params but without expected key', ->
  UrlParams.set('?one=1')

  UrlParams.updateParam('two', '2')

  equal UrlParams.fetch('two'), '2', 'it adds the key and value to the existing params'

test '.updateParam with params and expected key', ->
  UrlParams.set('?update=me')

  UrlParams.updateParam('update', 'you')

  equal UrlParams.fetch('update'), 'you', 'it updates the value of the key in the params when present'
