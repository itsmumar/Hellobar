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
            @controller.set("model.contact_list_id", data.id)
            modal.$modal.remove()
          close: (modal) =>
            @controller.set("model.contact_list_id", null)

      new ContactListModal($.extend(baseOptions, options)).open()

  # Actions bubble up the routers from most specific to least specific.
  # In order to catch all the actions (beacuse they happen in different
  # routes), the action catch was places in the top-most application route.

  actions:

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
          if HB_ACCOUNT_CREATION_VARIATION != "original" && @controllerFor("application").get("isTemporaryUser")
            new AlternateAccountPromptModal(siteURL: @controller.get("model.site.url")).open()
          else
            window.location = "/sites/#{window.siteID}/site_elements"
        error: (data) =>
          @controller.toggleProperty('saveSubmitted')
          @controller.set("model.errors", data.responseJSON.errors)
          new EditorErrorsModal(errors: data.responseJSON.full_error_messages).open()
