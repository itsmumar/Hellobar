HelloBar.ApplicationRoute = Ember.Route.extend

  redirect: ->
    @transitionTo('settings')