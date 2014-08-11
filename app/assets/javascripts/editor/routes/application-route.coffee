HelloBar.ApplicationRoute = Ember.Route.extend

  model: ->
    if localStorage["stashedEditorModel"]
      model = JSON.parse(localStorage["stashedEditorModel"])
      localStorage.removeItem("stashedEditorModel")
      model
    else if window.barID
      Ember.$.getJSON("/sites/#{window.siteID}/site_elements/#{window.barID}.json")
    else if window.elementToCopyID
      Ember.$.getJSON("/sites/#{window.siteID}/site_elements/#{window.elementToCopyID}.json")
    else
      Ember.$.getJSON("/sites/#{window.siteID}/site_elements/new.json")

  # Actions bubble up the routers from most specific to least specific.
  # In order to catch all the actions (beacuse they happen in different
  # routes), the action catch was places in the top-most application route.

  actions:

    triggerModal: (ruleData) ->
      route = this
      ruleId = ruleData.id
      $form = $("form#rule-#{ruleId}")
      $modal = $form.parents('.modal-wrapper:first')

      ruleToUpdate = @controller.get('model.site.rules').find (rule) ->
        rule.id == ruleData.id

      options =
        successCallback: ->
          ruleData = this

          ruleIds = route.controller.get('model.site.rules').map (rule) -> rule.id

          updatedRules = if ruleIds.contains(ruleData.id)
            route.controller.get('model.site.rules').map (rule) ->
              return rule unless rule.id == ruleData.id
              return ruleData
          else
            $form.find('.condition').remove() # remove any conditions
            $form.find('.form-control').val(null) # clear Rule Modal form values

            rules = route.controller.get('model.site.rules').map (rule) -> rule
            rules.push(ruleData)
            rules

          route.controller.set('model.site.rules', updatedRules)
          route.controller.set('model.rule_id', ruleData.id)

      new RuleModal($modal, options).open()

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

    closeEditor: ->
      window.location = "/sites/#{window.siteID}/site_elements"
