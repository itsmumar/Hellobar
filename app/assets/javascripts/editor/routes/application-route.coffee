HelloBar.ApplicationRoute = Ember.Route.extend

  saveCount: 0

  model: ->
    if localStorage["stashedEditorModel"]
      $(".goal-interstitial").remove() # Don't show the goal selector if we already have a model
      model = JSON.parse(localStorage["stashedEditorModel"])
      localStorage.removeItem("stashedEditorModel")
      model
    else if window.barID
      Ember.$.getJSON("/sites/#{window.siteID}/site_elements/#{window.barID}.json")
    else if window.elementToCopyID
      Ember.$.getJSON("/sites/#{window.siteID}/site_elements/#{window.elementToCopyID}.json")
    else
      Ember.$.getJSON("/sites/#{window.siteID}/site_elements/new.json")

  #-----------  Parse JSON Model  -----------#

  afterModel: (resolvedModel) ->
    if localStorage["stashedContactList"]
      contactList = JSON.parse(localStorage["stashedContactList"])
      localStorage.removeItem("stashedContactList")

      baseOptions =
        id: contactList.id
        siteID: siteID
        editorModel: resolvedModel
        contactList: contactList

      if contactList.id
        options =
          saveURL: "/sites/#{siteID}/contact_lists/#{contactList.id}.json"
          saveMethod: "PUT"

          success: (data, modal) =>
            resolvedModel.site.contact_lists.forEach (list) ->
              Ember.set(list, "name", data.name) if list.id == data.id

            modal.close()
      else
        options =
          saveURL: "/sites/#{siteID}/contact_lists.json"
          saveMethod: "POST"

          success: (data, modal) =>
            lists = resolvedModel.site.contact_lists.slice(0)
            lists.push({id: data.id, name: data.name})
            @controller.set("model.site.contact_lists", lists)
            setTimeout (=>
              @controller.set("model.contact_list_id", data.id)
            ), 100
            modal.$modal.remove()
          close: (modal) =>
            @controller.set("model.contact_list_id", null)

      new ContactListModal($.extend(baseOptions, options)).open()

  #---------- Contact Interstitial Test -----#
   renderTemplate: ->
     @_super()
     if HB_EMAIL_FLOW_TEST == 'force'
       controller = this.controllerFor('interstitial')
       controller.set('interstitialType', 'contacts')

       @render("interstitials/contacts", {
         into       : 'application'
         outlet     : 'interstitial'
         view       : 'interstitial'
         controller : controller
         model      : @currentModel
       })

  #-----------  Controller Setup  -----------#

  setupController: (controller, model) ->

    # Set sub-step forwarding on application load

    settings = @controllerFor('settings')
    if /^social/.test model.element_subtype
      settings.routeForwarding = 'settings.social'
    else
      switch model.element_subtype
        when 'call'
          settings.routeForwarding = 'settings.call'
        when 'email'
          settings.routeForwarding = 'settings.emails'
        when 'traffic'
          settings.routeForwarding = 'settings.click'
        when 'announcement'
          settings.routeForwarding = 'settings.announcement'
        else
          settings.routeForwarding = false

    style = @controllerFor('style')
    switch model.type
      when 'Takeover'
        style.routeForwarding = 'style.takeover'
      when 'Slider'
        style.routeForwarding = 'style.slider'
      when 'Modal'
        style.routeForwarding = 'style.modal'
      else
        style.routeForwarding = if model.id then 'style.bar' else false

    # Subscribes to outside action used by interstitial
    # to route ember app through selection

    Ember.subscribe 'interstitial.routing',
      before: (name, timestamp, subroute) =>
        isInterstitial = $.inArray(subroute, ['money', 'call', 'contacts', 'facebook']) > -1

        @disconnectOutlet({
          outlet     : 'interstitial'
          parentView : 'application'
        })

        if isInterstitial
          InternalTracking.track_current_person('Template Selected', {template: subroute})

          controller.set('showInterstitial', true)
          controller.set('interstitialType', subroute)

          @render("interstitials/#{subroute}", {
            into       : 'application'
            outlet     : 'interstitial'
            view       : 'interstitial'
            controller : 'interstitial'
            model      : model
          })

          # # If the choice was a subcategory of social, we have to trigger the transition
          # # now so that when they drop into the editor they'll be in the right category
          if choice == 'facebook'
            @transitionTo("settings.social")

      after: (name, timestamp, subroute) =>
        false

    @_super(controller, model)

  #-----------  Actions  -----------#

  # Actions bubble up the routers from most specific to least specific.
  # In order to catch all the actions (beacuse they happen in different
  # routes), the action catch was places in the top-most application route.

  actions:

    saveSiteElement: ->
      @set("saveCount", @get("saveCount") + 1)
      InternalTracking.track_current_person("Editor Flow", {step: "Save Bar", goal: @currentModel.element_subtype, style: @currentModel.type, save_attempts: @get("saveCount")}) if trackEditorFlow

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
          InternalTracking.track_current_person("Editor Flow", {step: "Completed", goal: @currentModel.element_subtype, style: @currentModel.type, save_attempts: @get("saveCount")}) if trackEditorFlow
          if @controller.get("model.site.num_site_elements") == 0
            window.location = "/sites/#{window.siteID}"
          else
            window.location = "/sites/#{window.siteID}/site_elements"

        error: (data) =>
          @controller.toggleProperty('saveSubmitted')
          @controller.set("model.errors", data.responseJSON.errors)
          new EditorErrorsModal(errors: data.responseJSON.full_error_messages).open()
