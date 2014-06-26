HelloBar.ApplicationRoute = Ember.Route.extend

  # Actions bubble up the routers from most specific to least specific. 
  # In order to catch all the actions (beacuse they happen in different
  # routes), the action catch was places in the top-most application route.

  actions:

    triggerModal: (modal) ->
      @transitionTo @controller.currentPath, {queryParams: {modal: modal}}