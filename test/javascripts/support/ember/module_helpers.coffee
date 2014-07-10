Ember.Test.registerHelper 'getModule', (app, name) ->
  app.__container__.lookup(name)
