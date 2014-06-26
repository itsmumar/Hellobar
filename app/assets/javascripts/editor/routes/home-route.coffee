HelloBar.HomeRoute = Ember.Route.extend

  redirect: ->
    @transitionTo('settings')