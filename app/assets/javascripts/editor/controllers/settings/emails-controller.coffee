HelloBar.SettingsEmailsController = Ember.Controller.extend

  collectionOptions: [
    {value: 0, label: 'Just email addresses'}
    {value: 1, label: 'Names and email addresses'}
  ]

  contactListOptions: (->
    lists = @get("model.site.contact_lists").slice(0)
    lists.push({id: 0, name: "New contact list..."})
    lists
  ).property("model.site.contact_lists")

  afterSubmitOptions: [
    {value: 0, label: 'Show default message'}
    {value: 1, label: 'Show a custom message'}
    {value: 2, label: 'Redirect the visitor to a url'}
  ]

  showDefaultMessage: (->
    action_index = @get("model.settings.after_email_submit_action")
    action_index == 0
  ).property("model.settings.after_email_submit_action")

  disableThankYouText: Ember.computed.not('model.site.capabilities.custom_thank_you_text')
  disableRedirect: Ember.computed.not('model.site.capabilities.after_submit_redirect')

  setDefaultListID: (->
    if !@get('model.contact_list_id')
      firstList = @get('model.site.contact_lists')[0]
      listId = if firstList then firstList.id else null

      @set('model.contact_list_id', listId)
  ).observes('model.site.contact_lists')

  popNewContactListModal: (->
    if (@get("model.site.contact_lists").length == 0 || @get("model.contact_list_id") == 0) && $(".contact-list-modal:visible").length == 0
      options =
        siteID: window.siteID
        saveURL: "/sites/#{siteID}/contact_lists.json"
        saveMethod: "POST"
        editorModel: @get("model")
        success: (data, modal) =>
          lists = @get("model.site.contact_lists").slice(0)
          lists.push({id: data.id, name: data.name})
          @set("model.site.contact_lists", lists)
          @set("model.contact_list_id", data.id)
          modal.$modal.remove()
        close: (modal) =>
          @set("model.contact_list_id", null)

      InternalTracking.track_current_person("Editor Flow", {step: "Contact List Settings", goal: @get("model.element_subtype")}) if trackEditorFlow
      new ContactListModal(options).open()
  ).observes("model.contact_list_id")

  showEditContactListLink: (->
    id = @get("model.contact_list_id")
    id && id != 0
  ).property("model.contact_list_id")

  showRedirectUrlInput: (->
    @get("model.settings.after_email_submit_action") == 2
  ).property("model.settings.after_email_submit_action")

  actions:

    popEditContactListModal: (id) ->
      options =
        id: id
        siteID: siteID
        loadURL: "/sites/#{siteID}/contact_lists/#{id}.json"
        saveURL: "/sites/#{siteID}/contact_lists/#{id}.json"
        saveMethod: "PUT"
        editorModel: @get("model")
        success: (data, modal) =>
          @get("model.site.contact_lists").forEach (list) ->
            Ember.set(list, "name", data.name) if list.id == data.id

          modal.close()

      new ContactListModal(options).open()

    openUpgradeModal: (capabilityType) ->
      controller = this

      if capabilityType == "redirect"
        upgradeText = 'redirect to a custom url'
      else
        upgradeText = 'customize your thank you text'

      new UpgradeAccountModal(
        site: controller.get('model.site')
        upgradeBenefit: upgradeText
        successCallback: ->
          controller.set('model.site.capabilities', this.site.capabilities)
      ).open()
