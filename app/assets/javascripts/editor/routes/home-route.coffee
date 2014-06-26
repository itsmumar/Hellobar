HelloBar.HomeRoute = Ember.Route.extend

  # Auto-redirects the index/home route to the first step

  redirect: ->
    @transitionTo('settings')
