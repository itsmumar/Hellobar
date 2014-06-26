HelloBar.ApplicationRoute = Ember.Route.extend

  actions:

    triggerModal: (modal) ->
      @transitionTo @controller.currentPath, {queryParams: {modal: modal}}