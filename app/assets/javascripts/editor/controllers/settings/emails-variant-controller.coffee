HelloBar.SettingsEmailsVariantController = Ember.Controller.extend

  collectNames : Ember.computed.alias('model.settings.collect_names')

  # set 'afterSubmitChoice' property only after model is ready
  afterModel: (->
    # Set Initial After Email Submission Choice
    modelVal  = @get('model.settings.after_email_submit_action') || 0
    selection = @get('afterSubmitOptions').findBy('value', modelVal)
    @set('afterSubmitChoice', selection.key)
  ).observes('model')

  #-----------  After Email Submit  -----------#

  showCustomMessage    : Ember.computed.equal('afterSubmitChoice', 'custom_message')
  showRedirectUrlInput : Ember.computed.equal('afterSubmitChoice', 'redirect')

  setModelChoice: ( ->
    choice    = @get('afterSubmitChoice')
    selection = @get('afterSubmitOptions').findBy('key', choice)
    @set('model.settings.after_email_submit_action', selection.value)
  ).observes('afterSubmitChoice', 'afterSubmitOptions')

  afterSubmitOptions: ( ->
    [{
      value : 0
      key   : 'default_message'
      label : 'Show default message'
      isPro : false
    },{
      value : 1
      key   : 'custom_message'
      label : 'Show a custom message'
      isPro : !@get('model.site.capabilities.custom_thank_you_text')
    },{
      value : 2
      key   : 'redirect'
      label : 'Redirect the visitor to a url'
      isPro : !@get('model.site.capabilities.after_submit_redirect')
    }]
  ).property('model.site.capabilities.custom_thank_you_text', 'model.site.capabilities.after_submit_redirect')

  #-----------  Actions  -----------#

  actions:

    collectEmail: ->
      @set('collectNames', 0)

    collectEmailsAndNames: ->
      @set('collectNames', 1)

    setContactList: (listID) ->
      @set('model.contact_list_id', listID)

    setModelAfterSubmitValue: (selection) ->
      if selection.isPro
        controller = @
        new UpgradeAccountModal(
          site            : @get('model.site')
          upgradeBenefit  : selection.key == 'redirect' ? 'redirect to a custom url' : 'customize your thank you text'
          successCallback : ->
            controller.set('model.site.capabilities', this.site.capabilities)
            controller.set('afterSubmitChoice', selection.key)
        ).open()
      else
        @set('afterSubmitChoice', selection.key)

    openEmailListPopup: (listID = 0) ->
      siteID = window.siteID

      if listID
        # Edit Existing Contact List
        new ContactListModal({
          id          : listID
          siteID      : siteID
          loadURL     : "/sites/#{siteID}/contact_lists/#{listID}.json"
          saveURL     : "/sites/#{siteID}/contact_lists/#{listID}.json"
          saveMethod  : "PUT"
          editorModel : @get("model")
          canDelete   : (listID != @get("model.orig_contact_list_id"))

          success: (data, modal) =>
            for list in @get("model.site.contact_lists")
              if list.id == data.id
                Ember.set(list, "name", data.name)
                break
            modal.close()

          destroyed: (data, modal) =>
            lists = @get("model.site.contact_lists")
            for list in lists
              if list.id == data.id
                lists.removeObject(list)
                break
            modal.close()
        }).open()

      else
        # New Contact List
        InternalTracking.track_current_person("Editor Flow", {
          step : "Contact List Settings"
          goal : @get("model.element_subtype")
        }) if trackEditorFlow

        new ContactListModal({
          siteID      : siteID
          saveURL     : "/sites/#{siteID}/contact_lists.json"
          saveMethod  : "POST"
          editorModel : @get("model")

          success: (data, modal) =>
            lists = @get("model.site.contact_lists").slice(0)
            lists.push({id: data.id, name: data.name})
            @set("model.site.contact_lists", lists)
            setTimeout ( =>
              @set("model.contact_list_id", data.id)
            ), 100
            modal.$modal.remove()

          close: (modal) => @set("model.contact_list_id", null)
        }).open()
