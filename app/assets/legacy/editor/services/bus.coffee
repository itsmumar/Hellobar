# TODO this is a temporary solution until refactoring is done
# (we need to upgrade Ember version in order to use services and bus pattern)
HelloBar.bus = {
  _events: {}
  subscribe: (eventName, callback) ->
    if not @_events[eventName]
      @_events[eventName] = []
    @_events[eventName].push(callback)

  unsubscribe: (eventName, callback) ->
    @_events[eventName] = _.without(@_events[eventName], callback)

  trigger: (eventName, params) ->
    callbacks = @_events[eventName]
    if callbacks
      callbacks.forEach((callback) ->
        setTimeout(->
          callback(params)
        , 0)
      )
}
