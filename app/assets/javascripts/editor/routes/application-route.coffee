HelloBar.ApplicationRoute = Ember.Route.extend

  model: ->
    if window.barID
      Ember.$.getJSON("/sites/#{window.siteID}/site_elements/#{window.barID}.json")
    else
      Ember.$.getJSON("/sites/#{window.siteID}/site_elements/new.json")

  # Actions bubble up the routers from most specific to least specific.
  # In order to catch all the actions (beacuse they happen in different
  # routes), the action catch was places in the top-most application route.

  actions:

    triggerModal: (modal) ->
      @transitionTo @controller.currentPath, {queryParams: {modal: modal}}

    saveSiteElement: ->
      if window.barID
        url = "/sites/#{window.siteID}/site_elements/#{window.barID}.json"
        method = "PUT"
      else
        url = "/sites/#{window.siteID}/site_elements.json"
        method = "POST"

      Ember.$.ajax
        type: method
        url: url
        contentType: "application/json"
        data: JSON.stringify(@currentModel)
        success: =>
          window.location = "/sites/#{window.siteID}/site_elements"
        error: =>
          @controller.toggleProperty('saveSubmitted')
